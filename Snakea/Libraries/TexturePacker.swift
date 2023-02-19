//
//  TexturePacker.swift
//  Snakea
//
//  Created by Matthew  Eatough on 20/12/2022.
//


class TexturePacker
{
    var root: Node!
    
    func createAtlas(sizes: [SIMD2<Int>], size: SIMD2<Int>) -> [SIMD2<Int>]?
    {
        root = Node()
        root.rect.right = size.x - 1
        root.rect.bottom = size.y - 1
        
        var positions: [SIMD2<Int>] = []
        
        var ok: Bool = true
        for imgSize in sizes
        {
            let rect = insert(w: imgSize.x, h: imgSize.y, ok: &ok)
            if (!ok) {
                print("Unable to fit size \(size)")
                return nil
            }
            positions.append(SIMD2<Int>(rect!.x, rect!.y))
        }
        
        return positions
        
    }
    
    func insertRect(node: inout Node, w: Int, h: Int, rect: inout Rectangle?) -> Bool
    {
        if (node.child.indices.contains(0))
        {
            assert(node.child.indices.contains(1))
            if (insertRect(node: &node.child[0], w: w, h: h, rect: &rect))
            {
                return true
            }
            return insertRect(node: &node.child[1], w: w, h: h, rect: &rect)
        }
        if (node.taken) { return false }
        
        if ( node.rect.width < w || node.rect.height < h ) { return false }
        
        if ( node.rect.width == w && node.rect.height == h) {
            node.taken = true
            rect = node.rect
            return true
        }
        
        node.child.insert(Node(), at: 0)
        node.child.insert(Node(), at: 1)
        
        let dw: Int = node.rect.width - w
        let dy: Int = node.rect.height - h
        assert(dw >= 0 && dy >= 0)
        
        if ( dw > dy )
        {
            node.child[0].rect = Rectangle(x: node.rect.x, y: node.rect.y,
                                           right: node.rect.x + w - 1,
                                           bottom: node.rect.bottom)
            node.child[1].rect = Rectangle(x: node.rect.x + w, y: node.rect.y,
                                           right: node.rect.right,
                                           bottom: node.rect.bottom)
        } else {
            node.child[0].rect = Rectangle(x: node.rect.x, y: node.rect.y,
                                           right: node.rect.right,
                                           bottom: node.rect.y + h - 1)
            node.child[1].rect = Rectangle(x: node.rect.x, y: node.rect.y + h,
                                           right: node.rect.right,
                                           bottom: node.rect.bottom)
        }
        
        return insertRect(node: &node.child[0], w: w, h: h, rect: &rect)
        
    }
    
    func insert(w: Int, h: Int, ok: inout Bool) -> Rectangle?
    {
        var r: Rectangle?
        let inserted: Bool = insertRect(node: &root, w: w, h: h, rect: &r)
        if (ok)
        {
            ok = inserted
        }
        return r
    }
    
    
    struct Rectangle
    {
        var x: Int = 0
        var y: Int = 0
        var right: Int = 0
        var bottom: Int = 0
        
        var width: Int { return right - x + 1 }
        var height: Int { return bottom - y + 1 }
    }

    struct Node
    {
        var child: [Node] = []
        var rect: Rectangle = Rectangle()
        var imgID: TextureTypes?
        var taken: Bool = false
    }
    

}
