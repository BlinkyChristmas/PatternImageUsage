// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

struct LightFile {
    static let headerSize = 54
    static let signature = Int32(0x5448474c)

    var frameCount = 0
    var frameLength = 0
    var dataOffset = 54
    var musicName = ""
    var framePeriod = 0.037
    var lightData = [ [UInt8]]()
    init(frameCount: Int = 0, frameLength: Int = 0,  musicName: String = "", framePeriod: Double = 0.037, lightData: [[UInt8]] = [ [UInt8]]()) {
        self.frameCount = frameCount
        self.frameLength = frameLength
        self.dataOffset = 54
        self.musicName = musicName
        self.framePeriod = framePeriod
        self.lightData = lightData
    }
}

extension LightFile {
    init(url:URL) throws {
        self.init()
        let data = try Data(contentsOf: url)
        guard data.count >= LightFile.headerSize else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid light file, insufficient size \(data.count) for header, expected \(LightFile.headerSize)"])
        }
        let signature = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Int32.self)}
        guard signature == LightFile.signature else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid light file, invalid signature \(String(format:"%x",signature)) expected: \(String(format:"%x",LightFile.signature))"])
        }
        let version = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self)}
        guard version == 0 else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid light file, invalid version \(version) expected: 0 "])
        }
        dataOffset = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Int32.self)})
        framePeriod = Double(data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: Int32.self)})/1000.0
        frameCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: Int32.self)})
        frameLength = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 20, as: Int32.self)})
        var temp = String(data: data[data.startIndex+24..<data.startIndex+54], encoding: .ascii)
        if temp != nil {
            temp = temp!.trimmingCharacters(in: .whitespacesAndNewlines)
            musicName = temp!
        }

        guard data.count >= frameCount * frameLength + LightFile.headerSize else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Corrupted light file, size \(data.count) is insufficent for stated framelength * framecount + headerSize: \(frameCount * frameLength + LightFile.headerSize)"])
        }
        for frame in 0..<frameCount {
            lightData.append([UInt8](Data(data[dataOffset+frame*frameLength..<dataOffset+(frame+1)*frameLength])))
        }
    }
    func saveTo(url:URL) throws {
        var data = Data(repeating: 0, count: LightFile.headerSize + self.frameCount * self.frameLength)
        data[0..<4] = Int32(LightFile.signature).data
        // we dont write the version since we all ready zeroed it
        data[8..<12] = Int32(54).data
        data[12..<16] = Int32(framePeriod * 1000.0).data
        data[16..<20] = Int32(lightData.count).data
        data[20..<24] = Int32(frameLength).data
        guard let temp = musicName.data(using: .ascii) else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Unable to convert musicName '\(musicName)' to data"])
        }
        let size = temp.count > 30 ? 30 : temp.count
        data[24..<24+size] = temp[0..<size]
        for (index,framedata) in lightData.enumerated() {
            data[54+index*frameLength..<54+(index+1)*frameLength] = Data(framedata)
        }
        try data.write(to: url)
    }
    
    func frameFor(frameNumber:Int) throws -> [UInt8] {
        guard frameNumber < frameCount else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Frame \(frameNumber) exceeds frame count: \(frameCount)"])
        }
        return lightData[frameNumber]
    }
    
    var count:Int {
        return lightData.count
    }
    var isEmpty:Bool {
        return lightData.isEmpty
    }
}
