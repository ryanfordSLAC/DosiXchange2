//
//  AudioPlayer.swift
//  LocationApp
//
//  Created by Lakatos Attila on 2023. 06. 15..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import AVFAudio
class AudioPlayer {
    
    var queue: [Audio]
    
    let lock = NSConditionLock(condition: 1)
    
    var buzzSound: AVAudioPlayer?
    var beepSound: AVAudioPlayer?
    
    init(){
        
        queue = []
        
        guard let buzzPath = Bundle.main.path(forResource: "beep-5", ofType: "wav") else {
            print("URL Not Found")
            return
        }
        let buzzUrl = URL(fileURLWithPath: buzzPath)
        do {
            buzzSound = try AVAudioPlayer(contentsOf: buzzUrl)
        }
        catch {
            print(error.localizedDescription)
        }
       
        guard let beepPath = Bundle.main.path(forResource: "scannerbeep", ofType: "mp3") else {
            print("URL Not Found")
            return
        }
        let beepUrl = URL(fileURLWithPath: beepPath)
        do {
            beepSound = try AVAudioPlayer(contentsOf: beepUrl)
        }
        catch {
            print(error.localizedDescription)
        }
        
        doWork()
        
    }
    
    //"Buzz!"
    func beepFail() {
        play(type: .buzz)
    }
    
    //"Beep!"
    func beep() {
        play(type: .beep)
    }
    
    private func play(type: Audio){
        lock.lock(whenCondition: 1)
        queue.append(type)
        lock.unlock(withCondition: 2)
    }
    
    private func doWork(){
        DispatchQueue.global(qos: .background).async {
            while(true){
                self.lock.lock(whenCondition: 2)
                if let last = self.queue.popLast(){
                    if( last == .beep ){
                        self.beepSound?.play()
                    } else if ( last == .buzz) {
                        self.buzzSound?.play()
                    }
                    sleep(1)
                }
                self.lock.unlock(withCondition: 1)
            }
        }
    }
}

enum Audio {
    case beep
    case buzz
}
