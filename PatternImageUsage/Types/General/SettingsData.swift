// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SettingsData : NSObject {
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var results = super.keyPathsForValuesAffectingValue(forKey:  key)
        if key == "completeBundle" {
            results.insert("bundleFile")
            results.insert("homeDirectory")
        }
        return results
    }
    enum TrackingKeys: String, CaseIterable {
        case musicDirectory,homeDirectory
        case selectionColor,backgroundColor,borderColor,timeNowColor,infoFontColor,detailFontColor
        case rowSize,startingLayerCount,framePeriod,infoFontSize,detailFontSize
        case bundleFile,gridDefault
    }
    var isTracking = false
    var musicSecurityAccessed = false
    var homeSecurityAccessed = false
    var changes = Set<TrackingKeys>()
    
    
    @objc dynamic var musicDirectory:URL? {
        willSet{
            if musicSecurityAccessed {
                musicDirectory?.stopAccessingSecurityScopedResource()
                musicSecurityAccessed = false
            }
        }
        didSet{
            guard isTracking else  { return }
            changes.insert(.musicDirectory)
        }
    }
    @objc dynamic var homeDirectory:URL? {
        willSet{
            if homeSecurityAccessed {
                homeDirectory?.stopAccessingSecurityScopedResource()
                homeSecurityAccessed = false
            }

        }
        didSet{
            guard isTracking else  { return }
            changes.insert(.homeDirectory)
        }
    }
    
    @objc dynamic var selectionColor = BlinkyGlobals.selectionColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.selectionColor)
        }
    }
    @objc dynamic var backgroundColor = BlinkyGlobals.backgroundColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.backgroundColor)
        }
    }
    @objc dynamic var borderColor = BlinkyGlobals.borderColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.borderColor)
        }
    }
    @objc dynamic var timeNowColor = BlinkyGlobals.timeNowColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.timeNowColor)
        }
    }
    @objc dynamic var detailFontColor = BlinkyGlobals.detailFontColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.detailFontColor)
        }
    }
    @objc dynamic var infoFontColor = BlinkyGlobals.infoFontColor {
        didSet{
            guard isTracking else  { return }
            changes.insert(.infoFontColor)
        }
    }
    
    @objc dynamic var rowSize = BlinkyGlobals.rowSize {
        didSet{
            guard isTracking else  { return }
            changes.insert(.rowSize)
        }
    }
    @objc dynamic var startingLayerCount = BlinkyGlobals.startingLayerCount {
        didSet{
            guard isTracking else  { return }
            changes.insert(.startingLayerCount)
        }
    }
    
    @objc dynamic var framePeriod = BlinkyGlobals.framePeriod {
        didSet{
            guard isTracking else  { return }
            changes.insert(.framePeriod)
        }
    }
    @objc dynamic var infoFontSize = BlinkyGlobals.infoFontSize {
        didSet{
            guard isTracking else  { return }
            changes.insert(.infoFontSize)
        }

    }
    @objc dynamic var detailFontSize = BlinkyGlobals.detailFontSize {
        didSet{
            guard isTracking else  { return }
            changes.insert(.detailFontSize)
        }
    }
    
    @objc dynamic var bundleFile:String? {
        didSet{
            guard isTracking else  { return }
            changes.insert(.bundleFile)
        }

    }
    @objc dynamic var gridDefault:String? {
        didSet {
            guard isTracking else  { return }
            changes.insert(.gridDefault)

        }
    }
    
    func reset() {
        changes.removeAll()
    }
    
    func loadFromDefaults(keys:Set<TrackingKeys>) throws {
        let teamIdPrefix = Bundle.main.object(forInfoDictionaryKey: "TeamIdentifierPrefix") as! String
        let groupDefaultString = Bundle.main.object(forInfoDictionaryKey: "GroupDefaultString") as! String
        guard let groupDefaults = UserDefaults(suiteName: teamIdPrefix + "." + groupDefaultString) else {
            throw GeneralError(errorMessage: "Unable to obtain group default: \(teamIdPrefix + "." + groupDefaultString )")
        }
        for key in keys {
            switch key {
                
            case .musicDirectory:
                let data = groupDefaults.data(forKey: key.rawValue)
                if data != nil {
                    let (url,isStale) = data!.obtainSecurity()
                    if url != nil {
                        // Is the bookmark stale?  if so, I guess we save it back
                        if isStale {
                            groupDefaults.setValue(url?.securityData, forKey: key.rawValue)
                        }
                        // are we security scoped on the old one
                        if musicSecurityAccessed {
                            musicDirectory?.stopAccessingSecurityScopedResource()
                            musicSecurityAccessed = false
                        }
                        musicDirectory = url
                        if musicDirectory != nil {
                            musicSecurityAccessed = musicDirectory!.startAccessingSecurityScopedResource()
                        }
                    }
                }
            case .homeDirectory:
                let data = groupDefaults.data(forKey: key.rawValue)
                if data != nil {
                    let (url,isStale) = data!.obtainSecurity()
                    if url != nil {
                        // Is the bookmark stale?  if so, I guess we save it back
                        if isStale {
                            groupDefaults.setValue(url?.securityData, forKey: key.rawValue)
                        }
                        // are we security scoped on the old one
                        if homeSecurityAccessed {
                            homeDirectory?.stopAccessingSecurityScopedResource()
                            homeSecurityAccessed = false
                        }
                        homeDirectory = url
                        if homeDirectory != nil {
                            homeSecurityAccessed = homeDirectory!.startAccessingSecurityScopedResource()
                        }
                    }
                }
            case .selectionColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    selectionColor = NSColor.colorFrom(string: text!)
                }
            case .backgroundColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    backgroundColor = NSColor.colorFrom(string: text!)
                }
            case .borderColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    borderColor = NSColor.colorFrom(string: text!)
                }
            case .timeNowColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    timeNowColor = NSColor.colorFrom(string: text!)
                }
            case .infoFontColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    infoFontColor = NSColor.colorFrom(string: text!)
                }
            case .detailFontColor:
                let text = groupDefaults.string(forKey: key.rawValue)
                if text != nil {
                    detailFontColor = NSColor.colorFrom(string: text!)
                }
            case .rowSize:
                let value = groupDefaults.double(forKey: key.rawValue)
                if value != 0.0 {
                    rowSize = value
                }
            case .startingLayerCount:
                let value = groupDefaults.integer(forKey: key.rawValue)
                if value != 0 {
                    startingLayerCount = value
                }
            case .framePeriod:
                let value = groupDefaults.integer(forKey: key.rawValue)
                if value != 0 {
                    framePeriod = value
                }
            case .infoFontSize:
                let value = groupDefaults.double(forKey: key.rawValue)
                if value != 0.0 {
                    infoFontSize = value
                }
            case .detailFontSize:
                let value = groupDefaults.double(forKey: key.rawValue)
                if value != 0.0 {
                    detailFontSize = value
                }
            case .bundleFile:
                bundleFile = groupDefaults.string(forKey: key.rawValue)
            case .gridDefault:
                gridDefault = groupDefaults.string(forKey: key.rawValue)

            }
        }
    }
    func saveToDefaults(keys:Set<TrackingKeys>) throws {
        let teamIdPrefix = Bundle.main.object(forInfoDictionaryKey: "TeamIdentifierPrefix") as! String
        let groupDefaultString = Bundle.main.object(forInfoDictionaryKey: "GroupDefaultString") as! String
        guard let groupDefaults = UserDefaults(suiteName: teamIdPrefix + "." + groupDefaultString) else {
            throw GeneralError(errorMessage: "Unable to obtain group default: \(teamIdPrefix + "." + groupDefaultString )")
        }
        for key in keys {
            switch key {
                
            case .musicDirectory:
                groupDefaults.setValue(musicDirectory?.securityData, forKey: key.rawValue)
            case .homeDirectory:
                groupDefaults.setValue(homeDirectory?.securityData, forKey: key.rawValue)

            case .selectionColor:
                groupDefaults.setValue(selectionColor.stringValue, forKey: key.rawValue)
            case .backgroundColor:
                groupDefaults.setValue(backgroundColor.stringValue, forKey: key.rawValue)
            case .borderColor:
                groupDefaults.setValue(borderColor.stringValue, forKey: key.rawValue)
            case .timeNowColor:
                groupDefaults.setValue(timeNowColor.stringValue, forKey: key.rawValue)
            case .infoFontColor:
                groupDefaults.setValue(infoFontColor.stringValue, forKey: key.rawValue)
            case .detailFontColor:
                groupDefaults.setValue(detailFontColor.stringValue, forKey: key.rawValue)
            case .rowSize:
                groupDefaults.setValue(rowSize, forKey: key.rawValue)
            case .startingLayerCount:
                groupDefaults.setValue(startingLayerCount, forKey: key.rawValue)
            case .framePeriod:
                groupDefaults.setValue(framePeriod, forKey: key.rawValue)
            case .infoFontSize:
                groupDefaults.setValue(infoFontSize, forKey: key.rawValue)
            case .detailFontSize:
                groupDefaults.setValue(detailFontSize, forKey: key.rawValue)
            case .bundleFile:
                groupDefaults.setValue(bundleFile, forKey: key.rawValue)
            case .gridDefault:
                groupDefaults.setValue(gridDefault, forKey: key.rawValue)
            }
        }

    }
    func updateChangesFrom(settingsData:SettingsData) throws {
        for key in settingsData.changes {
            switch key {
                
            case .musicDirectory:
                self.musicDirectory = settingsData.musicDirectory  // We dont worry about security scope here, as it came from an OpenPanel, so all ready accessed
            case .homeDirectory:
                self.homeDirectory = settingsData.homeDirectory  // We dont worry about security scope here, as it came from an OpenPanel, so all ready accessed
            case .selectionColor:
                self.selectionColor = settingsData.selectionColor.copy() as! NSColor
            case .backgroundColor:
                self.backgroundColor = settingsData.backgroundColor.copy() as! NSColor
            case .borderColor:
                self.borderColor = settingsData.borderColor.copy() as! NSColor
            case .timeNowColor:
                self.timeNowColor = settingsData.timeNowColor.copy() as! NSColor
            case .infoFontColor:
                self.infoFontColor = settingsData.infoFontColor.copy() as! NSColor
            case .detailFontColor:
                self.detailFontColor = settingsData.detailFontColor.copy() as! NSColor
            case .rowSize:
                self.rowSize = settingsData.rowSize
            case .startingLayerCount:
                self.startingLayerCount = settingsData.startingLayerCount
            case .framePeriod:
                self.framePeriod = settingsData.framePeriod
            case .infoFontSize:
                self.infoFontSize = settingsData.infoFontSize
            case .detailFontSize:
                self.detailFontSize = settingsData.detailFontSize
            case .bundleFile:
                self.bundleFile  = settingsData.bundleFile
            case .gridDefault:
                self.gridDefault = settingsData.gridDefault
            }
        }
    }
    
    func partialCopy() -> SettingsData {
        let data = SettingsData()
        for key in TrackingKeys.allCases {
            switch key {
                
            case .musicDirectory:
                data.musicDirectory = musicDirectory
            case .homeDirectory:
                data.homeDirectory = homeDirectory
            case .selectionColor:
                data.selectionColor = selectionColor.copy() as! NSColor
            case .backgroundColor:
                data.backgroundColor = backgroundColor.copy() as! NSColor
            case .borderColor:
                data.borderColor = borderColor.copy() as! NSColor
            case .timeNowColor:
                data.timeNowColor = timeNowColor.copy() as! NSColor
            case .infoFontColor:
                data.infoFontColor = infoFontColor.copy() as! NSColor
            case .detailFontColor:
                data.detailFontColor = detailFontColor.copy() as! NSColor
            case .rowSize:
                data.rowSize = rowSize
            case .startingLayerCount:
                data.startingLayerCount = startingLayerCount
            case .framePeriod:
                data.framePeriod = framePeriod
            case .infoFontSize:
                data.infoFontSize = infoFontSize
            case .detailFontSize:
                data.detailFontSize = detailFontSize
            case .bundleFile:
                data.bundleFile = bundleFile
            case .gridDefault:
                data.gridDefault = gridDefault
            }
        }
        return data
    }
    
    var completeBundle:URL? {
        guard self.bundleFile != nil else { return nil }
        return bundleDirectory?.appending(component: self.bundleFile!)
    }
    override func awakeFromNib() {
        do {
            let keys = Set<TrackingKeys>(TrackingKeys.allCases)
            try loadFromDefaults(keys: keys)
        }
        catch {
            NSAlert(error: GeneralError(errorMessage: "Unable to initailize user defaults", failure: error.localizedDescription)).runModal()
        }
    }
}

