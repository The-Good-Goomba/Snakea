//
//  ModelLoader.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//


import MetalKit

class ModelLoader {
    private static var _modelLibrary: ModelLibrary!
    public static var Models: ModelLibrary { return _modelLibrary }
    
    private static var _textureLibrary: TextureLibrary!
    public static var textures: TextureLibrary { return _textureLibrary }
    
    private static var _texturePacker: TexturePacker!
    public static var texturePacker: TexturePacker { return _texturePacker}
    
    public static func Initialise()
    {
        self._texturePacker = TexturePacker()
        
        self._textureLibrary = TextureLibrary()
        
        self._modelLibrary = ModelLibrary()
    }
}

