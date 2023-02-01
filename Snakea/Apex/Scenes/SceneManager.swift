//
//  SceneManager.swift
//  Snakea
//
//  Created by Matthew  Eatough on 27/10/2022.
//

import MetalKit

enum SceneTypes
{
    case Level1
}

class SceneManager
{
    private static var currentScene: Scene!
    private static var frameSemaphore: DispatchSemaphore!
    
    public static var getCurrentScene: Scene {
        return currentScene
    }
    
    public static func initialise()
    {
//        Basically prevents the GPU from trying to process too far ahead
        frameSemaphore = DispatchSemaphore(value: Scene.maxFramesInFlight)
    }
    
    public static func setScene(_ type: SceneTypes)
    {
        switch type
        {
        case .Level1:
            currentScene = Level1()
        }
    }
    
    public static func doUpdate(view: MTKView, deltaTime: Float)
    {
        GameTime.UpdateTime(deltaTime)
        
        frameSemaphore.wait()
        currentScene.semaphore.wait()
        
        guard let vertexCommandBuffer = Engine.CommandQueue.makeCommandBuffer() else { return }
        vertexCommandBuffer.label = "Vertex Command Buffer"
        guard let commandBuffer = Engine.CommandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "One Command Buffer to rule them all"
        
        vertexCommandBuffer.enqueue()
        commandBuffer.enqueue()

        commandBuffer.addCompletedHandler({_ in
            frameSemaphore.signal()
        })
        
        currentScene.updateCameras()
        currentScene.createRays(commandBuffer)
        
        currentScene.rebuildAccelerationStructure(commandBuffer: vertexCommandBuffer,
                                                  completeHandler: {
    //      MARK: Update with the kernel functions
            updateComputations(commandBuffer: commandBuffer)

    //      MARK: Raytrace the scene
            currentScene.render(commandBuffer)
            
    //      MARK: Present the texture
            presentTextures(commandBuffer: commandBuffer, view: view)
            
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()
        })
     
        vertexCommandBuffer.commit()
        
    }
    
    
    private static func updateComputations(commandBuffer: MTLCommandBuffer)
    {
        commandBuffer.pushDebugGroup("Start Kernel Computation")
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()

        currentScene.update(computeEncoder)
        
        computeEncoder?.endEncoding()
        commandBuffer.popDebugGroup()
        
    }

    private static func presentTextures(commandBuffer: MTLCommandBuffer, view: MTKView)
    {
        commandBuffer.pushDebugGroup("Present Texture")
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        currentScene.presentTexture(renderEncoder!)
        
        renderEncoder?.endEncoding()
        commandBuffer.popDebugGroup()
        
    }
    
}
