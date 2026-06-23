import Foundation

struct MetadataIcon: Decodable {
    let unicode: String
    let free: [String]
}

struct GeneratedIcon: Comparable {
    let rawValue: String
    let caseName: String
    let unicode: String
    let style: String

    static func < (lhs: GeneratedIcon, rhs: GeneratedIcon) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum GeneratorError: Error, CustomStringConvertible {
    case missingArgument
    case sourceDirectoryNotFound(String)
    case metadataNotFound(String)
    case fontsDirectoryNotFound(String)
    case fontFileNotFound(String)

    var description: String {
        switch self {
        case .missingArgument:
            "Usage: swift run apple-font-awesome-generate <font-awesome-desktop-package-directory> [package-root]"
        case .sourceDirectoryNotFound(let path):
            "Font Awesome desktop package directory does not exist: \(path)"
        case .metadataNotFound(let path):
            "Font Awesome metadata file does not exist: \(path)"
        case .fontsDirectoryNotFound(let path):
            "Font Awesome OTF directory does not exist: \(path)"
        case .fontFileNotFound(let path):
            "Font Awesome font file does not exist: \(path)"
        }
    }
}

let fontFileNames = [
    "Font Awesome 7 Free-Solid-900",
    "Font Awesome 7 Free-Regular-400",
    "Font Awesome 7 Brands-Regular-400",
]

do {
    let fileManager = FileManager.default
    let arguments = CommandLine.arguments.dropFirst()
    guard let sourcePath = arguments.first else {
        throw GeneratorError.missingArgument
    }

    let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        throw GeneratorError.sourceDirectoryNotFound(sourceURL.path)
    }

    let metadataURL = sourceURL
        .appendingPathComponent("metadata", isDirectory: true)
        .appendingPathComponent("icons.json")
    guard fileManager.fileExists(atPath: metadataURL.path) else {
        throw GeneratorError.metadataNotFound(metadataURL.path)
    }

    let sourceFontsURL = sourceURL.appendingPathComponent("otfs", isDirectory: true)
    guard fileManager.fileExists(atPath: sourceFontsURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        throw GeneratorError.fontsDirectoryNotFound(sourceFontsURL.path)
    }

    let packageRoot: URL
    if arguments.count > 1 {
        packageRoot = URL(fileURLWithPath: String(arguments.dropFirst().first!)).standardizedFileURL
    } else {
        packageRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath).standardizedFileURL
    }

    let targetRoot = packageRoot.appendingPathComponent("Sources/AppleFontAwesome", isDirectory: true)
    let generatedRoot = targetRoot.appendingPathComponent("Generated", isDirectory: true)
    let resourcesRoot = targetRoot.appendingPathComponent("Resources", isDirectory: true)
    let fontsRoot = resourcesRoot.appendingPathComponent("Fonts", isDirectory: true)

    let metadata = try loadMetadata(from: metadataURL)
    let icons = generateIcons(from: metadata)

    try recreateDirectory(generatedRoot)
    try recreateDirectory(resourcesRoot)
    try fileManager.createDirectory(at: fontsRoot, withIntermediateDirectories: true)
    try copyFonts(from: sourceFontsURL, to: fontsRoot)

    let generatedSwift = generatedRoot.appendingPathComponent("FontAwesomeIcon.swift")
    try writeEnum(for: icons, to: generatedSwift)

    print("Generated \(icons.count) Font Awesome icons")
    print("Fonts: \(fontsRoot.path)")
    print("Swift: \(generatedSwift.path)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

func loadMetadata(from url: URL) throws -> [String: MetadataIcon] {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode([String: MetadataIcon].self, from: data)
}

func generateIcons(from metadata: [String: MetadataIcon]) -> [GeneratedIcon] {
    var usedCaseNames: [String: Int] = [:]
    var icons: [GeneratedIcon] = []

    for name in metadata.keys.sorted() {
        guard let icon = metadata[name] else {
            continue
        }
        let styles = Set(icon.free)

        if styles.contains("brands") {
            icons.append(
                makeIcon(
                    rawValue: name,
                    unicode: icon.unicode,
                    style: "brands",
                    usedCaseNames: &usedCaseNames
                )
            )
            continue
        }

        if styles.contains("regular") {
            icons.append(
                makeIcon(
                    rawValue: name,
                    unicode: icon.unicode,
                    style: "regular",
                    usedCaseNames: &usedCaseNames
                )
            )
        }

        if styles.contains("solid") {
            let rawValue = styles.contains("regular") ? "\(name).fill" : name
            icons.append(
                makeIcon(
                    rawValue: rawValue,
                    unicode: icon.unicode,
                    style: "solid",
                    usedCaseNames: &usedCaseNames
                )
            )
        }
    }

    return icons.sorted()
}

func makeIcon(
    rawValue: String,
    unicode: String,
    style: String,
    usedCaseNames: inout [String: Int]
) -> GeneratedIcon {
    let baseCaseName = swiftCaseName(for: rawValue)
    let index = usedCaseNames[baseCaseName, default: 0]
    usedCaseNames[baseCaseName] = index + 1
    let caseName = index == 0 ? baseCaseName : "\(baseCaseName)\(index + 1)"

    return GeneratedIcon(
        rawValue: rawValue,
        caseName: caseName,
        unicode: unicode.lowercased(),
        style: style
    )
}

func recreateDirectory(_ url: URL) throws {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: url.path) {
        try fileManager.removeItem(at: url)
    }
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
}

