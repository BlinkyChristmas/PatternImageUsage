//Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SynchronizedScollView: NSScrollView {
    public weak var synchronizedScrollView: NSScrollView? {
        didSet {
            if let oldValue = oldValue {
                stopSynchronizing(with: oldValue)
            }
            guard let newValue = synchronizedScrollView else { return }
            startSynchronizing(with:newValue)
        }
    }
    
    private func startSynchronizing(with scrollview: NSScrollView) {
        let synchronizedContentView = scrollview.contentView
        // Make sure the other view is sending bounds changed
        synchronizedContentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(synchronizedViewContentBoundsDidChange(_:)),
                                                       name: NSView.boundsDidChangeNotification, object: synchronizedContentView)
    }
    @objc private func synchronizedViewContentBoundsDidChange(_ notification: NSNotification) {
        // get the changed content view from the notification
        guard let changedContentView = notification.object as? NSClipView else { return }
        guard changedContentView != self.contentView else { return }
        // get the origin of the NSClipView of
        // the scroll view that we're watching
        let changedBoundsOrigin = changedContentView.documentVisibleRect.origin
        // get our current origin
        let curOffset = contentView.bounds.origin
        var newOffset = curOffset
        // scrolling is synchronized in the vertical plane
        if changedContentView == self.synchronizedScrollView?.contentView {
            // so only modify the y component of the offset
            newOffset.y = changedBoundsOrigin.y
            
            
            if !hasHorizontalRuler {
                newOffset.y = changedBoundsOrigin.y + 32.0
            }
            else {
                newOffset.y = changedBoundsOrigin.y - 32.0
            }
            
            
        }
        // if our synced position is different from our current
        // position, reposition our content view
        if !NSEqualPoints(changedBoundsOrigin, curOffset) {
            // note that a scroll view watching this one will
            // get notified here
            /*
            if newOffset.x > contentView.frame.width {
                newOffset.x = contentView.frame.width
            }
             */
            //if contentView.bounds.size.height >= newOffset.y  && contentView.bounds.size.width >= newOffset.x{
                
               contentView.scroll(to: newOffset)
                // we have to tell the NSScrollView to update its
                // scrollers
                reflectScrolledClipView(contentView)
            //}
        }
    }
    
    private func stopSynchronizing(with scrollview: NSScrollView) {
        
        let synchronizedContentView = scrollview.contentView
        // remove any existing notification registration
        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification,
                                                  object: synchronizedContentView)
    }

}

