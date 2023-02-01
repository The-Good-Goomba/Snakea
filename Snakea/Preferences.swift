//
//  Preferences.swift
//  Snakea
//
//  Created by Matthew  Eatough on 24/10/2022.
//

import MetalKit


class Preferences
{
    public static let colourPixelFormat: MTLPixelFormat = .rgba8Unorm
    
    public static let depthStencilPixelFormat: MTLPixelFormat = .invalid
    
    public static let clearColour: MTLClearColor = MTLClearColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0)
    
    public static let sampleCount: Int = 1
    
}
