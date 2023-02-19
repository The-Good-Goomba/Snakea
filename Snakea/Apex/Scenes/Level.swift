//
//  Level.swift
//  Snakea
//
//  Created by Matthew Eatough on 14/2/2023.
//


import Metal

class Level: Scene
{
    var gravitationConstant: Float = 6.674 * 10e-5
    
    override func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil) {
        computeGravity()
        super.update(kernelEncoder)
    }
    
    func computeGravity()
    {
        for bruh in children
        {
            if let attractor = bruh as? AttractorObject
            {
                for obj in children
                {
                    if let entity = obj as? Entity
                    {
                
                        entity.acceleration += gravitationConstant * (attractor.mass/distance_squared(attractor.getPosition(), entity.getPosition()))
                    }
                }
            }
        }
    }
    
    
    
}
