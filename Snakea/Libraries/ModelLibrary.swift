//
//  ModelLibrary.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit

enum ModelTypes {
    case Level1Mesh
    case Cactus
}

class ModelLibrary
{
    private var library: [ModelTypes: Model] = [:]
    
    init()
    {
        
        library.updateValue(Model("planet"), forKey: .Level1Mesh)
        library.updateValue(Model("cactus"), forKey: .Cactus)
    }
    
    subscript(_ type: ModelTypes) -> Model
    {
        return library[type]!
    }
    
}

class Model
{
    private var meshes: [Mesh] = []
    
    var getMeshes: [Mesh] {
        return self.meshes
    }
    
    var animations: [String: AnimationClip]!
    var currentTime: Float = 0
    
    init(_ modelName: String, ext: String = ".obj")
    {
        loadMesh(modelName, ext: ext)
    }
    
    private func loadMesh(_ modelName: String, ext: String)
    {
        guard let assetUrl = Bundle.main.url(forResource: modelName, withExtension: ext) else {
            fatalError("File doesn't exist \(modelName)")
        }
        let descriptor = Graphics.VertexDescriptors[.Basic]
        
        (descriptor.attributes[Int(Position.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (descriptor.attributes[Int(Colour.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributeColor
        (descriptor.attributes[Int(UV.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (descriptor.attributes[Int(Normal.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (descriptor.attributes[Int(Joints.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributeJointIndices
        (descriptor.attributes[Int(Weights.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributeJointWeights
        
        
        let bufferAllocater = MTKMeshBufferAllocator(device: Engine.Device)
        let asset: MDLAsset = MDLAsset(url: assetUrl, vertexDescriptor: descriptor, bufferAllocator: bufferAllocater)
        
        let assetAnimations = asset.animations.objects.compactMap {
            $0 as? MDLPackedJointAnimation
        }
        let animations = Dictionary(uniqueKeysWithValues: assetAnimations.map {
            ($0.name, AnimationComponent.load(animation: $0))
        })
        self.animations = animations
        for animation in animations {
            print("animation: ",animation.key)
        }
        
        
        asset.loadTextures()
        
        
        var mdlMeshes: [MDLMesh] = []
        do{
            mdlMeshes = try MTKMesh.newMeshes(asset: asset, device: Engine.Device).modelIOMeshes
        } catch let error as NSError
        {
            print("Didnt Work", error)
        }
        
        var mtkMeshes: [MTKMesh] = []
        
        for mdlMesh in mdlMeshes
        {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
            mdlMesh.vertexDescriptor = descriptor
            do {
                let mtkMesh = try MTKMesh(mesh: mdlMesh, device: Engine.Device)
                mtkMeshes.append(mtkMesh)
            } catch let error as NSError {
                print("HELLO",error)
            }
        }

        for i in 0...(mdlMeshes.count - 1) {
            let mesh = Mesh(mdlMesh: mdlMeshes[i], mtkMesh: mtkMeshes[i], startTime: asset.startTime, endTime: asset.endTime)
            addMesh(mesh)
        }
       
    }
    
    func addMesh(_ mesh: Mesh)
    {
        meshes.append(mesh)
    }
    
    func doUpdate()
    {
        currentTime += GameTime.DeltaTime
        for mesh in meshes {
            if let animationClip = animations.first?.value {
                mesh.skeleton?.updatePose(animationClip: animationClip, at: currentTime)
                mesh.transformComponent?.currentTransformation = matrix_identity_float4x4
                
            } else {
            mesh.transformComponent?.setCurrentTransform(at: currentTime)
            }
        }
    }

}

class Mesh {
    var mtkMesh: MTKMesh! = nil
    var mdlMesh: MDLMesh! = nil
    
    var vertexDataBuffer: [Vertex] = []
    var textureDataBuffer: [VertexColourData] = []
    
    var transformComponent: TransformComponent? = nil
    var skeleton: Skeleton? = nil
    
    var submeshIndexCounts: [Int] = []
    var submeshMaterials: [MDLMaterial] = []
    
    init(mdlMesh: MDLMesh, mtkMesh: MTKMesh, startTime: TimeInterval, endTime: TimeInterval)
    {
        self.mtkMesh = mtkMesh
        self.mdlMesh = mdlMesh
        
        let count = self.mtkMesh.vertexBuffers[0].buffer.length / MemoryLayout<SIMD3<Float>>.size
        let positionBuffer = self.mtkMesh.vertexBuffers[Int(Position.rawValue)].buffer
        let normalsBuffer = self.mtkMesh.vertexBuffers[Int(Normal.rawValue)].buffer
        let jointsBuffer = self.mtkMesh.vertexBuffers[Int(Joints.rawValue)].buffer
        let weightsBuffer = self.mtkMesh.vertexBuffers[Int(Weights.rawValue)].buffer
        let uvBuffer = self.mtkMesh.vertexBuffers[Int(UV.rawValue)].buffer
        let colourBuffer = self.mtkMesh.vertexBuffers[Int(Colour.rawValue)].buffer
        
        let normalsPtr = normalsBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: count)
        let positionPtr = positionBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: count)
        let jointsPtr = jointsBuffer.contents().bindMemory(to: SIMD4<UInt16>.self, capacity: count)
        let weightsPtr = weightsBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: count)
        
        let uvPtr = uvBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: count)
        let colourPtr = colourBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: count)
        
        for (mdlIndex, submesh) in self.mtkMesh.submeshes.enumerated() {
            let indexBuffer = submesh.indexBuffer.buffer
            let offset = submesh.indexBuffer.offset
            let indexPtr = indexBuffer.contents().advanced(by: offset)
            var indices = indexPtr.bindMemory(to: uint.self, capacity: submesh.indexCount)
            
            let mdlSubmesh = mdlMesh.submeshes![mdlIndex] as! MDLSubmesh
            createTexture(mdlSubmesh.material!, index: mdlIndex)
            
            submeshIndexCounts.append(submesh.indexCount)
            
            for _ in 0..<submesh.indexCount {
                let index = Int(indices.pointee)
                vertexDataBuffer.append(Vertex(position: positionPtr[index],
                                            normal: normalsPtr[index],
                                            joints: jointsPtr[index],
                                            weights: weightsPtr[index]))
                textureDataBuffer.append(VertexColourData(uv: uvPtr[index],
                                                     colour: colourPtr[index]))
                indices = indices.advanced(by: 1)
                
            }
        }
        
        let skeleton = Skeleton(animationBindComponent:
                                    (mdlMesh.componentConforming(to: MDLComponent.self) as? MDLAnimationBindComponent))
        self.skeleton = skeleton
        
        if let mdlMeshTransform = mdlMesh.transform {
            transformComponent = TransformComponent(transform: mdlMeshTransform,
                                           object: mdlMesh,
                                           startTime: startTime,
                                           endTime: endTime)
        } else {
            transformComponent = nil
        }
    }
    
    private func texture(for semantic: MDLMaterialSemantic,in material: MDLMaterial?,textureOrigin: MTKTextureLoader.Origin) -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Engine.Device)
        guard let materialProperty = material?.property(with: semantic) else { return nil }
        guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return nil}
        let options: [MTKTextureLoader.Option : Any] = [
            MTKTextureLoader.Option.origin : textureOrigin as Any,
            MTKTextureLoader.Option.generateMipmaps : true,
            MTKTextureLoader.Option.textureStorageMode : NSNumber(value: MTLStorageMode.shared.rawValue)
        ]
        let tex = try? textureLoader.newTexture(texture: sourceTexture, options: options)
        
        return tex
    }
    
    private func createTexture(_ mdlMaterial: MDLMaterial, index: Int)
    {
        let submeshTexture = SubmeshTextures()

        submeshTexture.colour = texture(for: .baseColor, in: mdlMaterial, textureOrigin: .bottomLeft)
        submeshTexture.ao = texture(for: .ambientOcclusion, in: mdlMaterial, textureOrigin: .bottomLeft)
        submeshTexture.normal = texture(for: .objectSpaceNormal, in: mdlMaterial, textureOrigin: .bottomLeft)
        
        ModelLoader.textures.updateValue(submeshTexture,
                                                 forKey: mdlMaterial.name)
        submeshMaterials.append(mdlMaterial)
    }
    
}

