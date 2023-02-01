//
//  TextureLibrary.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit

enum TextureTypes {
    case None
    case Level1Colour
}

class TextureLibrary {
    private var library: [String: SubmeshTextures] = [:]
    
    func updateValue(_ value: SubmeshTextures,forKey key: String)
    {
        library.updateValue(value, forKey: key)
    }
    
    subscript(_ type: String) -> SubmeshTextures?
    {
        return library[type]
    }
    
    
    func packIncludedTextures(_ textureNames: [String], packer: TexturePacker) -> (MTLTexture, [Img])
    {
        var sizes: [SIMD2<Int>] = []
        var images: [Img] = []
        
        for texture in textureNames
        {
            if library[texture]?.colour != nil { sizes.append(SIMD2<Int>(library[texture]!.colour!.width,
                                                            library[texture]!.colour!.height))
                images.append(Img(name: texture, type: .baseColor,
                                  size: SIMD2<Float>(Float(sizes.last!.x), Float(sizes.last!.y))))
            }
            if library[texture]?.normal != nil { sizes.append(SIMD2<Int>(library[texture]!.normal!.width,
                                                            library[texture]!.normal!.height))
                images.append(Img(name: texture, type: .objectSpaceNormal,
                                  size: SIMD2<Float>(Float(sizes.last!.x), Float(sizes.last!.y))))
            }
            if library[texture]?.ao != nil { sizes.append(SIMD2<Int>(library[texture]!.ao!.width,
                                                            library[texture]!.ao!.height))
                images.append(Img(name: texture, type: .ambientOcclusion,
                                  size: SIMD2<Float>(Float(sizes.last!.x), Float(sizes.last!.y))))
            }
        }
        
        var positions: [SIMD2<Int>]!
        
        var size = 128
        
        repeat {
            size *= 2
            positions = packer.createAtlas(sizes: sizes, size: SIMD2<Int>(size,size))
        } while ( positions == nil )
     
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = size
        descriptor.height = size
        descriptor.pixelFormat = Preferences.colourPixelFormat
        let outTex: MTLTexture! = Engine.Device.makeTexture(descriptor: descriptor)
        
        if (outTex == nil)
        {
            fatalError("Texture Atlas didn't feel like being made")
        }
        
        let buffer = Engine.CommandQueue.makeCommandBuffer()
        let blitEncoder = buffer?.makeBlitCommandEncoder()
        
        for (index,position) in positions.enumerated()
        {
            blitEncoder?.copy(from: library[images[index].name]![images[index].type]!, sourceSlice: 0,
                              sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                              sourceSize: MTLSizeMake(Int(images[index].size.x), Int(images[index].size.y), 1),
                              to: outTex,
                              destinationSlice: 0, destinationLevel: 0,
                              destinationOrigin: MTLOrigin(x: position.x, y: position.y, z: 0))
        }
        
        blitEncoder?.endEncoding()
        buffer?.commit()
        
        for (index,position) in positions.enumerated()
        {
            images[index].pos = SIMD2<Float>(Float(position.x), Float(position.y))
        }
        
        return (outTex!, images)
    }
    
    struct Img
    {
        var name: String
        var type: MDLMaterialSemantic
        var size: SIMD2<Float> = [0,0]
        var pos: SIMD2<Float> = [0,0]
    }
    
    
}

class SubmeshTextures
{
    var colour: MTLTexture?
    var normal: MTLTexture?
    var ao: MTLTexture?
    
    subscript (type: MDLMaterialSemantic) -> MTLTexture?
    {
        switch (type)
        {
        case .baseColor:
            return colour
    
        case .objectSpaceNormal:
            return normal
        
        case .ambientOcclusion:
            return ao
        
        default:
            return colour
            
        }
    }
}

