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

class Camera: Apex
{
    var cameraType: CameraTypes!
    private var _viewMatrix = matrix_identity_float4x4
    var viewMatrix: matrix_float4x4 {
        return _viewMatrix
    }
    
    var projectionMatrix: matrix_float4x4 {
        return matrix_identity_float4x4
    }
    
    init(_ type: CameraTypes)
    {
        super.init("Camera")
        self.cameraType = type
    }
    
    func updateProjectionMatrix() { }
    
    override func updateModelMatrix() {
        let translationMatrix = float4x4(translation: self.getPosition())
        
        let rotateMatrix = float4x4(rotationYXZ: [-self.getRotationX(),
                                                   self.getRotationY(),
                                                  0])
        _viewMatrix = (rotateMatrix * translationMatrix).inverse
    }
    
}