extension SettingsData {
    @objc dynamic var bundleDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.bundleSubpath)
    }
    
    @objc dynamic var visualizationDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.visualizationSubpath)
    }
    
    @objc dynamic var sequenceDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.sequenceSubpath)
    }
    
    @objc dynamic var lightDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.lightSubpath)
    }
    
    @objc dynamic var configurationDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.configurationSubpath)
    }
    
    @objc dynamic var shuffleDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.shuffleSubpath)
    }
    
    @objc dynamic var patternDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.patternSubpath)
    }
    
    @objc dynamic var imageDirectory:URL? {
        homeDirectory?.appending(path: BlinkyGlobals.imageSubpath)
    }
    
    @objc dynamic var musicFiles:[String] {
        var contents = [String]()
        guard self.musicDirectory != nil else { return contents}
        let possible = try? FileManager.default.contentsOfDirectory(at: self.musicDirectory!, includingPropertiesForKeys: [.isRegularFileKey,.isHiddenKey,.isReadableKey])
        guard possible != nil else { return contents }
        for entry in possible! {
            if entry.isReqularFile && !entry.isHidden && entry.isReadable {
                if entry.pathExtension.lowercased() == "wav" {
                    contents.append(entry.deletingPathExtension().lastPathComponent)
                }
            }
        }
        return contents
    }
}
