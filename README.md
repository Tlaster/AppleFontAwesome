# AppleFontAwesome

Swift Package wrapper for Font Awesome font rendering on Apple platforms.

The package renders Font Awesome glyphs from bundled OTF fonts instead of
shipping one SVG asset per icon.

## Generate

```sh
swift run apple-font-awesome-generate /path/to/fontawesome-free-desktop
```

The generator writes:

- `Sources/AppleFontAwesome/Generated/FontAwesomeIcon.swift`
- `Sources/AppleFontAwesome/Resources/Fonts/*.otf`

## Usage

```swift
import AppleFontAwesome
import SwiftUI

FontAwesomeIconView(.houseFill, size: 20)
```

## License

AppleFontAwesome package source code is available under the MIT License.
Bundled Font Awesome fonts are licensed separately by Fonticons, Inc.;
see `LICENSE-FONT-AWESOME.txt` and `NOTICE.md`.
