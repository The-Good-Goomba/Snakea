//
//  Scene.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit
import Accelerate
import MetalPerformanceShaders

class Scene: Apex
{
    var cameraManager: CameraManager = CameraManager()
    var sceneConstants = SceneConstants()
    
    var jointMatrices: [float4x4] = []
    
    var transformPipeline: MTLComputePipelineState!
    var primaryRayPipeline: MTLComputePipelineState!
    var shadePipeline: MTLComputePipelineState!
    var shadowPipeline: MTLComputePipelineState!
    
    var rayBuffer: MTLBuffer!
    var rayStride = MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride + MemoryLayout<SIMD3<Float16>>.stride
    
    var rayDataBuffer: MTLBuffer!
    var rayDataBufferOffset = 0
    var rayDataBufferIndex = 0
    
    var randomBuffer: MTLBuffer!
    var randomBufferOffset = 0
    var randomBufferIndex = 0
    
    var shadowRayBuffer: MTLBuffer!
    var shadowRayBufferOffset = 0
    var shadowRayBufferIndex = 0
    
    var intersectionBuffer: MTLBuffer!
    var intersector: MPSRayIntersector!

    let intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates>.stride
    
    var renderTarget: MTLTexture!
    var renderPipeline: MTLRenderPipelineState!
    
    var accumulationTarget: MTLTexture!
    var accumulatePipeline: MTLComputePipelineState!
    
    var accelerationStructure: MPSInstanceAccelerationStructure!
    var transformBuffer: MTLBuffer!
    
    var semaphore: DispatchSemaphore!
    
    public static let maxFramesInFlight = 1
    let alignedRayDataSize = (MemoryLayout<RayData>.size + 255) & ~255
    var frameIndex: uint = 0
    var gameObjectCount = 0
    
    var textureAtlas: MTLTexture!
    var modelVertexCounts: [Int] = []
    var currentTextures: [String] = []
    var textureInfo: [TextureLibrary.Img] = []
    var textureData: [TextureData] = []
    
    var meshBuffer: MTLBuffer!
    
    var _vertexBuffer: MTLBuffer!
    
    init()
    {
        super.init("Scene")
        
        semaphore = DispatchSemaphore.init(value: 1)
        buildPipelineStates()
        buildScene()
        buildTextureAtlas()
 
        let commandBuffer = Engine.CommandQueue.makeCommandBuffer()!
        modifyVertices(commandBuffer: commandBuffer)
        commandBuffer.commit()
        commandBuffer.addCompletedHandler({ _ in
            self.generateChildrenContent()
            self.updateTransformBuffer()
      
            self.createBuffers()
            self.buildIntersector()
            self.createAccelerationStructure()
            self.updateScreenSize()
        })
        
        
        
     
    }
    
    func buildScene() { }
    
    func updateRaytracingStuff()
    {
        updateRayData()
        
        updateRandomBuffer()
        rayDataBufferIndex = (rayDataBufferIndex + 1) % Scene.maxFramesInFlight
    }
    
    func buildTextureAtlas()
    {
        
        for child in children
        {
            if let obj = child as? GameObject
            {
                for mesh in obj.getModel.getMeshes
                {
                    for material in mesh.submeshMaterials
                    {
                        if (!currentTextures.contains(material.name))
                        {
                            currentTextures.append(material.name)
                        }
                    }
                }
            }
        }
        
        let output  = ModelLoader.textures.packIncludedTextures(currentTextures, packer: ModelLoader.texturePacker)
        textureAtlas = output.0
        textureInfo = output.1
        
        textureData = textureInfo.compactMap {
            TextureData(offset: $0.pos, size: $0.size)
        }
    
    }
    
    func updateTransformBuffer()
    {
        transformBuffer = Engine.Device.makeBuffer(length: float4x4.stride(gameObjectCount))
        let transformArray = transformBuffer.contents().bindMemory(to: float4x4.self, capacity: gameObjectCount)
        
        var i = 0
        for child in children
        {
            if child is GameObject
            {
                transformArray[i] = child.modelMatrix
                i += 1
            }
        }
        
        transformBuffer.label = "Transform Vertices"
    }
    
