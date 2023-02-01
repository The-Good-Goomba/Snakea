//
//  GameObject.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit
import MetalPerformanceShaders

class GameObject: Apex
{
    private var _modelConstants = ModelConstants()
    var modelConstants: ModelConstants { return _modelConstants }
    
    private var _material: Material? = nil
    
    internal var _model: Model!
    var getModel: Model { return self._model }
    
    var _accelerationStructure: MPSTriangleAccelerationStructure!
    
    var normalBuffer: MTLBuffer!
    var staticVertexBuffer: MTLBuffer!
    var modifiedVertexBuffer: MTLBuffer!
    var vertexColourDataBuffer: MTLBuffer!
    var submeshBuffer: MTLBuffer!
    
    var jointMatrices: [float4x4] = []
    var vertexCount: Int!
    
    var shaderMesh: ShaderMesh = ShaderMesh()
    
    init(name: String, type: ModelTypes)
    {
        super.init(name)
        self._model = ModelLoader.Models[type]
        _modelConstants.useBones = self._model.animations.count != 0 ? 1 : 0
        self._modelConstants.modelMatrix = self.modelMatrix
        self._modelConstants.normalMatrix = _modelConstants.modelMatrix.upperLeft
        createContent()
    }
    
    override func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil) {
        self._modelConstants.modelMatrix = self.modelMatrix
        self._modelConstants.normalMatrix = _modelConstants.modelMatrix.upperLeft
        self._model.doUpdate()
        super.update(kernelEncoder)
    }
    
    func modifyVertices(kernelEncoder: MTLComputeCommandEncoder, _ threadsPerThreadGroup: MTLSize)
    {
        let threadsPerGrid = MTLSize(width: vertexCount, height: 1, depth: 1)
        
        kernelEncoder.setBuffer(staticVertexBuffer, offset: 0, index: 0)
        kernelEncoder.setBuffer(modifiedVertexBuffer, offset: 0, index: 1)
        kernelEncoder.setBuffer(normalBuffer, offset: 0, index: 2)
        kernelEncoder.setBytes(&jointMatrices, length: float4x4.stride(jointMatrices.count), index: 3)
        kernelEncoder.setBytes(&_modelConstants, length: ModelConstants.stride, index: 4)
        
        kernelEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    }
    
    func createContent()
    {
        var vertexColourData: [VertexColourData] = []
        var vertices: [Vertex] = []
        
        for mesh in getModel.getMeshes
        {
            vertices += mesh.vertexDataBuffer
            vertexColourData += mesh.textureDataBuffer
            if (mesh.skeleton != nil) {
                self.jointMatrices += mesh.skeleton!.jointMatrixPalette
            }
            
        }
        
        if (jointMatrices.count == 0) { jointMatrices.append(.identity()) }
        
        self.vertexCount = vertices.count
        self.normalBuffer = Engine.Device.makeBuffer(length: SIMD3<Float>.stride(vertexCount))
        normalBuffer.label = name + " Normal Buffer"
        self.modifiedVertexBuffer = Engine.Device.makeBuffer(length: SIMD3<Float>.stride(vertexCount))
        modifiedVertexBuffer.label = name + " Modified Vertex Buffer"
        self.staticVertexBuffer =  Engine.Device.makeBuffer(bytes: &vertices, length: Vertex.stride(vertexCount))
        staticVertexBuffer.label = name + " Static Vertex Buffer"
        self.vertexColourDataBuffer =  Engine.Device.makeBuffer(bytes: &vertexColourData, length: VertexColourData.stride(vertexCount))
        vertexColourDataBuffer.label = name + " Vertex Colour Data Buffer"
    }

    func rebuildAccelerationStructure()
    {
        self._accelerationStructure.rebuild()
    }
}

extension GameObject {
    public func useMaterial(_ material: Material)
    {
        self._material = material
    }
}
