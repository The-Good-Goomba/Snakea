//
//  Animation.swift
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

import MetalKit

struct Keyframe {
  var time: Float = 0
    var value: SIMD3<Float> = [0, 0, 0]
}

struct KeyQuaternion {
  var time: Float = 0
  var value = simd_quatf()
}

struct Animation {
  var translations: [Keyframe] = []
  var rotations: [KeyQuaternion] = []
  var repeatAnimation = true
  
  func getTranslation(at time: Float) -> SIMD3<Float>? {
    guard let lastKeyframe = translations.last else {
      return nil
    }
    var currentTime = time
    if let first = translations.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)
    let keyFramePairs = translations.indices.dropFirst().map {
      (previous: translations[$0 - 1], next: translations[$0])
    }
    guard let (previousKey, nextKey) = ( keyFramePairs.first {
      currentTime < $0.next.time
    } )
      else { return nil }
    let interpolant = (currentTime - previousKey.time) /
      (nextKey.time - previousKey.time)
    return simd_mix(previousKey.value,
                    nextKey.value,
                    SIMD3<Float>(repeating: interpolant))
  }
  
  func getRotation(at time: Float) -> simd_quatf? {
    guard let lastKeyframe = rotations.last else {
      return nil
    }
    var currentTime = time
    if let first = rotations.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation
    {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)
    let keyFramePairs = rotations.indices.dropFirst().map {
      (previous: rotations[$0 - 1], next: rotations[$0])
    }
    guard let (previousKey, nextKey) = ( keyFramePairs.first {
      currentTime < $0.next.time
    } )
      else {return nil}
    let interpolant = (currentTime - previousKey.time) /
      (nextKey.time - previousKey.time)
    return simd_slerp(previousKey.value, nextKey.value,
                      interpolant)
  }
}

