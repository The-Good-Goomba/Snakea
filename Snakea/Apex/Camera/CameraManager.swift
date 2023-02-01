//
//  CameraManage.swift
//  Snakea
//
//  Created by Matthew  Eatough on 26/10/2022.
//

import MetalKit

class CameraManager
{
    private var _cameras: [CameraTypes: Camera] = [:]
    
    public var currentCamera: Camera!
    
    internal func update()
    {
        for camera in _cameras.values
        {
            camera.update()
        }
    }
    
    
    func addCamera(_ cam: Camera)
    {
        _cameras.updateValue(cam, forKey: cam.cameraType)
    }
    
    func setCamera(_ type: CameraTypes)
    {
        self.currentCamera = _cameras[type]
    }
    
}
