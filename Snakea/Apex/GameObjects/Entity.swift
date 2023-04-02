//
//  Player.swift
//  Snakea
//
//  Created by Matthew  Eatough on 14/2/2023.
//

import Metal

class Entity: GameObject
{
    var velocity: SIMD3<Float> = SIMD3<Float>(repeating: 0.0)
    var acceleration: SIMD3<Float> = SIMD3<Float>(repeating: 0.0)
    var radius: Float = 1
    
    var sphere: Sphere {
        return Sphere(position: self.getPosition(), velocity: velocity, radius: radius)
    }
    
    override func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil) {
        updateRotation()
        super.update(kernelEncoder)
    }
    
    func updateRotation()
    {
        let a = normalize(acceleration)
        setRotationZ(asin(a.x))
        setRotationX(acos(a.y))
    }
    
}
