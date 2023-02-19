//
//  Light.swift
//  Snakea
//
//  Created by Matthew  Eatough on 15/2/2023.
//

class Light
{
    private var _position: SIMD3<Float> = [0,0,0]
    private var _rotation: SIMD3<Float> = [0,0,0]
    private var _colour: SIMD3<Float> = SIMD3<Float>(repeating: 0.0)
    
    var forward: SIMD3<Float> {
        return SIMD3<Float>(sin(_rotation.y),0.0,-cos(_rotation.y))
    }
    var right: SIMD3<Float> {
        return SIMD3<Float>(cos(_rotation.y),0.0,sin(_rotation.y))
    }
    var up: SIMD3<Float> {
        return SIMD3<Float>(0.0,1.0,0.0)
    }
    
    var colour: SIMD3<Float> {
        get { return _colour }
        set { _colour = newValue
            areaLight.color = _colour
        }
    }
    
    var position: SIMD3<Float> {
        get { return _position }
        set {
            _position = newValue
            areaLight.position  = _position
        }
    }
    
    var rotation: SIMD3<Float> {
        get { return _rotation }
        set {
            _rotation = newValue
            areaLight.right     = right
            areaLight.forward   = forward
            areaLight.up        = up
        }
    }
    
    var areaLight: AreaLight = AreaLight()
    
}
