//
//  TransformComponent.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import ModelIO

class TransformComponent
{
    let keyTransforms: [float4x4]
    let duration: Float
    var currentTransformation: float4x4 = .identity()
    
    init(transform: MDLTransformComponent, object: MDLObject, startTime: TimeInterval, endTime: TimeInterval)
    {
        duration = Float(endTime - startTime)
        let timeStride = stride(from: startTime, to: endTime, by: 1/TimeInterval(GameTime.FPS))
        keyTransforms = Array(timeStride).map {time in
            return MDLTransform.globalTransform(with: object, atTime: time)
        }
    }
    
    func setCurrentTransform(at time: Float)
    {
        guard duration > 0 else {
            self.currentTransformation = .identity()
            return
        }
        let frame = Int(fmod(time, duration) * Float(GameTime.FPS))
        if frame < keyTransforms.count {
            currentTransformation = keyTransforms[frame]
        } else {
            currentTransformation = keyTransforms.last ?? .identity()
        }
    }
    
    
    
}
