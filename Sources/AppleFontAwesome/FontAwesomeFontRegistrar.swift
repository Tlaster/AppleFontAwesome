import Foundation

#if canImport(CoreText)
import CoreText
#endif

public enum FontAwesomeFont {
    public static func registerFonts() {
        FontAwesomeFontRegistrar.registerFonts()
    }
}

enum FontAwesomeFontRegistrar {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var registeredStyles: Set<FontAwesomeStyle> = []

    static func registerFonts() {
        lock.lock()
        let styles = FontAwesomeStyle.allCases.filter { !registeredStyles.contains($0) }
        registeredStyles.formUnion(styles)
        lock.unlock()

        for style in styles {
            registerFont(for: style)
        }
    }

    private static func registerFont(for style: FontAwesomeStyle) {
        #if canImport(CoreText)
        guard let url = fontURL(for: style) else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        #endif
    }

    private static func fontURL(for style: FontAwesomeStyle) -> URL? {
        Bundle.module.url(
            forResource: style.fontFileName,
            withExtension: "otf",
            subdirectory: "Fonts"
        ) ?? Bundle.module.url(
            forResource: style.fontFileName,
            withExtension: "otf"
        )
    }
}
