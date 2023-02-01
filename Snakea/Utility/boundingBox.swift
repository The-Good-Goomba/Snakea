import MetalKit

extension MDLAxisAlignedBoundingBox
{

    
    var width: Float { return maxBounds.x - minBounds.x }
    var height: Float { return maxBounds.y - minBounds.y }
    var depth: Float { return maxBounds.z - minBounds.z }
    
    func scaleWidthTo(_ wide: Float) -> Float { return wide / width }
    func scaleHeightTo(_ high: Float) -> Float { return high / height }
    func scaleDepthTo(_ deep: Float) -> Float { return deep / depth }
    
    func getScaledBounds(scale: SIMD3<Float>) -> MDLAxisAlignedBoundingBox
    {
        var box = self
        box.minBounds = scale * box.minBounds 
        box.maxBounds = scale * box.maxBounds 
        return box
    }
    
}
