// 

import Cocoa
import UniformTypeIdentifiers
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    @IBOutlet var settingsData:SettingsData!
    var bundleDictionary=[String:LightBundle]()
    var bundleObserver:NSKeyValueObservation?
    deinit {
        bundleObserver?.invalidate()
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        bundleObserver = settingsData.observe(\.bundleFile, changeHandler: { settings, _ in
            self.processBundles()
        })
        self.processBundles()

    }

    @IBAction func endWindow(_ sender: Any?) {
        self.window.close()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func processBundles() {
        guard let url = settingsData.completeBundle else {
            NSDocumentController.shared.presentError(GeneralError(errorMessage: "Unable to process bundles", failure: "Bundle file or Base Directory is not set"))
            return
        }
        do{
            bundleDictionary = try PatternImageUsage.processBundles(url: url)
        }
        catch{
            NSAlert(error:GeneralError(errorMessage: "Unable to process bundles", failure: error.localizedDescription)).beginSheetModal(for: self.window)
        }
    }

}

extension AppDelegate {
    @IBAction func listUsage(_ sender:Any?) {
        let panel = NSSavePanel()
        panel.prompt = "List used patterns/images in sequences into file"
        panel.allowedContentTypes = [UTType.text]
        panel.beginSheetModal(for: self.window) { response in
            guard response == .OK , panel.url != nil else { return }
            let sequences = self.allContentsMatching(fileExtension: "sequence", searchDirectory: self.settingsData.sequenceDirectory!)
            if sequences.isEmpty {
                return
            }
            do {
                var outstring = String()
                for sequence in sequences {
                    outstring += "Sequence: " + sequence.path() + "\n"
                    let items = try self.patternsImagesInSequence(url: sequence, bundleDictionary: self.bundleDictionary, baseDirectory: self.settingsData.homeDirectory!)
                    for (name,seqItem) in items {
                        outstring += "\tItem \(name)" + "\n"
                        for entry in seqItem.keys {
                            outstring += "\t\tPattern:" + entry.path() + "\n"
                            for pattern in seqItem[entry]! {
                                outstring += "\t\t\tImage: " + pattern.path() + "\n"
                            }
                        }
                    }
                    
                }
                try outstring.write(to: panel.url!, atomically: true, encoding: .utf8)
            }
            catch {
                NSAlert(error: GeneralError(errorMessage: "Error writing data to: \(panel.url!.path())",failure: error.localizedDescription)).beginSheetModal(for: self.window)
            }
           
        }
    }

    @IBAction func listUnused(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.prompt = "List unused patterns/images into file"
        panel.allowedContentTypes = [UTType.text]
        panel.beginSheetModal(for: self.window) { response in
            guard response == .OK , panel.url != nil else { return }
            // get all patterns and images
            do {
                let availablePatterns = self.allContentsMatching(fileExtension: "xml", searchDirectory: self.settingsData.patternDirectory!)
                let availableImages = self.allContentsMatching(fileExtension: "tiff", searchDirectory: self.settingsData.imageDirectory!)
                
                // Now get all used images and patterns
                let (usedPatterns,usedImages) = try self.allUsedPatternImages(sequences: self.settingsData.sequenceDirectory!, bundleDictionary: self.bundleDictionary, homeDirectory: self.settingsData.homeDirectory!)
                var unusedPattern = Set<URL>()
                var unusedImage = Set<URL>()
                for entry in availablePatterns {
                    if !usedPatterns.contains(entry) {
                        unusedPattern.insert(entry)
                    }
                }
                for entry in availableImages {
                    if !usedImages.contains(entry) {
                        unusedImage.insert(entry)
                    }
                }

                // Now we get to write them to a file!
                var outstring = "Patterns" + "\n"
                for entry in unusedPattern {
                    outstring += "\t" + entry.path() + "\n"
                }
                
                outstring += "\n" + "Images" + "\n"
                for entry in unusedImage {
                    outstring += "\t" + entry.path() + "\n"
                }
                try outstring.write(to: panel.url!, atomically: true, encoding: .utf8)
            }
            catch {
                NSAlert(error: GeneralError(errorMessage: "Error listing data to: \(panel.url!.path())", failure: error.localizedDescription)).beginSheetModal(for: self.window)
            }
        }
    }
    