    func generateChildrenContent()
    {
        self.meshBuffer = Engine.Device.makeBuffer(length: MemoryLayout<ShaderMesh>.stride * gameObjectCount)
        self.meshBuffer.label = "Mesh Buffer"
        
        let meshes = meshBuffer.contents().bindMemory(to: ShaderMesh.self, capacity: gameObjectCount)
        
        var i = 0
        for child in self.children
        {
            if let obj = child as? GameObject
            {
                var infoArray: [SubmeshInfo] = []
                for mesh in obj.getModel.getMeshes
                {
                    for (index, count) in mesh.submeshIndexCounts.enumerated()
                    {
                        var info = SubmeshInfo()
                        info.bufferLength = UInt32(count)
                        findTextureIndex(mdlMaterial: mesh.submeshMaterials[index], info: &info)
                        print(info)
                        infoArray.append(info)
                    }
                    
                }
                
                
                obj.submeshBuffer  = Engine.Device.makeBuffer(bytes: &infoArray, length: SubmeshInfo.size(infoArray.count))!
                obj.submeshBuffer.label = obj.name + " info buffer"
                
                obj.shaderMesh.submeshes = obj.submeshBuffer.gpuAddress
                obj.shaderMesh.normals = obj.normalBuffer.gpuAddress
                obj.shaderMesh.positions = obj.modifiedVertexBuffer.gpuAddress
                obj.shaderMesh.generics = obj.vertexColourDataBuffer.gpuAddress
                meshes[i] = obj.shaderMesh
                i += 1
            }
        }

    }
    
    func createAccelerationStructure()
    {
        let group = MPSAccelerationStructureGroup(device: Engine.Device)
        var triangleAccelerationStrutures: [MPSTriangleAccelerationStructure] = []
        var vertexBufferOffset = 0
        let _instanceBuffer = Engine.Device.makeBuffer(length: MemoryLayout<UInt32>.stride * gameObjectCount)
        _instanceBuffer?.label = "Instance Buffer"
        let instances = _instanceBuffer?.contents().bindMemory(to: UInt32.self, capacity: gameObjectCount)
        var i: UInt32 = 0
        
        for child in children
        {
            if let obj = child as? GameObject
            {
                instances![Int(i)] = i
                i += 1
                
                obj._accelerationStructure = MPSTriangleAccelerationStructure(group: group)
                
                obj._accelerationStructure.vertexBuffer = self._vertexBuffer
                obj._accelerationStructure.vertexBufferOffset = SIMD3<Float>.stride(vertexBufferOffset)
                obj._accelerationStructure.triangleCount = obj.vertexCount / 3
                
                if obj.getModel.animations != nil
                {
                    obj._accelerationStructure.usage = .refit
                }
                obj._accelerationStructure.rebuild()
                
                vertexBufferOffset += obj.vertexCount
                triangleAccelerationStrutures.append(obj._accelerationStructure)
            }
        }
        
        self.accelerationStructure = MPSInstanceAccelerationStructure(group: group)
        self.accelerationStructure.instanceCount = gameObjectCount
        self.accelerationStructure.transformBuffer = transformBuffer
        self.accelerationStructure.instanceBuffer = _instanceBuffer
        self.accelerationStructure.accelerationStructures = triangleAccelerationStrutures
        
    }
    
    func rebuildAccelerationStructure(commandBuffer: MTLCommandBuffer, completeHandler: @escaping  () -> Void)
    {
        updateTransformBuffer()
        modifyVertices(commandBuffer: commandBuffer)
        
        commandBuffer.addCompletedHandler({ _ in
            for child in self.children
            {
                if let obj = child as? GameObject
                {
                    obj._accelerationStructure.vertexBuffer = self._vertexBuffer
                }
            }
            
            self.accelerationStructure.rebuild()
            completeHandler()
            self.semaphore.signal()
        })
    }
    
    func updateScreenSize()
    {
        frameIndex = 0
        
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = Preferences.colourPixelFormat
        renderTargetDescriptor.textureType = .type2D
        renderTargetDescriptor.width = Renderer.ScreenSize.x
        renderTargetDescriptor.height = Renderer.ScreenSize.y
        renderTargetDescriptor.storageMode = .private
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        renderTarget = Engine.Device.makeTexture(descriptor: renderTargetDescriptor)
        
        let rayCount = Renderer.ScreenSize.x * Renderer.ScreenSize.y
        rayBuffer = Engine.Device.makeBuffer(length: rayStride * rayCount,
                                      options: .storageModePrivate)
        rayBuffer.label = "Ray Buffer"
        shadowRayBuffer =  Engine.Device.makeBuffer(length: rayStride * rayCount,
                                            options: .storageModePrivate)
        shadowRayBuffer.label = "Shadow Ray Buffer"
        accumulationTarget = Engine.Device.makeTexture(
          descriptor: renderTargetDescriptor)
        
        intersectionBuffer = Engine.Device.makeBuffer(
          length: intersectionStride * rayCount,
          options: .storageModePrivate)
        intersectionBuffer.label = "Intersection Buffer"
    }
    
