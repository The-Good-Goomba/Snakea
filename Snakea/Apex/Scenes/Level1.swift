//
//  Level1.swift
//  Snakea
//
//  Created by Matthew  Eatough on 27/10/2022.
//

import MetalKit

class Level1: Scene
{
    var planet: GameObject!
    var cactus: GameObject!
    var cam: Camera!
    
    
    override func buildScene() {
        planet = GameObject(name: "Level 1 Planet", type: .Level1Mesh)
        cactus = GameObject(name: "Cactus", type: .Cactus)
        cam = StaticCamera()
        
        addCamera(cam)
        addChild(planet)
        addChild(cactus)
    }
    
    override func doUpdate() {
        let dx = Mouse.GetDX()
        let dy = Mouse.GetDY()
        
        if (Mouse.IsMouseButtonPressed(button: .left))
        {
            planet.rotateY(y: dx * 0.002)
            planet.rotateX(x: dy * -0.002)
        }
        super.doUpdate()
    }
    
}
