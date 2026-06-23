# AppleFontAwesome

Swift Package wrapper for Font Awesome SVG symbols on Apple platforms.

Misskey and Nostr compatibility symbols are included for Flare-style social platform icon coverage; see `NOTICE.md`.

## Generate

```sh
swift run apple-font-awesome-generate /path/to/font-awesome-svg-directory
```

The generator writes:

- `Sources/AppleFontAwesome/Generated/FontAwesomeIcon.swift`
- `Sources/AppleFontAwesome/Resources/FontAwesome.xcassets`

## Usage

```swift
import AppleFontAwesome
import SwiftUI

Image(fontAwesome: .house)
```

UIKit:

```swift
UIImage(fontAwesome: .house)
```

AppKit:

```swift
NSImage.fontAwesome(.house)
```

## License

AppleFontAwesome package source code is available under the MIT License.
Generated Font Awesome icon assets are licensed separately by Fonticons, Inc.;
see `LICENSE-FONT-AWESOME.txt` and `NOTICE.md`.