    func buildIntersector()
    {
        intersector = MPSRayIntersector(device: Engine.Device)
        intersector?.rayDataType = .originMinDistanceDirectionMaxDistance
        intersector?.rayStride = rayStride
    }
    
    private func buildPipelineStates()
    {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction =  Engine.DefaultLibrary.makeFunction(name: "fragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.colourPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        
        do {
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction(name: "vertexModifiers")
            transformPipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor,
                                                                           options: [], reflection: nil)
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction( name: "primaryRays")
            primaryRayPipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction(name: "shadeKernel")
            shadePipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction(name: "shadowKernel")
            shadowPipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction(name: "accumulateKernel")
            accumulatePipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
            
            renderPipeline = try Engine.Device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
        } catch let error as NSError
        {
            print("Error making compute pipelines \(error)")
        }
    }
    
    public func addCamera(_ camera: Camera, _ isActive: Bool = true)
    {
        cameraManager.addCamera(camera)
        if (isActive)
        {
            cameraManager.setCamera(camera.cameraType)
        }
    }
    
    func updateSceneConstants()
    {
        self.sceneConstants.viewMatrix = cameraManager.currentCamera.viewMatrix
        self.sceneConstants.projectionMatrix = cameraManager.currentCamera.projectionMatrix
        self.sceneConstants.totalGameTime = GameTime.TotalGameTime
    }
    
    func updateCameras()
    {
        cameraManager.update()
    }
    
    func updateRayData()
    {
        rayDataBufferOffset = alignedRayDataSize * rayDataBufferIndex
        let pointer = rayDataBuffer!.contents().advanced(by: rayDataBufferOffset)
        let uniforms = pointer.bindMemory(to: RayData.self, capacity: 1)
        
        var camera = CameraToShader()
//        camera.position = cameraManager.currentCamera.getPosition()
        camera.position = SIMD3<Float>(0.0, 0.0, 80.0)
        camera.forward = SIMD3<Float>(0.0, 0.0, -1.0)
        camera.right = SIMD3<Float>(1.0, 0.0, 0.0)
        camera.up = SIMD3<Float>(0.0, 1.0, 0.0)
        
        let fieldOfView = 45.0 * (Float.pi / 180.0)
        let aspectRatio = Renderer.AspectRatio
        let imagePlaneHeight = tanf(fieldOfView / 2.0)
        let imagePlaneWidth = aspectRatio * imagePlaneHeight
        
        camera.right *= imagePlaneWidth
        camera.up *= imagePlaneHeight
        
        var light = AreaLight()
        light.position = SIMD3<Float>(40.0, 40.0, 40.0)
        light.forward = SIMD3<Float>(0.0, -1.0, 0.0)
        light.right = SIMD3<Float>(0.25, 0.0, 0.0)
        light.up = SIMD3<Float>(0.0, 0.0, 0.25)
        light.color = SIMD3<Float>(repeating: 10000)
        
        uniforms.pointee.camera = camera
        uniforms.pointee.light = light
        
        uniforms.pointee.width = uint(Renderer.ScreenSize.x)
        uniforms.pointee.height = uint(Renderer.ScreenSize.y)
        uniforms.pointee.blocksWide = ((uniforms.pointee.width) + 15) / 16
        uniforms.pointee.frameIndex = frameIndex
        frameIndex += 1
    }
    
    func updateRandomBuffer()
    {
        randomBufferOffset = 256 * SIMD2<Float>.stride * rayDataBufferIndex
        let pointer = randomBuffer!.contents().advanced(by: randomBufferOffset)
        var random = pointer.bindMemory(to: SIMD2<Float>.self, capacity: 256)
        for _ in 0..<256 {
            random.pointee = SIMD2<Float>(Float(drand48()), Float(drand48()) )
            random = random.advanced(by: 1)
        }
    }
    
