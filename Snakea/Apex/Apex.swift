//
//  Apex.swift
//  Snakea
//
//  Created by Matthew  Eatough on 24/10/2022.
//

import MetalKit

class Apex
{
    private var _position: SIMD3<Float> = [0,0,0]
    private var _rotation: SIMD3<Float> = [0,0,0]
    private var _scale: SIMD3<Float> = [1,1,1]
    private var _quarternion: simd_quatf = simd_quatf()
    
    private var _name: String
    var name: String { return self._name }
    
    private var parentModelMatrix = matrix_identity_float4x4
    private var _modelMatrix = matrix_identity_float4x4
    
    var modelMatrix: float4x4 {
        return matrix_multiply(parentModelMatrix, _modelMatrix)
    }

    private var _children: [Apex] = []
    
    var children: [Apex] { return self._children }
    
    var toRender: Bool = true
    
    init(_ name: String)
    {
        self._name = name
    }
    
    func addChild(_ child: Apex)
    {
        self._children.append(child)
    }
    
    func removeChild(index: Int)
    {
        _children.remove(at: index)
    }
    
    func removeChild(child: Apex)
    {
        let index = _children.firstIndex{$0 === child}
        if index == nil { return }
        removeChild(index: index!)
    }
    
    func updateModelMatrix()
    {
        let translationMatrix = float4x4(translation: _position)
        let scaleMatrix = float4x4(scaling: _scale)
        let rotationMatrix = float4x4(_quarternion)
        self._modelMatrix = translationMatrix * rotationMatrix * scaleMatrix
    }
    
    func doUpdate() { }
    
    func update(_ kernelEncoder: MTLComputeCommandEncoder? = nil)
    {
        kernelEncoder?.pushDebugGroup("Computing " + self._name)
        
        doUpdate()
        
        if let updater = self as? KernelUpdate
        {
            updater.doUpdate(kernelEncoder!)
        }
        
        for child in _children
        {
            child.parentModelMatrix = self.modelMatrix
            child.update(kernelEncoder!)
        }
    
        kernelEncoder?.popDebugGroup()
    }
    
    func afterTranslation() { }
    func afterRotation() { }
    func afterScale() { }
}

extension Apex
{
    
//    Position
    func setPosition(_ pos: SIMD3<Float>)
    {
        self._position = pos
        updateModelMatrix()
        afterTranslation()
    }
    
    func setPosition(x: Float, y: Float, z: Float)
    {
        self.setPosition([x,y,z])
    }
    
    func setPositionX(_ x: Float) { setPosition(x: x, y: getPositionY(), z: getPositionZ() ) }
    func setPositionY(_ y: Float) { setPosition(x: getPositionX(), y: y, z: getPositionZ() ) }
    func setPositionZ(_ z: Float) { setPosition(x: getPositionX(), y: getPositionY() , z: z) }
    
    func move(_ amount: SIMD3<Float>)
    {
        setPosition(getPosition() + amount)
    }
    
    func moveX(x: Float) { move([x,0,0]) }
    func moveY(y: Float) { move([0,y,0]) }
    func moveZ(z: Float) { move([0,0,z]) }
    
    func getPosition() -> SIMD3<Float>{ return self._position }
    func getPositionX() -> Float { return self._position.x }
    func getPositionY() -> Float { return self._position.y }
    func getPositionZ() -> Float { return self._position.z }
    
    
//    Rotation
    func setRotation(_ rot: SIMD3<Float>)
    {
        self._rotation = rot
        
        let rotationMat = float4x4(rotation: _rotation)
        self._quarternion = simd_quatf(rotationMat)
        
        updateModelMatrix()
        afterRotation()
    }
    
    func setRotation(x: Float, y: Float, z: Float)
    {
        self.setRotation([x,y,z])
    }
    
    func setRotationX(_ x: Float) { setRotation(x: x, y: getRotationY(), z: getRotationZ() ) }
    func setRotationY(_ y: Float) { setRotation(x: getRotationX(), y: y, z: getRotationZ() ) }
    func setRotationZ(_ z: Float) { setRotation(x: getRotationX(), y: getRotationY() , z: z) }
    
    func rotate(_ amount: SIMD3<Float>)
    {
        setRotation(getRotation() + amount)
    }
    
    func rotateX(x: Float) { rotate([x,0,0]) }
    func rotateY(y: Float) { rotate([0,y,0]) }
    func rotateZ(z: Float) { rotate([0,0,z]) }
    
    func getRotation() -> SIMD3<Float>{ return self._rotation }
    func getRotationX() -> Float { return self._rotation.x }
    func getRotationY() -> Float { return self._rotation.y }
    func getRotationZ() -> Float { return self._rotation.z }
    
//    Scale
    func setScale(_ scale: SIMD3<Float>)
    {
        print(scale)
        self._scale = scale
        updateModelMatrix()
        afterScale()
    }
    
    func setScale(x: Float, y: Float, z: Float)
    {
        self.setScale([x,y,z])
    }
    
    func setScaleX(_ x: Float) { setScale(x: x, y: getScaleY(), z: getScaleZ() ) }
    func setScaleY(_ y: Float) { setScale(x: getScaleX(), y: y, z: getScaleZ() ) }
    func setScaleZ(_ z: Float) { setScale(x: getScaleX(), y: getScaleY() , z: z) }
    
    func scale(_ amount: SIMD3<Float>)
    {
        setScale(getScale() * amount)
    }
    
    func scaleX(x: Float) { scale([x,1,1]) }
    func scaleY(y: Float) { scale([1,y,1]) }
    func scaleZ(z: Float) { scale([1,1,z]) }
    
    func getScale() -> SIMD3<Float>{ return self._scale }
    func getScaleX() -> Float { return self._scale.x }
    func getScaleY() -> Float { return self._scale.y }
    func getScaleZ() -> Float { return self._scale.z }
    
    func setUniformScale(_ x:Float) { setScale([x,x,x]) }
    func uniformScale(_ x:Float) { scale([x,x,x]) }
    
}
