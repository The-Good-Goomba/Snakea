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
    private var _pitch: Float = 0
    private var _roll: Float = 0
    private var _yaw: Float = 0
    private var _zoom: Float = 60.0
    
    
    var forward: SIMD3<Float> {
        return SIMD3<Float>(sin(_yaw),sin(_pitch),-cos(_yaw))
    }
    
    var right: SIMD3<Float> {
        return SIMD3<Float>(cos(_yaw),0.0,sin(_yaw))
    }
    
    var up: SIMD3<Float> {
        return SIMD3<Float>(-sin(_yaw) * sin(_pitch),cos(_pitch),cos(_yaw) * sin(_pitch))
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
    
    var yaw: Float {
        get { return _yaw }
        set { _yaw = newValue
            updateShaderCamera()
        }
    }
    var pitch: Float {
        get { return _pitch }
        set { _pitch = newValue
            updateShaderCamera()
        }
    }
    var roll: Float {
        get { return _roll }
        set { _roll = newValue
            updateShaderCamera()
        }
    }
    
    func updateShaderCamera()
    {
        shaderCamera.forward = normalize(forward)
        shaderCamera.right = normalize(right)
        shaderCamera.up = -normalize(up)
        
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