    func createBuffers()
    {
        let rayDataBufferSize = alignedRayDataSize * Scene.maxFramesInFlight
        
        let options: MTLResourceOptions = .storageModeShared
        
        rayDataBuffer = Engine.Device.makeBuffer(length: rayDataBufferSize, options: options)
        rayDataBuffer.label = "Ray Data Buffer"
        randomBuffer = Engine.Device.makeBuffer(length: 256 * SIMD2<Float>.stride * Scene.maxFramesInFlight, options: options)
        randomBuffer.label = "Random Buffer"
    }
    
    func findTextureIndex(mdlMaterial: MDLMaterial,  info: inout SubmeshInfo)
    {
        for (index, image) in textureInfo.enumerated()
        {
            if (mdlMaterial.name == image.name)
            {
                switch (image.type)
                {
                case .baseColor:
                    info.colourTextureIndex = UInt8(index)
                    break
                case .objectSpaceNormal:
                    info.normalTextureIndex = UInt8(index)
                    break
                case .ambientOcclusion:
                    info.aoTextureIndex = UInt8(index)
                    break
                default:
                    break
                    
                }
            }
        }
    }
    
    func modifyVertices(commandBuffer: MTLCommandBuffer)
    {
        let kernelEncoder = commandBuffer.makeComputeCommandEncoder()!
        kernelEncoder.label = "Transform Pipeline"
        kernelEncoder.setComputePipelineState(transformPipeline)
        let w = transformPipeline.threadExecutionWidth
        let threadsPerThreadGroup = MTLSize(width: w, height: 1, depth: 1)
        
        var vertexCount = 0
        for child in children
        {
            if let obj = child as? GameObject
            {
                obj.modifyVertices(kernelEncoder: kernelEncoder, threadsPerThreadGroup)
                vertexCount += obj.vertexCount
            }
        }
        
        kernelEncoder.endEncoding()
        
        self._vertexBuffer = Engine.Device.makeBuffer(length: SIMD3<Float>.stride(vertexCount))
        self._vertexBuffer.label = "Scene Vertex Buffer"
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        vertexCount = 0
        for child in children
        {
            if let obj = child as? GameObject
            {
                blitEncoder.copy(from: obj.modifiedVertexBuffer, sourceOffset: 0, to: _vertexBuffer, destinationOffset: vertexCount, size: SIMD3<Float>.stride(obj.vertexCount))
                vertexCount += SIMD3<Float>.stride(obj.vertexCount)
            }
        }
        blitEncoder.endEncoding()
        
    }
    
    func createRays(_ commandBuffer: MTLCommandBuffer)
    {
        updateRaytracingStuff()
//        MARK: Create Rays
        let kernelEncoder = commandBuffer.makeComputeCommandEncoder()!
        kernelEncoder.label = "Create Rays"
        
        kernelEncoder.setComputePipelineState(primaryRayPipeline)
        
        let w = primaryRayPipeline.threadExecutionWidth
        let h = primaryRayPipeline.maxTotalThreadsPerThreadgroup / w
        
        let threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSizeMake(Renderer.ScreenSize.x, Renderer.ScreenSize.y, 1)
        
        kernelEncoder.setBuffer(rayDataBuffer, offset: rayDataBufferOffset, index: 0)
        kernelEncoder.setBuffer(rayBuffer, offset: 0, index: 1)
        kernelEncoder.setBuffer(randomBuffer, offset: randomBufferOffset, index: 2)
        
        kernelEncoder.setTexture(renderTarget, index: 0)
        
        kernelEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        
        kernelEncoder.endEncoding()
    }
    
