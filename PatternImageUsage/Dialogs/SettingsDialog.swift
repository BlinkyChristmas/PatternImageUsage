// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SettingsDialog : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "SettingsDialog"
    }
    
    @objc dynamic var settingsData = SettingsData() {
        didSet {
            settingsData.isTracking = true
            settingsData.reset()
        }
    }
    @IBOutlet var masterData:SettingsData!
    
    @IBAction func selectLocation(_ sender:Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        switch tag {
        case 1:
            panel.prompt = "Select Blinky Home Directory"
        default:
            panel.prompt = "Select Music Directory"
        }
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK , panel.url != nil else { return }
            switch tag {
            case 1:
                self.settingsData.homeDirectory = panel.url
            default:
                self.settingsData.musicDirectory = panel.url
            }
        }
    }
    
    func updateMaster() {
        do {
            try masterData.updateChangesFrom(settingsData: settingsData)
            try masterData.saveToDefaults(keys: settingsData.changes)
            settingsData.reset()
        }
        catch{
            NSAlert(error: GeneralError(errorMessage: "Error Applying Settings", failure: error.localizedDescription)).beginSheetModal(for: self.window!)
        }
        
    }
    
    @IBAction func endDialog(_ sender: Any?) {
        self.window?.makeFirstResponder((sender as! NSControl))
        let response = ((sender as? NSControl)?.tag ?? 0 ) == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
        defer {
            self.close()
        }
        guard response == .OK else { settingsData = masterData.partialCopy(); return  }
        updateMaster()
    }
    
    override func windowDidLoad() {
        settingsData = masterData.partialCopy() 
    }
}
