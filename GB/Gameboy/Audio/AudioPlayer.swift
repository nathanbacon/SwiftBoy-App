//
//  AudioPlayer.swift
//  GB
//
//  Created by Nathan Gelman on 9/10/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation
import AVFoundation

struct AudioPlayer {
    let audioEngine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true)!
    let gbNode = AVAudioMixerNode()
    lazy var mixer = audioEngine.mainMixerNode
    lazy var buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(4096))!
    
    mutating func initializePlayer() {
        buffer.frameLength = 4096
        
        audioEngine.attach(gbNode)
        
        audioEngine.connect(gbNode, to: mixer, format: format)
    }
}