    func render(_ commandBuffer: MTLCommandBuffer) {
        
        
    
        commandBuffer.pushDebugGroup("Start Render \(name)")
        
        let width = Renderer.ScreenSize.x
        let height = Renderer.ScreenSize.y
        
//        MARK: Start Raytracing
        intersector.label = "First Ray Trace"
        intersector?.intersectionDataType = .distancePrimitiveIndexInstanceIndexCoordinates
        intersector?.intersectionStride = intersectionStride
        intersector?.cullMode = .back
        intersector?.encodeIntersection(commandBuffer: commandBuffer,
                                        intersectionType: .nearest,
                                        rayBuffer: rayBuffer,
                                        rayBufferOffset: 0,
                                        intersectionBuffer: intersectionBuffer,
                                        intersectionBufferOffset: 0,
                                        rayCount: width * height,
                                        accelerationStructure: accelerationStructure)
        
        
        
//        MARK: Shading
        var kernelEncoder = commandBuffer.makeComputeCommandEncoder()!
        kernelEncoder.label = "Shading"
        
        let threadsPerThreadGroup = MTLSize(width: 8, height: 8, depth: 1)
        let threadsPerGrid = MTLSize(width: (width + threadsPerThreadGroup.width - 1)
                                     / threadsPerThreadGroup.width, height: (height + threadsPerThreadGroup.height - 1)
                                     / threadsPerThreadGroup.height, depth: 1)
        
        kernelEncoder.setComputePipelineState(shadePipeline)
        
        for child in self.children
        {
            if let obj = child as? GameObject
            {
                kernelEncoder.useResource(obj.vertexColourDataBuffer, usage: .read)
                kernelEncoder.useResource(obj.normalBuffer, usage: .read)
                kernelEncoder.useResource(obj.modifiedVertexBuffer, usage: .read)
                kernelEncoder.useResource(obj.submeshBuffer, usage: .read)
            }
        }
        
        kernelEncoder.setBuffer(rayDataBuffer,
                                  offset: rayDataBufferOffset,
                                  index: 0)
        kernelEncoder.setBuffer(rayBuffer, offset: 0, index: 1)
        kernelEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 2)
        kernelEncoder.setBuffer(intersectionBuffer, offset: 0,index: 3)
        kernelEncoder.setBuffer(meshBuffer, offset: 0,index: 4)
        kernelEncoder.setBuffer(randomBuffer,offset: randomBufferOffset,index: 5)
        kernelEncoder.setBytes(&textureData, length: TextureData.stride(textureData.count), index: 6)
        kernelEncoder.setTexture(textureAtlas, index: 0)
        
      
        
        kernelEncoder.dispatchThreadgroups(threadsPerGrid,
          threadsPerThreadgroup: threadsPerThreadGroup)
        
        kernelEncoder.endEncoding()
        
//        MARK: Shadows
        
        intersector?.label = "Shadows Intersector"
        intersector?.intersectionDataType = .distance
        intersector?.intersectionStride = SIMD3<Float>.stride
        intersector?.encodeIntersection(
                        commandBuffer: commandBuffer,
                        intersectionType: .any,
                        rayBuffer: shadowRayBuffer,
                        rayBufferOffset: 0,
                        intersectionBuffer: intersectionBuffer,
                        intersectionBufferOffset: 0,
                        rayCount: width * height,
                        accelerationStructure: accelerationStructure!)
        
        kernelEncoder = commandBuffer.makeComputeCommandEncoder()!
        kernelEncoder.label = "Shadows"
        
        kernelEncoder.setBuffer(rayDataBuffer,
                                  offset: rayDataBufferOffset,
                                  index: 0)
        kernelEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 1)
        kernelEncoder.setBuffer(intersectionBuffer, offset: 0,
                                  index: 2)
        
        kernelEncoder.setTexture(renderTarget, index: 0)
        kernelEncoder.setComputePipelineState(shadowPipeline!)
        kernelEncoder.dispatchThreadgroups(threadsPerGrid,
                                           threadsPerThreadgroup: threadsPerThreadGroup)
    
        kernelEncoder.endEncoding()
        
        // MARK: Accumulation
        kernelEncoder = commandBuffer.makeComputeCommandEncoder()!
        kernelEncoder.label = "Accumulation"
        
        kernelEncoder.setBuffer(rayDataBuffer, offset: rayDataBufferOffset, index: 0)
        kernelEncoder.setTexture(renderTarget, index: 0)
        kernelEncoder.setTexture(accumulationTarget, index: 1)
        kernelEncoder.setComputePipelineState(accumulatePipeline)
        kernelEncoder.dispatchThreadgroups(threadsPerGrid,
                                             threadsPerThreadgroup: threadsPerThreadGroup)
        
        kernelEncoder.endEncoding()
        
        commandBuffer.popDebugGroup()
        
        
        
    }
    
    func presentTexture(_ renderEncoder: MTLRenderCommandEncoder)
    {
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentTexture(accumulationTarget, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    override func addChild(_ child: Apex) {
        
        if child is GameObject
        {
            self.gameObjectCount += 1
        }
        super.addChild(child)
    }
    
    override func removeChild(child: Apex)
    {
        if child is GameObject
        {
            self.gameObjectCount -= 1 
        }
        super.removeChild(child: child)
    }
    
    
}
