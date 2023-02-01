import simd
import MetalPerformanceShaders

protocol sizeable{ }
extension sizeable{
    static var size: Int{
        return MemoryLayout<Self>.size
    }
    
    static var stride: Int{
        return MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int)->Int{
        return MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int)->Int{
        return MemoryLayout<Self>.stride * count
    }
}

extension Float: sizeable { }
extension SIMD2<Float>: sizeable { }
extension SIMD3<Float>: sizeable { }
extension SIMD4<Float>: sizeable { }


extension matrix_float4x4: sizeable { }

extension SceneConstants: sizeable { }
extension ModelConstants: sizeable { }
extension Vertex: sizeable { }
extension Material: sizeable { }
extension UInt32: sizeable { }
extension RayData: sizeable { }
extension VertexColourData: sizeable { }
extension SubmeshInfo: sizeable { }
extension TextureData: sizeable { }
extension MTLPackedFloat3: sizeable { }


// Dont ask

func +(vec1: SIMD2<Int>, vec2: SIMD2<Int>) -> SIMD2<Int>
{
    return SIMD2<Int>(vec1.x + vec2.x,vec1.y + vec2.y)
}

