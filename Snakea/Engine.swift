//
//  Engine.swift
//  Snakea
//
//  Created by Matthew  Eatough on 24/10/2022.
//

import MetalKit

class Engine
{
    public static var Device: MTLDevice!
    public static var CommandQueue: MTLCommandQueue!
    public static var DefaultLibrary: MTLLibrary!
    
    
    public static func Initialise(_ device: MTLDevice)
    {
        self.Device = device
        self.CommandQueue = self.Device.makeCommandQueue()
        self.DefaultLibrary = self.Device.makeDefaultLibrary()
        
        Graphics.Initialise()
        
        ModelLoader.Initialise()
        
        
        
    }
}
