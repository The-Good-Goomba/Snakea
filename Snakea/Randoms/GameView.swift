//
//  ViewController.swift
//  Snakea
//
//  Created by Matthew  Eatough on 24/10/2022.
//

import MetalKit

class GameView: MTKView
{
    var renderer: Renderer!
    
    required init(coder: NSCoder) {
        
        super.init(coder: coder)

        self.device = MTLCreateSystemDefaultDevice()
        
        Engine.Initialise(self.device!)
    
        self.renderer = Renderer(self)
        
        self.colorPixelFormat = Preferences.colourPixelFormat
        
        self.clearColor = Preferences.clearColour
        
        self.depthStencilPixelFormat = Preferences.depthStencilPixelFormat
        
        self.delegate = self.renderer
    
        
    }
    
    
}


// Keyboard Input
extension GameView
{
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent)
    {
        Keyboard.SetKeyPressed(event.keyCode, isOn: true)
    }
    
    override func keyUp(with event: NSEvent)
    {
        Keyboard.SetKeyPressed(event.keyCode, isOn: false)
    }
}


// Mouse Input
extension GameView
{
    override func mouseDown(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
    }
    
    override func mouseUp(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
    }
    
    override func otherMouseDown(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
    }
    
    override func otherMouseUp(with event: NSEvent) {
        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
    }
}


extension GameView
{
    override func mouseMoved(with event: NSEvent) {
        setMousePositionChanged(event: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        setMousePositionChanged(event: event)
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        setMousePositionChanged(event: event)
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        setMousePositionChanged(event: event)
    }
    
    private func setMousePositionChanged(event: NSEvent)
    {
        let overallLocation = SIMD2<Float>(Float(event.locationInWindow.x), Float(event.locationInWindow.y))
        let deltaLocation = SIMD2<Float>(Float(event.deltaX), Float(event.deltaY))
        
        Mouse.SetMousePositionChange(overallPosition: overallLocation, deltaPosition: deltaLocation)
    }
    
    override func scrollWheel(with event: NSEvent) {
        Mouse.ScrollMouse(deltaY: Float(event.deltaY))
    }
    
    override func updateTrackingAreas() {
        let area: NSTrackingArea = NSTrackingArea(rect: self.bounds,
                                                  options: [NSTrackingArea.Options.activeAlways,
                                                            NSTrackingArea.Options.mouseMoved,
                                                            NSTrackingArea.Options.enabledDuringMouseDrag],
                                                  owner: self,
                                                  userInfo: nil)
        self.addTrackingArea(area)
    }
}

