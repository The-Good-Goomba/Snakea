//
//  Renderer.swift
//  Snakea
//
//  Created by Matthew  Eatough on 24/10/2022.
//

import MetalKit

class Renderer: NSObject
{
    public static var ScreenSize: SIMD2<Int> = [0,0]
    public static var AspectRatio: Float {
        return Float(ScreenSize.x) / Float(ScreenSize.y)
    }
    
    init(_ mtkView: MTKView) {
        super.init()
        updateScreenSize(mtkView)
        SceneManager.initialise()
        SceneManager.setScene(.Level1)
        
    }
}

extension Renderer: MTKViewDelegate
{
    public func updateScreenSize(_ view: MTKView)
    {
        Renderer.ScreenSize = [Int(view.bounds.width) , Int(view.bounds.height)]
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateScreenSize(view)
        SceneManager.getCurrentScene.updateScreenSize()
    }
    
    func draw(in view: MTKView) {
        
//        let captureDescriptor = MTLCaptureDescriptor()
//        captureDescriptor.captureObject = Engine.
//        destination is developerTools by default
//        try? MTLCaptureManager.shared().startCapture(with: captureDescriptor)

        Mouse.UpdateDX()
        SceneManager.doUpdate( view: view, deltaTime: 1 / Float(view.preferredFramesPerSecond))
        
//        if MTLCaptureManager.shared().isCapturing {
//                MTLCaptureManager.shared().stopCapture()
//            }
        
    }
}


