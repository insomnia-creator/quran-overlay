import SwiftUI
import AppKit

class WidgetWindow: NSWindow {
    private var targetScreen: NSScreen?
    
    init(contentView: NSView, frame: NSRect, screen: NSScreen) {
        self.targetScreen = screen
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        updateLayer()
        
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = true // The widget itself is non-interactive
        
        self.contentView = contentView
        
        loadPosition()
        
        // Listen for UserDefaults changes from the configurator window
        NotificationCenter.default.addObserver(self, selector: #selector(loadPosition), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayer), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc private func loadPosition() {
        let xPercent = UserDefaults.standard.object(forKey: "WidgetPositionX") != nil ? UserDefaults.standard.double(forKey: "WidgetPositionX") : 50.0
        let yPercent = UserDefaults.standard.object(forKey: "WidgetPositionY") != nil ? UserDefaults.standard.double(forKey: "WidgetPositionY") : 50.0
        
        let screen = targetScreen ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame
        
        // Calculate position relative to screen frame
        // Subtract window size to ensure it stays within bounds at 100%
        let x = screenFrame.minX + (screenFrame.width - self.frame.width) * (xPercent / 100.0)
        let y = screenFrame.minY + (screenFrame.height - self.frame.height) * (yPercent / 100.0)
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func updateLayer() {
        let layer = UserDefaults.standard.string(forKey: "WidgetLayer") ?? "desktopIcon"
        if layer == "desktop" {
            self.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        } else {
            self.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
