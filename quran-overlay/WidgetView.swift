import SwiftUI
import LiquidGlassText

struct WidgetView: View {
    @ObservedObject var quranManager = QuranManager.shared
    @AppStorage("WidgetBrightness") private var brightness: Double = 0.0
    @AppStorage("WidgetContrast") private var contrast: Double = 1.0
    @AppStorage("WidgetTint") private var tintColor: Color = .white
    @AppStorage("ArabicFontSize") private var arabicFontSize: Double = 32.0
    @AppStorage("TranslationFontSize") private var translationFontSize: Double = 18.0
    
    var body: some View {
        VStack(spacing: 12) {
            
            LiquidGlassText(quranManager.currentArabic, glass: .clear.tint(.white.opacity(0.9)).tint(tintColor), fontName: "SF Arabic", size: arabicFontSize)
                .brightness(brightness)
                .contrast(contrast)
            
            LiquidGlassText("\(quranManager.currentTranslation) \(quranManager.currentReference)", glass: .clear.tint(.white.opacity(0.9)).tint(tintColor), fontName: "SF Arabic", size: translationFontSize)
                .brightness(brightness)
                .contrast(contrast)
        }
        .padding(30)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity) 
    }
}
