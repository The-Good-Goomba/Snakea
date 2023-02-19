//
//  Level1.swift
//  Snakea
//
//  Created by Matthew  Eatough on 27/10/2022.
//

import MetalKit

class Level1: Level
{
    var planet: AttractorObject!
    var cactus: Entity!
    var cam: Camera!
    
    
    override func buildScene() {
        planet = AttractorObject(name: "Level 1 Planet", type: .Level1Mesh)
        cactus = Entity(name: "Cactus", type: .Cactus)
        cam = Camera(.Static)
        
        addCamera(cam)
        addChild(planet)
        addChild(cactus)
        cactus.setUniformScale(0.3)
        
        cactus.setPosition(x: 0.0, y: 10.0, z: 0.0)
        
        light.position = SIMD3<Float>(40.0, 0.0, 40.0)
        light.colour = SIMD3<Float>(repeating: 10000)
        light.rotation.y = -.pi/2.0

    }
    
    override func doUpdate() {
        
        if (Mouse.IsMouseButtonPressed(button: .left))
        {
            cam.rotation.y +=  Mouse.DX * 0.002
        }
        if (Keyboard.IsKeyPressed(.a))
        {
            cam.position.x -= 0.5
        }
        if (Keyboard.IsKeyPressed(.d))
        {
            cam.position.x += 0.5
        }
        if (Keyboard.IsKeyPressed(.w))
        {
            cam.position.z -= 0.5
        }
        if (Keyboard.IsKeyPressed(.s))
        {
            cam.position.z += 0.5
        }
        
        super.doUpdate()
    }
    
}
