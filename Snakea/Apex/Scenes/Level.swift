//
//  Level.swift
//  Snakea
//
//  Created by Matthew Eatough on 14/2/2023.
//


import Metal

class Level: Scene
{
    var gravitationConstant: Float = 6.674 * 10e-7
    
    var collisionPipeline: MTLComputePipelineState!
    var collisionBuffer: MTLBuffer!
    var collisionTriangleCount: Int!
    
    var entityBuffer: MTLBuffer!
    var entityCount: Int = 0

    var recreateCollisionBuffer: Bool = true
    var recreateEntity: Bool = true
    
    var collisionTexture: MTLTexture!
    
    override init()
    {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        do {
            computeDescriptor.computeFunction = Engine.DefaultLibrary.makeFunction(name: "collisionSphereTriangle")
            collisionPipeline = try Engine.Device.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
        } catch let error as NSError {
            print(error)
        }
        super.init()
        
        createEntityBufferForCollision()
        createArgumentBufferForCollision()
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = collisionTriangleCount
        descriptor.height = entityCount
        descriptor.pixelFormat = Preferences.colourPixelFormat
        descriptor.usage = .shaderWrite
        collisionTexture = Engine.Device.makeTexture(descriptor: descriptor)
    }
    
    override func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil) {
        
        
        let velocityArray = entityBuffer.contents().bindMemory(to: Sphere.self, capacity: entityCount)
        var i = 0
        for child in children
        {
            if let obj = child as? Entity
            {
                obj.move(velocityArray[i].velocity)
                obj.velocity = velocityArray[i].velocity
                obj.acceleration = SIMD3<Float>(repeating: 0.0)
                i += 1
            }
        }
        computeGravity()
        i = 0
        for child in children
        {
            if let obj = child as? Entity
            {
                obj.velocity += obj.acceleration
                velocityArray[i] = obj.sphere
                i += 1
            }
        }
        
        
        
        
        if ( children.count != entityCount)
        {
            if (recreateEntity) { createEntityBufferForCollision() }
            if (recreateCollisionBuffer){ createArgumentBufferForCollision() }
            
            computeCollision(kernelEncoder!)
        }
        super.update(kernelEncoder)
    }
    
    func computeCollision(_ kernelEncoder: MTLComputeCommandEncoder)
    {
        kernelEncoder.pushDebugGroup("Compute Collision")
        kernelEncoder.setComputePipelineState(collisionPipeline)
        let threadsPerThreadGroup = MTLSize(width: 8, height: 8, depth: 1)
//        FIXME: I think this can be better
        let threadsPerGrid = MTLSizeMake(collisionTriangleCount, entityCount, 1)
        
 
        kernelEncoder.setTexture(collisionTexture, index: 0)
        
        
        kernelEncoder.setBuffer(entityBuffer, offset: 0, index: 0)
        kernelEncoder.setBuffer(collisionBuffer, offset: 0, index: 1)
  
        for child in children
        {
            if let obj = child as? GameObject
            {
                if (!(obj is Entity))
                {
                    kernelEncoder.useResource(obj.normalBuffer, usage: .read)
                    kernelEncoder.useResource(obj.modifiedVertexBuffer, usage: .read)
        }}}
        
        kernelEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        kernelEncoder.popDebugGroup()
    }
    
    
    func createArgumentBufferForCollision()
    {
        let meshCount = (children.count - entityCount)
        collisionBuffer = Engine.Device.makeBuffer(length: MemoryLayout<collisionBufferObject>.stride * meshCount)
        let collisionArray = collisionBuffer.contents().bindMemory(to: collisionBufferObject.self, capacity: meshCount)
        collisionTriangleCount = 0
        var i = 0
        for child in children
        {
            if let obj = child as? GameObject
            {
                if (!(obj is Entity))
                {
                    collisionArray[i] = collisionBufferObject(triangleCount: UInt32(obj.vertexCount / 3),
                                                              normals: obj.normalBuffer.gpuAddress,
                                                              vertices: obj.modifiedVertexBuffer.gpuAddress)
                    collisionTriangleCount += obj.vertexCount
                    i += 1
                }
            }
        }
        collisionTriangleCount /= 3
        
    }
    func createEntityBufferForCollision()
    {
        entityBuffer = Engine.Device.makeBuffer(length: MemoryLayout<Sphere>.size * entityCount, options: .storageModeShared)
        let entityArray = entityBuffer.contents().bindMemory(to: Sphere.self, capacity: entityCount)
        
        var i = 0
        for child in children
        {
            if let bruh = child as? Entity
            {
                entityArray[i] = bruh.sphere
                i += 1
            }
        }
        
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
                        let distSq = distance_squared(attractor.getPosition(), entity.getPosition())
                        entity.acceleration += (gravitationConstant * (attractor.mass/distSq)) * (attractor.getPosition() - entity.getPosition()) * simd_rsqrt(distSq)
                    }
                }
            }
        }
    }
    
    override func addChild(_ child: Apex) {
        if child is Entity
        {
            entityCount += 1
            recreateEntity = true
        } else if child is GameObject {
            recreateCollisionBuffer = true
        }
        super.addChild(child)
    }
    override func removeChild(child: Apex) {
        if child is Entity
        {
            entityCount -= 1
            recreateEntity = true
        } else if child is GameObject {
            recreateCollisionBuffer = true
        }
        super.removeChild(child: child)
    }
    override func removeChild(index: Int) {
        if children[index] is Entity
        {
            entityCount -= 1
            recreateEntity = true
        } else if children[index] is GameObject {
            recreateCollisionBuffer = true
        }
        super.removeChild(index: index)
    }
    
}
