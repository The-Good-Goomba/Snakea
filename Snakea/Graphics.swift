//
//  Graphics.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import Foundation

class Graphics {

    private static var _vertexDescriptorLibrary: VertexDescriptorLibrary!
    public static var VertexDescriptors: VertexDescriptorLibrary{ return _vertexDescriptorLibrary }
    

    public static func Initialise()
    {
        self._vertexDescriptorLibrary = VertexDescriptorLibrary()
       
    }
}
