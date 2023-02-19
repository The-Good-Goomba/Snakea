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
    
    override func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil) {
        velocity += acceleration
        move(velocity)
        acceleration = SIMD3<Float>(repeating: 0.0)
        super.update(kernelEncoder)
    }
}
