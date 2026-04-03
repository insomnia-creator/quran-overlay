import SwiftUI
import AppKit

extension Color: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .white
            return
        }
        
        do {
            let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) ?? .white
            self = Color(nsColor)
        } catch {
            self = .white
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(self), requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}
