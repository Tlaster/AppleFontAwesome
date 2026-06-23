import Foundation

struct Icon: Comparable {
    let assetName: String
    let caseName: String
    let sourceURL: URL

    static func < (lhs: Icon, rhs: Icon) -> Bool {
        lhs.assetName < rhs.assetName
    }
}

enum GeneratorError: Error, CustomStringConvertible {
    case missingArgument
    case sourceDirectoryNotFound(String)

    var description: String {
        switch self {
        case .missingArgument:
            "Usage: swift run apple-font-awesome-generate <font-awesome-svg-directory> [package-root]"
        case .sourceDirectoryNotFound(let path):
            "Font Awesome SVG directory does not exist: \(path)"
        }
    }
}

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

    let packageRoot: URL
    if arguments.count > 1 {
        packageRoot = URL(fileURLWithPath: String(arguments.dropFirst().first!)).standardizedFileURL
    } else {
        packageRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath).standardizedFileURL
    }

    let targetRoot = packageRoot.appendingPathComponent("Sources/AppleFontAwesome", isDirectory: true)
    let generatedRoot = targetRoot.appendingPathComponent("Generated", isDirectory: true)
    let resourcesRoot = targetRoot.appendingPathComponent("Resources", isDirectory: true)
    let assetCatalog = resourcesRoot.appendingPathComponent("FontAwesome.xcassets", isDirectory: true)

    let icons = try discoverIcons(in: sourceURL)

    try recreateDirectory(generatedRoot)
    try recreateDirectory(resourcesRoot)
    try fileManager.createDirectory(at: assetCatalog, withIntermediateDirectories: true)

    try writeRootAssetCatalogContents(to: assetCatalog)
    try writeAssets(for: icons, to: assetCatalog)
    let generatedSwift = generatedRoot.appendingPathComponent("FontAwesomeIcon.swift")
    try writeEnum(for: icons, to: generatedSwift)

    print("Generated \(icons.count) Font Awesome icons")
    print("Assets: \(assetCatalog.path)")
    print("Swift: \(generatedSwift.path)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

func discoverIcons(in sourceURL: URL) throws -> [Icon] {
    let fileManager = FileManager.default
    let fileNames = try fileManager.contentsOfDirectory(atPath: sourceURL.path)
        .filter { !$0.hasPrefix(".") }

    var usedCaseNames: [String: Int] = [:]
    var icons: [Icon] = []

    for fileName in fileNames where fileName.hasSuffix(".svg") {
        let path = (sourceURL.path as NSString).appendingPathComponent(fileName)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            continue
        }

        let assetName = String(fileName.dropLast(4))
        let baseCaseName = swiftCaseName(for: assetName)
        let index = usedCaseNames[baseCaseName, default: 0]
        usedCaseNames[baseCaseName] = index + 1
        let caseName = index == 0 ? baseCaseName : "\(baseCaseName)\(index + 1)"

        icons.append(Icon(assetName: assetName, caseName: caseName, sourceURL: URL(fileURLWithPath: path)))
    }

    return icons.sorted()
}

func recreateDirectory(_ url: URL) throws {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: url.path) {
        try fileManager.removeItem(at: url)
    }
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
}

func writeRootAssetCatalogContents(to assetCatalog: URL) throws {
    try writeJSON(
        """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """,
        to: assetCatalog.appendingPathComponent("Contents.json")
    )
}

func writeAssets(for icons: [Icon], to assetCatalog: URL) throws {
    let fileManager = FileManager.default
    for icon in icons {
        let symbolSet = assetCatalog.appendingPathComponent("\(icon.assetName).symbolset", isDirectory: true)
        try fileManager.createDirectory(at: symbolSet, withIntermediateDirectories: true)

        let svgFileName = "\(icon.assetName).svg"
        let targetSVG = symbolSet.appendingPathComponent(svgFileName)
        try fileManager.copyItem(at: icon.sourceURL, to: targetSVG)

        try writeJSON(
            """
            {
              "info" : {
                "author" : "xcode",
                "version" : 1
              },
              "symbols" : [
                {
                  "filename" : "\(jsonEscaped(svgFileName))",
                  "idiom" : "universal"
                }
              ]
            }
            """,
            to: symbolSet.appendingPathComponent("Contents.json")
        )
    }
}

func writeEnum(for icons: [Icon], to url: URL) throws {
    var output = """
    // Generated by AppleFontAwesomeGenerator. Do not edit manually.

    public enum FontAwesomeIcon: String, CaseIterable, Hashable, Identifiable, Sendable {

    """

    for icon in icons {
        output += "    case \(icon.caseName) = \"\(swiftEscaped(icon.assetName))\"\n"
    }

    output += """

        public var id: String {
            rawValue
        }

        public var assetName: String {
            rawValue
        }
    }

    """

    try output.write(to: url, atomically: true, encoding: .utf8)
}

func writeJSON(_ value: String, to url: URL) throws {
    try value.write(to: url, atomically: true, encoding: .utf8)
}

func swiftCaseName(for assetName: String) -> String {
    var outputBytes: [UInt8] = []
    var shouldUppercaseNext = false
    var hasOutput = false

    for byte in assetName.utf8 {
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

func jsonEscaped(_ value: String) -> String {
    swiftEscaped(value)
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
