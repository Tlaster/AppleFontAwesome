#if canImport(SwiftUI)
import SwiftUI

public struct FontAwesomeIconView: View {
    private let icon: FontAwesomeIcon
    private let size: CGFloat

    public init(_ icon: FontAwesomeIcon, size: CGFloat = 20) {
        self.icon = icon
        self.size = size
        FontAwesomeFont.registerFonts()
    }

    public var body: some View {
        Text(icon.character)
            .font(.custom(icon.style.postScriptName, fixedSize: size))
            .frame(width: size, height: size, alignment: .center)
            .lineLimit(1)
            .accessibilityHidden(true)
    }
}
#endif
