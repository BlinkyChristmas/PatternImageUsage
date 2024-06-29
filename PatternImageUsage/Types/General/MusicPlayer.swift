// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AVFoundation

class MusicPlayer : NSObject {
    static let framePeriod = 0.037
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var values = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "isLoaded") {
            values.insert("duration")
        }
        else if key == "durationString" {
            values.insert("duration")
        }
        else if key == "playButtonTitle" {
            values.insert("isPlaying")
        }
        return values
    }

    var player = AVPlayer()
    var readyObserver: NSKeyValueObservation?
    var rateObserver: NSKeyValueObservation?
    var timeChangeCallback:((Double)->Void)?
    var timeObserver: Any? {
        willSet {
            guard timeObserver != nil else { return }
            player.removeTimeObserver(timeObserver!)
        }
    }
    var endObserver: Any? {
        willSet {
            guard endObserver != nil else { return }
            player.removeTimeObserver(endObserver!)
        }
    }

    @objc dynamic var volume : Float {
        get {
            player.volume
        }
        set {
            player.volume = newValue
        }
    }
    @objc dynamic var isMuted: Bool {
        get {
            player.isMuted
        }
        set {
            player.isMuted = newValue
        }
    }
    @objc dynamic var rate : Float {
        get{
            return player.defaultRate
        }
        set {
            player.defaultRate = newValue
        }
    }
    
    @objc dynamic var duration: Double {
        guard let item = player.currentItem else {
            return 0.0
        }
        let value = CMTimeGetSeconds(item.duration)
        if (value.isNaN) {
            return 0.0
        }
        return value
    }
    @objc dynamic var durationString:String{
        get {
            return String(format:"%.3f",self.duration)
        }
    }
    @objc dynamic var currentTime :Double {
        get {
            guard player.currentTime().isNumeric else {
                return 0
            }
            return player.currentTime().seconds
        }
        set {
            self.setCurrentTime(seconds: newValue)
        }

    }
    @objc dynamic var isLoaded : Bool {
        return self.duration > 0.0
    }
    @objc dynamic var playButtonTitle:String {
        return isPlaying ? "Stop" : "Play"
    }
    @IBAction func playMusic(_ sender:Any?) {
        if isPlaying {
            self.stop()
        }
        else if currentTime != self.duration {
            self.play()
        }
    }
    @objc dynamic var isPlaying : Bool {
        return player.rate > 0.0
    }
    
    @objc dynamic var musicTitle = ""
    
    deinit {
        timeObserver = nil
        endObserver = nil
        
    }
    
    func setCurrentTime(seconds:Double) {
        let time = CMTimeMake(value: Int64(seconds * 1000.0),timescale: 1000)
        self.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func play() {
        guard currentTime < duration else { return }
        player.play()
    }
    func stop() {
        player.pause()
    }
    
    
    func loadMusic(url:URL?) {
        player.pause()
        timeObserver = nil
        endObserver = nil
        if (rateObserver == nil) {
            self.rateObserver = player.observe(\.rate, changeHandler: { _,_ in
                self.willChangeValue(forKey: "isPlaying")
                self.didChangeValue(forKey: "isPlaying")
            })
        }
        if (readyObserver != nil) {
            readyObserver?.invalidate()
            readyObserver = nil
        }
        guard let url = url else {
            musicTitle = ""
            player.replaceCurrentItem(with: nil)
            return
        }

        musicTitle = url.deletingPathExtension().lastPathComponent
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        let item = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: [.duration,.isPlayable])
        item.audioTimePitchAlgorithm = .spectral
        self.willChangeValue(forKey: "duration")
        readyObserver = item.observe(\.status, options: [.new]) { object, value in
            if (item.status == .readyToPlay) {
                self.didChangeValue(forKey: "duration")
                self.currentTime = 0.0
                self.rate = 1.0
                let time =  CMTimeMake(value: Int64(MusicPlayer.framePeriod * 1000.0),timescale: 1000)
                
                self.timeObserver = self.player.addPeriodicTimeObserver(forInterval:time , queue: DispatchQueue.main, using: { cmtime in
                    self.willChangeValue(forKey: "currentTime")
                    self.didChangeValue(forKey: "currentTime")
                    guard self.timeChangeCallback != nil else { return }
                    self.timeChangeCallback!(self.currentTime)
                })
                
                self.endObserver = self.player.addBoundaryTimeObserver(forTimes: [NSValue(time:CMTimeMake(value: Int64(self.duration * 1000.0), timescale: 1000))], queue: DispatchQueue.main) {
                    self.willChangeValue(forKey: "isPlaying")
                    self.didChangeValue(forKey: "isPlaying")
                }
            }
            else {
                //Swift.print("Error loading assest: \(item.error?.localizedDescription ?? "unknown")")
            }
        }
        player.replaceCurrentItem(with: item)

   }

}
