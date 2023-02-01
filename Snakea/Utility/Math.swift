import MetalKit

public var X_AXIS: SIMD3<Float>{
    return SIMD3<Float>(1,0,0)
}

public var Y_AXIS: SIMD3<Float>{
    return SIMD3<Float>(0,1,0)
}

public var Z_AXIS: SIMD3<Float>{
    return SIMD3<Float>(0,0,1)
}

extension Float {
    
    var toRadians: Float{
        return (self / 180.0) * Float.pi
    }
    
    var toDegrees: Float{
        return self * (180.0 / Float.pi)
    }
    
    static var randomZeroToOne: Float{
        return Float(arc4random()) / Float(UINT32_MAX)
    }
    
}

extension matrix_float4x4 {
    
    init(translation: SIMD3<Float>) {
      let matrix = float4x4(
        [            1,             0,             0, 0],
        [            0,             1,             0, 0],
        [            0,             0,             1, 0],
        [translation.x, translation.y, translation.z, 1]
      )
      self = matrix
    }
    
    init(scaling: SIMD3<Float>) {
      let matrix = float4x4(
        [scaling.x,         0,         0, 0],
        [        0, scaling.y,         0, 0],
        [        0,         0, scaling.z, 0],
        [        0,         0,         0, 1]
      )
      self = matrix
    }
    
    init(scaling: Float) {
      self = matrix_identity_float4x4
      columns.3.w = 1 / scaling
    }
    
    // MARK:- Rotate
    init(rotationX angle: Float) {
      let matrix = float4x4(
        [1,           0,          0, 0],
        [0,  cos(angle), sin(angle), 0],
        [0, -sin(angle), cos(angle), 0],
        [0,           0,          0, 1]
      )
      self = matrix
    }
    
    init(rotationY angle: Float) {
      let matrix = float4x4(
        [cos(angle), 0, -sin(angle), 0],
        [         0, 1,           0, 0],
        [sin(angle), 0,  cos(angle), 0],
        [         0, 0,           0, 1]
      )
      self = matrix
    }
    
    init(rotationZ angle: Float) {
      let matrix = float4x4(
        [ cos(angle), sin(angle), 0, 0],
        [-sin(angle), cos(angle), 0, 0],
        [          0,          0, 1, 0],
        [          0,          0, 0, 1]
      )
      self = matrix
    }
    
    init(rotation angle: SIMD3<Float>) {
      let rotationX = float4x4(rotationX: angle.x)
      let rotationY = float4x4(rotationY: angle.y)
      let rotationZ = float4x4(rotationZ: angle.z)
      self = rotationX * rotationY * rotationZ
    }
    
    init(rotationYXZ angle: SIMD3<Float>) {
      let rotationX = float4x4(rotationX: angle.x)
      let rotationY = float4x4(rotationY: angle.y)
      let rotationZ = float4x4(rotationZ: angle.z)
      self = rotationY * rotationX * rotationZ
    }
    
    static func identity() -> float4x4
    {
        return matrix_identity_float4x4
    }
    
    var upperLeft: float3x3 {
        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz
      return float3x3(columns: (x, y, z))
    }
    
    //https://gamedev.stackexchange.com/questions/120338/what-does-a-perspective-projection-matrix-look-like-in-opengl
    static func perspective(degreesFov: Float, aspectRatio: Float, near: Float, far: Float)->matrix_float4x4{
        let fov = degreesFov.toRadians
        
        let t: Float = tan(fov / 2)
        
        let x: Float = 1 / (aspectRatio * t)
        let y: Float = 1 / t
        let z: Float = -((far + near) / (far - near))
        let w: Float = -((2 * far * near) / (far - near))
        
        var result = matrix_identity_float4x4
        result.columns = (
            SIMD4<Float>(x,  0,  0,   0),
            SIMD4<Float>(0,  y,  0,   0),
            SIMD4<Float>(0,  0,  z,  -1),
            SIMD4<Float>(0,  0,  w,   0)
        )
        return result
    }

}

typealias float4 = SIMD4<Float>

// MARK:- float4
extension  float4 {
  var xyz: SIMD3<Float> {
    get {
        SIMD3<Float>(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }
  
  // convert from double4
  init(_ d: SIMD4<Double>) {
    self.init()
    self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
  }
}


