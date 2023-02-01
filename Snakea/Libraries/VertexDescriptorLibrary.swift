import MetalKit

enum VertexDescriptorTypes {
    case Basic
}

class VertexDescriptorLibrary {
    private var library: [VertexDescriptorTypes: VertexDescriptor] = [:]
    
    init()
    {
        library.updateValue(BasicVertexDescriptor(), forKey: .Basic)
    }
    
    subscript(_ type: VertexDescriptorTypes)-> MDLVertexDescriptor
    {
        return library[type]!.vertexDescriptor
    }
}

protocol VertexDescriptor {
    var name: String { get }
    var vertexDescriptor: MDLVertexDescriptor! { get }
}

public struct BasicVertexDescriptor : VertexDescriptor {
    var name: String = "Basic Vertex Descriptor"
    var vertexDescriptor: MDLVertexDescriptor!
    
    init()
    {
        vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[Int(Position.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                 format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: SIMD3<Float>.stride)
        vertexDescriptor.attributes[Int(Normal.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                               format: .float3, offset: 0,
                                                                               bufferIndex: 1)
        vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: SIMD3<Float>.stride)
        vertexDescriptor.attributes[Int(Joints.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeJointIndices,
                                                                               format: .uShort4, offset: 0,
                                                                               bufferIndex: 2)
        vertexDescriptor.layouts[2] = MDLVertexBufferLayout(stride: MemoryLayout<SIMD4<UInt16>>.stride)
        vertexDescriptor.attributes[Int(Weights.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeJointWeights,
                                                                               format: .float4, offset: 0,
                                                                               bufferIndex: 3)
        vertexDescriptor.layouts[3] = MDLVertexBufferLayout(stride: SIMD4<Float>.stride)
        vertexDescriptor.attributes[Int(UV.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                               format: .float2, offset: 0,
                                                                               bufferIndex: 4)
        vertexDescriptor.layouts[4] = MDLVertexBufferLayout(stride: SIMD2<Float>.stride)
        vertexDescriptor.attributes[Int(Colour.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeColor,
                                                                               format: .float4, offset: 0,
                                                                               bufferIndex: 5)
        vertexDescriptor.layouts[5] = MDLVertexBufferLayout(stride: SIMD4<Float>.stride)
    }
    
}
