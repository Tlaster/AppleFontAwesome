#if canImport(SwiftUI)
import SwiftUI

public extension Image {
    init(fontAwesome icon: FontAwesomeIcon) {
        self.init(icon.assetName, bundle: AppleFontAwesomeResources.bundle)
    }
}
#endif

#if canImport(UIKit)
import UIKit

public extension UIImage {
    convenience init?(
        fontAwesome icon: FontAwesomeIcon,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) {
        self.init(
            named: icon.assetName,
            in: AppleFontAwesomeResources.bundle,
            compatibleWith: traitCollection
        )
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public extension NSImage {
    static func fontAwesome(_ icon: FontAwesomeIcon) -> NSImage? {
        AppleFontAwesomeResources.bundle.image(forResource: icon.assetName)
    }
}
#endif
