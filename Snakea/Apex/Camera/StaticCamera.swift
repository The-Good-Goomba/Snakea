//
//  StaticCamera.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit

class StaticCamera: Camera
{
    private var _zoom: Float = 45.0
    var zoom: Float {
        get {
            return _zoom
        }
        set (newVal) {
            _zoom = newVal
            updateProjectionMatrix()
        }
    }
    
    
    var _projectionMatrix: float4x4 = .identity()
    
    override var projectionMatrix: matrix_float4x4
    {
        return _projectionMatrix
    }
    
    init()
    {
        super.init(.Static)
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: self.zoom,
                                                        aspectRatio: Renderer.AspectRatio,
                                                        near: 0.1, far: 1000)
    }
    
    override func updateProjectionMatrix() {
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: self.zoom,
                                                        aspectRatio: Renderer.AspectRatio,
                                                        near: 0.1, far: 1000)
    }
}
