//
//  KernelUpdate.swift
//  Snakea
//
//  Created by Matthew  Eatough on 27/10/2022.
//

import MetalKit

protocol KernelUpdate
{
    func doUpdate(_ kernelEncoder: MTLComputeCommandEncoder)
}
