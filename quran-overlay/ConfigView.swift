import SwiftUI
import UniformTypeIdentifiers
import LaunchAtLogin


struct ConfigView: View {
    @AppStorage("WidgetPositionX") private var x: Double = 50.0
    @AppStorage("WidgetPositionY") private var y: Double = 50.0
    @AppStorage("WidgetLayer") private var widgetLayer: String = "desktopIcon"
    @AppStorage("WidgetBrightness") private var brightness: Double = 0.0
    @AppStorage("WidgetContrast") private var contrast: Double = 1.0
    @AppStorage("WidgetTint") private var tintColor: Color = .white
    @AppStorage("UpdateFrequencyHours") private var updateFrequency: Double = 24.0
    @AppStorage("ArabicFontSize") private var arabicFontSize: Double = 40.0
    @AppStorage("TranslationFontSize") private var translationFontSize: Double = 18.0
    
    @ObservedObject var quranManager = QuranManager.shared
    @State private var isShowingFilePicker = false
    @State private var fileTypeToPick: FileType?
    
    enum FileType {
        case quran, translation, cycle
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Quran Overlay Configurator")
                    .font(.headline)
                
                LaunchAtLogin.Toggle("Launch at login")
                
                // Verse Section
                VStack(spacing: 10) {
                    Button("Randomize Now") {
                        quranManager.pickRandomVerse()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    HStack {
                        Text("Update Every:")
                        Slider(value: $updateFrequency, in: 1...168, step: 1)
                        Text("\(Int(updateFrequency))h")
                    }
                    Text("Reference: fawazahmed0/quran-api")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            if let url = URL(string: "https://github.com/fawazahmed0/quran-api/") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)

                Divider()

                // Position Section
                VStack(alignment: .leading) {
                    Text("Position").font(.subheadline).bold()
                    HStack {
                        Text("Horizontal")
                        Slider(value: $x, in: 0...100)
                    }
                    HStack {
                        Text("Vertical")
                        Slider(value: $y, in: 0...100)
                    }
                    Button("Center Widget") {
                        x = 50
                        y = 50
                    }
                    
                    Divider().padding(.vertical, 5)
                    
                    VStack(alignment: .leading) {
                        Text("Layer").font(.subheadline).bold()
                        Text("Choose where the widget sits on your desktop.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Widget Layer", selection: $widgetLayer) {
                            Text("Behind Icons").tag("desktop")
                            Text("Above Icons").tag("desktopIcon")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Divider()

                // Appearance Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Appearance").font(.subheadline).bold()
                    ColorPicker("Tint Color", selection: $tintColor)
                    
                    VStack(alignment: .leading) {
                        Text("Arabic Font Size: \(Int(arabicFontSize))")
                        Slider(value: $arabicFontSize, in: 10...100, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Translation Font Size: \(Int(translationFontSize))")
                        Slider(value: $translationFontSize, in: 10...60, step: 1)
                    }
                    
                    HStack {
                        Text("Brightness")
                        Slider(value: $brightness, in: -1...1)
                    }
                    HStack {
                        Text("Contrast")
                        Slider(value: $contrast, in: 0...2)
                    }
                }

                Divider()

                // File Upload Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Custom Assets").font(.subheadline).bold()
                    
                    fileButton(label: "Upload Quran (Arabic)", type: .quran)
                    fileButton(label: "Upload Translation", type: .translation)
                    fileButton(label: "Upload Cycle (.txt)", type: .cycle)
                    
                    InfoBox(text: "Quran/Translation: JSON format from quran-api.\nCycle: List of chapter:verse (e.g. 1:1) per line.")
                }
                
                Button("Reset All Settings") {
                    resetSettings()
                }
                .foregroundColor(.red)
                .padding(.top)
            }
            .padding()
        }
        .frame(width: 400, height: 650)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [UTType.json, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func fileButton(label: String, type: FileType) -> some View {
        Button(label) {
            fileTypeToPick = type
            isShowingFilePicker = true
        }
        .buttonStyle(.bordered)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first, let type = fileTypeToPick else { return }
        
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        
        let destName: String
        switch type {
        case .quran: destName = "quran.json"
        case .translation: destName = "translation.json"
        case .cycle: destName = "cycle.txt"
        }
        
        let destURL = appSupport.appendingPathComponent(destName)
        try? fileManager.removeItem(at: destURL)
        try? fileManager.copyItem(at: url, to: destURL)
        
        quranManager.loadData()
        quranManager.pickRandomVerse()
    }

    private func resetSettings() {
        x = 50
        y = 50
        widgetLayer = "desktopIcon"
        brightness = 0.0
        contrast = 1.0
        tintColor = .white
        updateFrequency = 24.0
    }
}

struct InfoBox: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(5)
            .foregroundColor(.secondary)
    }
}