    func allContentsMatching(fileExtension:String,searchDirectory:URL) -> Set<URL> {
        var rvalue = Set<URL>()
        guard let dirEnumerator = FileManager.default.enumerator(at: searchDirectory, includingPropertiesForKeys: [.isRegularFileKey,.isDirectoryKey,.isHiddenKey,.isReadableKey], options: [.skipsHiddenFiles]) else { return rvalue }
        for case let fileURL as URL in dirEnumerator {
            if fileURL.isReqularFile {
                
                if fileURL.pathExtension == fileExtension{
                    rvalue.insert(fileURL)
                }
            }
        }
        return rvalue

    }
    func allUsedPatternImages(sequences:URL,bundleDictionary:[String:LightBundle],homeDirectory:URL) throws -> (Set<URL>,Set<URL>) {
        let sequences = allContentsMatching(fileExtension: "sequence", searchDirectory:  settingsData.sequenceDirectory!)
        var patterns = Set<URL>()
        var images = Set<URL>()
        for entry in sequences {
            let (usedPattern,usedImage) = try imagesPatternsUsedInSequence(url: entry, bundleDictionary: bundleDictionary, baseDirectory: homeDirectory)
            for pat in usedPattern {
                patterns.insert(pat)
            }
            for img in usedImage {
                images.insert(img)
            }
        }
        return (patterns,images)
    }
    
    func imagesInPattern(pattern:URL, imageDirectory:URL) throws -> Set<URL>{
        var rvalue = Set<URL>()
        do {
            let doc = try XMLDocument(contentsOf: pattern)
            guard let root = doc.rootElement() else { return rvalue}
            for child in root.elements(forName: "transition") {
                if child.children != nil {
                    for item in child.children! {
                        let element = item as? XMLElement
                        if element != nil {
                            var node = element?.attribute(forName: "startImage")
                            if node?.stringValue != nil {
                                rvalue.insert(imageDirectory.appending(path: node!.stringValue!))
                            }
                            node = element?.attribute(forName: "endImage")
                            if node?.stringValue != nil {
                                rvalue.insert(imageDirectory.appending(path: node!.stringValue!))
                            }
                            node = element?.attribute(forName: "maskImage")
                            if node?.stringValue != nil {
                                rvalue.insert(imageDirectory.appending(path: node!.stringValue!))
                            }
                        }
                    }
                }
            }
            
        }
        catch {
            throw GeneralError(errorMessage: "Unable to open pattern: \(pattern.path())", failure: error.localizedDescription)
        }
        return rvalue
    }
    func patternsForSequenceItem(sequenceItem:SeqItem, patternDirectory:URL)  -> Set<URL> {
        var rvalue = Set<URL>()
        for effect in sequenceItem.effects {
            rvalue.insert(patternDirectory.appending(path: effect.pattern!))
        }
        return rvalue
    }
    func patternsImagesInSequence(url:URL, bundleDictionary:[String:LightBundle], baseDirectory:URL) throws -> [(String,[URL:[URL]])]{
        let imageBase = baseDirectory.appending(path: BlinkyGlobals.imageSubpath)
        let patternBase = baseDirectory.appending(path: BlinkyGlobals.patternSubpath)
        do {
            let xmldoc = try XMLDocument(contentsOf: url)
            var sequenceUse = [(String,[URL:[URL]])]()
            guard let root = xmldoc.rootElement() else { return sequenceUse }
            for child in root.elements(forName: "sequenceItem") {
                let sequencItem = try SeqItem(element: child)
                var patternImage = [URL:[URL]]()
                guard let bundleType = bundleDictionary[sequencItem.bundleType!] else {
                    throw GeneralError(errorMessage: "Unable to find bundle type: \(sequencItem.bundleType!) for sequence item: \(sequencItem.name ?? "")")
                }
                let imageDirectory = imageBase.appending(path: bundleType.bundleImageDirectory)
                let patternDirectory = patternBase.appending(path: bundleType.bundlePatternDirectory)
                let patterns = patternsForSequenceItem(sequenceItem: sequencItem, patternDirectory: patternDirectory)
                for pattern in patterns {
                    let images = try imagesInPattern(pattern: pattern, imageDirectory: imageDirectory)
                    patternImage[pattern] = Array(images)
                }
                sequenceUse.append((sequencItem.name!,patternImage))
            }
            return sequenceUse
         }
        catch{
            throw GeneralError(errorMessage: "Error processing: \(url.path())", failure: error.localizedDescription)
        }
    }
    func imagesPatternsUsedInSequence(url:URL, bundleDictionary:[String:LightBundle], baseDirectory:URL) throws -> (Set<URL>,Set<URL>) {
        let alldata = try patternsImagesInSequence(url: url, bundleDictionary: bundleDictionary, baseDirectory: baseDirectory)
        var patterns = Set<URL>()
        var images = Set<URL>()
        for (name,patternData) in alldata {
            for patternUrls in patternData.keys {
                patterns.insert(patternUrls)
                for imageURL in patternData[patternUrls]! {
                    images.insert(imageURL)
                }
            }
        }
        return (patterns,images)
    }
}
