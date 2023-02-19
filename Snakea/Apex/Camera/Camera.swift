//
//  Camera.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit

enum CameraTypes
{
    case Static
}

class Camera
{
    var cameraType: CameraTypes!
    
    private var _position: SIMD3<Float> = [0,0,0]
    private var _rotation: SIMD3<Float> = [0,0,0]
    private var _zoom: Float = 45.0
    
    var forward: SIMD3<Float> {
        return SIMD3<Float>(sin(_rotation.y),0.0,-cos(_rotation.y))
    }
    var right: SIMD3<Float> {
        return SIMD3<Float>(cos(_rotation.y),0.0,sin(_rotation.y))
    }
    var up: SIMD3<Float> {
        return SIMD3<Float>(0.0,1.0,0.0)
    }
    
    var zoom: Float {
        get { return _zoom }
        set { _zoom = newValue
            updateShaderCamera()
        }
    }
    
    var position: SIMD3<Float> {
        get { return _position }
        set { _position = newValue
            shaderCamera.position = _position
        }
    }
    
    var rotation: SIMD3<Float> {
        get { return _rotation }
        set { _rotation = newValue
            updateShaderCamera()
        }
    }
    
    func updateShaderCamera()
    {
        shaderCamera.forward = forward
        shaderCamera.right = right
        shaderCamera.up = up
        
        let fieldOfView = zoom * (Float.pi / 180.0)
        let aspectRatio = Renderer.AspectRatio
        let imagePlaneHeight = tanf(fieldOfView / 2.0)
        let imagePlaneWidth = aspectRatio * imagePlaneHeight
        
        shaderCamera.right *= imagePlaneWidth
        shaderCamera.up *= imagePlaneHeight
    }
    
    var shaderCamera = CameraToShader()

    init(_ type: CameraTypes)
    {
        self.cameraType = type
        updateShaderCamera()
        shaderCamera.position = _position
    }
    
    func update() { }
    
}