func copyFonts(from sourceFontsURL: URL, to fontsRoot: URL) throws {
    let fileManager = FileManager.default
    for fontFileName in fontFileNames {
        let source = sourceFontsURL.appendingPathComponent("\(fontFileName).otf")
        guard fileManager.fileExists(atPath: source.path) else {
            throw GeneratorError.fontFileNotFound(source.path)
        }

        try fileManager.copyItem(
            at: source,
            to: fontsRoot.appendingPathComponent("\(fontFileName).otf")
        )
    }
}

func writeEnum(for icons: [GeneratedIcon], to url: URL) throws {
    var output = """
    // Generated by AppleFontAwesomeGenerator. Do not edit manually.

    public enum FontAwesomeIcon: String, CaseIterable, Hashable, Identifiable, Sendable {

    """

    for icon in icons {
        output += "    case \(icon.caseName) = \"\(swiftEscaped(icon.rawValue))\"\n"
    }

    output += """

        public var id: String {
            rawValue
        }

        public var name: String {
            rawValue
        }

        public var character: String {
            switch self {

    """

    for icon in icons {
        output += "        case .\(icon.caseName):\n"
        output += "            \"\\u{\(icon.unicode)}\"\n"
    }

    output += """
            }
        }

        public var unicode: String {
            switch self {

    """

    for icon in icons {
        output += "        case .\(icon.caseName):\n"
        output += "            \"\(swiftEscaped(icon.unicode))\"\n"
    }

    output += """
            }
        }

        public var style: FontAwesomeStyle {
            switch self {

    """

    for icon in icons {
        output += "        case .\(icon.caseName):\n"
        output += "            .\(icon.style)\n"
    }

    output += """
            }
        }
    }

    """

    try output.write(to: url, atomically: true, encoding: .utf8)
}

func swiftCaseName(for rawValue: String) -> String {
    var outputBytes: [UInt8] = []
    var shouldUppercaseNext = false
    var hasOutput = false

    for byte in rawValue.utf8 {
        if isASCIIAlphanumeric(byte) {
            let outputByte: UInt8
            if !hasOutput {
                outputByte = asciiLowercased(byte)
            } else if shouldUppercaseNext {
                outputByte = asciiUppercased(byte)
            } else {
                outputByte = byte
            }
            outputBytes.append(outputByte)
            hasOutput = true
            shouldUppercaseNext = false
        } else if hasOutput {
            shouldUppercaseNext = true
        }
    }

    var name = outputBytes.isEmpty ? "icon" : asciiString(from: outputBytes)

    if name.isEmpty {
        name = "icon"
    }

    if let first = name.utf8.first, isASCIIDigit(first) {
        name = "number" + name.prefix(1).uppercased() + name.dropFirst()
    }

    if isSwiftKeyword(name) {
        name += "Icon"
    }

    return name
}

func isASCIIAlphanumeric(_ byte: UInt8) -> Bool {
    isASCIIDigit(byte) ||
        (byte >= 65 && byte <= 90) ||
        (byte >= 97 && byte <= 122)
}

func isASCIIDigit(_ byte: UInt8) -> Bool {
    byte >= 48 && byte <= 57
}

func asciiLowercased(_ byte: UInt8) -> UInt8 {
    if byte >= 65 && byte <= 90 {
        return byte + 32
    }
    return byte
}

func asciiUppercased(_ byte: UInt8) -> UInt8 {
    if byte >= 97 && byte <= 122 {
        return byte - 32
    }
    return byte
}

func asciiString(from bytes: [UInt8]) -> String {
    NSString(
        bytes: bytes,
        length: bytes.count,
        encoding: String.Encoding.utf8.rawValue
    )! as String
}

func swiftEscaped(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}

func isSwiftKeyword(_ value: String) -> Bool {
    switch value {
    case "Any", "Protocol", "Self", "Type", "actor", "as", "associatedtype", "async", "await",
        "break", "case", "catch", "class", "continue", "default", "defer", "deinit", "do",
        "else", "enum", "extension", "fallthrough", "false", "fileprivate", "for", "func",
        "guard", "if", "import", "in", "init", "inout", "internal", "is", "let", "nil",
        "nonisolated", "open", "operator", "private", "protocol", "public", "repeat",
        "rethrows", "return", "self", "static", "struct", "subscript", "super", "switch",
        "throw", "throws", "true", "try", "typealias", "var", "where", "while":
        true
    default:
        false
    }
}
