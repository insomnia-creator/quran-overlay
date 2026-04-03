import Foundation
import SwiftUI
import Combine

struct QuranChapter: Codable {
    let id: Int
    let name: String
    let transliteration: String
    let verses: [QuranVerse]
}

struct QuranVerse: Codable {
    let id: Int
    let text: String
}

struct TranslationFile: Codable {
    let quran: [TranslationVerse]
}

struct TranslationVerse: Codable {
    let chapter: Int
    let verse: Int
    let text: String
}

class QuranManager: ObservableObject {
    static let shared = QuranManager()
    
    @Published var currentArabic: String = ""
    @Published var currentTranslation: String = ""
    @Published var currentReference: String = ""
    
    private var chapters: [QuranChapter] = []
    private var translations: [TranslationVerse] = []
    private var cycle: [String] = []
    private var timer: Timer?
    
    private enum Asset: CaseIterable {
        case quran
        case translation
        case cycle

        var fileName: String {
            switch self {
            case .quran: return "quran.json"
            case .translation: return "translation.json"
            case .cycle: return "cycle.txt"
            }
        }

        var bundleResourceName: String {
            switch self {
            case .quran: return "quran"
            case .translation: return "translation"
            case .cycle: return "cycle"
            }
        }

        var bundleExtension: String {
            switch self {
            case .quran: return "json"
            case .translation: return "json"
            case .cycle: return "txt"
            }
        }
    }

    private func appSupportDirectory() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private func assetURLInAppSupport(_ asset: Asset) -> URL? {
        guard let base = appSupportDirectory() else { return nil }
        return base.appendingPathComponent(asset.fileName)
    }

    private func assetURLInBundle(_ asset: Asset) -> URL? {
        Bundle.main.url(forResource: asset.bundleResourceName, withExtension: asset.bundleExtension)
    }

    private func verifyAssets() {
        print("[QuranManager] Verifying assets...")
        for asset in Asset.allCases {
            let appSupportPath = assetURLInAppSupport(asset)?.path ?? "<nil>"
            let bundlePath = assetURLInBundle(asset)?.path ?? "<nil>"
            let appSupportExists = (assetURLInAppSupport(asset)).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
            let bundleExists = assetURLInBundle(asset) != nil
            print("[QuranManager] Asset \(asset): AppSupport exists=\(appSupportExists) at \(appSupportPath); Bundle exists=\(bundleExists) at \(bundlePath)")
        }
    }
    
    init() {
        prepareAssets()
        verifyAssets()
        loadData()
        refreshVerseIfNeeded()
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
            self.refreshVerseIfNeeded()
        }
    }
    
    private func prepareAssets() {
        let fileManager = FileManager.default
        guard let appSupport = appSupportDirectory() else {
            print("[QuranManager] Failed to resolve Application Support directory")
            return
        }

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupport.path) {
            do {
                try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
                print("[QuranManager] Created Application Support at: \(appSupport.path)")
            } catch {
                print("[QuranManager] Error creating Application Support directory: \(error)")
            }
        } else {
            // Ensure it's not a file collision
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: appSupport.path, isDirectory: &isDir), !isDir.boolValue {
                print("[QuranManager] Expected directory at Application Support path but found a file.")
            }
        }

        // Define assets and copy if missing
        for asset in Asset.allCases {
            guard let destURL = assetURLInAppSupport(asset) else { continue }

            if !fileManager.fileExists(atPath: destURL.path) {
                if let bundleURL = assetURLInBundle(asset) {
                    do {
                        try fileManager.copyItem(at: bundleURL, to: destURL)
                        print("[QuranManager] Copied \(asset.fileName) to Application Support")
                    } catch {
                        print("[QuranManager] Failed to copy \(asset.fileName): \(error)")
                    }
                } else {
                    print("[QuranManager] Missing \(asset.fileName) in bundle subdirectory 'qrn-assets'. Ensure the folder is added to the app target and files are included.")
                }
            } else {
                // Optional: you can validate size or freshness here if needed
                // For now, we leave existing files in place
                // print("[QuranManager] \(asset.fileName) already present in Application Support")
            }
        }
    }
    
    func loadData() {
        let fileManager = FileManager.default

        // Resolve URLs
        let quranAppURL = assetURLInAppSupport(.quran)
        let transAppURL = assetURLInAppSupport(.translation)
        let cycleAppURL = assetURLInAppSupport(.cycle)

        let quranBundleURL = assetURLInBundle(.quran)
        let transBundleURL = assetURLInBundle(.translation)
        let cycleBundleURL = assetURLInBundle(.cycle)

        // Load Quran Arabic
        if let url = (quranAppURL?.path).flatMap({ fileManager.fileExists(atPath: $0) ? quranAppURL : nil }) ?? quranBundleURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([QuranChapter].self, from: data) {
            self.chapters = decoded
        } else {
            print("[QuranManager] Failed to load quran.json from both App Support and bundle.")
        }

        // Load Translations
        if let url = (transAppURL?.path).flatMap({ fileManager.fileExists(atPath: $0) ? transAppURL : nil }) ?? transBundleURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(TranslationFile.self, from: data) {
            self.translations = decoded.quran
        } else {
            print("[QuranManager] Failed to load translation.json from both App Support and bundle.")
        }

        // Load Cycle
        if let url = (cycleAppURL?.path).flatMap({ fileManager.fileExists(atPath: $0) ? cycleAppURL : nil }) ?? cycleBundleURL,
           let content = try? String(contentsOf: url) {
            self.cycle = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        } else {
            print("[QuranManager] Failed to load cycle.txt from both App Support and bundle.")
        }
    }
    
    func refreshVerseIfNeeded() {
        let lastUpdate = UserDefaults.standard.double(forKey: "LastUpdateTimestamp")
        let frequencyHours = UserDefaults.standard.double(forKey: "UpdateFrequencyHours")
        let interval = (frequencyHours == 0 ? 24.0 : frequencyHours) * 3600
        
        let now = Date().timeIntervalSince1970
        if now - lastUpdate >= interval {
            pickRandomVerse()
        } else {
            loadSavedVerse()
        }
    }
    
    func pickRandomVerse() {
        guard !cycle.isEmpty else { return }
        let randomRef = cycle.randomElement()!
        displayVerse(ref: randomRef)
        
        UserDefaults.standard.set(randomRef, forKey: "CurrentVerseRef")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "LastUpdateTimestamp")
    }
    
    private func loadSavedVerse() {
        if let ref = UserDefaults.standard.string(forKey: "CurrentVerseRef") {
            displayVerse(ref: ref)
        } else {
            pickRandomVerse()
        }
    }
    
    private func displayVerse(ref: String) {
        let parts = ref.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        guard parts.count == 2, let chapId = Int(parts[0]), let verseId = Int(parts[1]) else { return }
        
        let arabic = chapters.first(where: { $0.id == chapId })?.verses.first(where: { $0.id == verseId })?.text ?? "Arabic not found (\(ref))"
        let trans = translations.first(where: { $0.chapter == chapId && $0.verse == verseId })?.text ?? "Translation not found"
        
        DispatchQueue.main.async {
            self.currentArabic = arabic
            self.currentTranslation = trans
            self.currentReference = "(\(chapId):\(verseId))"
        }
    }
}

