public enum FontAwesomeStyle: String, CaseIterable, Hashable, Sendable {
    case solid
    case regular
    case brands

    public var postScriptName: String {
        switch self {
        case .solid:
            "FontAwesome7Free-Solid"
        case .regular:
            "FontAwesome7Free-Regular"
        case .brands:
            "FontAwesome7Brands-Regular"
        }
    }

    var fontFileName: String {
        switch self {
        case .solid:
            "Font Awesome 7 Free-Solid-900"
        case .regular:
            "Font Awesome 7 Free-Regular-400"
        case .brands:
            "Font Awesome 7 Brands-Regular-400"
        }
    }
}
