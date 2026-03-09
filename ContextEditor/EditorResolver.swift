import Foundation

struct EditorConfig: Decodable {
    let editor: String?
}

struct TargetApplication: Equatable {
    let appName: String?
    let bundleIdentifier: String?
}

enum ConfigError: LocalizedError, Equatable {
    case missingConfiguration
    case invalidConfiguration(URL)
    case appNotInstalled(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "No supported editor was found and no valid .contexteditor file is available."
        case .invalidConfiguration(let url):
            return "Could not read \(url.path) as a valid configuration file."
        case .appNotInstalled(let name):
            return "The app \(name) is not installed."
        }
    }
}

struct EditorResolver {
    let fileManager: FileManager
    let appLocator: (TargetApplication) -> URL?
    let systemDefaultLocator: (URL) -> TargetApplication?

    init(
        fileManager: FileManager = .default,
        appLocator: @escaping (TargetApplication) -> URL? = { _ in nil },
        systemDefaultLocator: @escaping (URL) -> TargetApplication? = { _ in nil }
    ) {
        self.fileManager = fileManager
        self.appLocator = appLocator
        self.systemDefaultLocator = systemDefaultLocator
    }

    func resolveTargetApplication(for fileURL: URL) throws -> TargetApplication {
        if let configURL = findConfig(startingFrom: fileURL.deletingLastPathComponent()) {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(EditorConfig.self, from: data)

            if let alias = normalized(config.editor) {
                return targetApplication(for: alias)
            }

            throw ConfigError.invalidConfiguration(configURL)
        }

        if let fallback = systemDefaultLocator(fileURL) ?? fallbackApplication() {
            return fallback
        }

        throw ConfigError.missingConfiguration
    }

    func findConfig(startingFrom directoryURL: URL) -> URL? {
        var currentPath = directoryURL.path

        if currentPath.isEmpty {
            return nil
        }

        while true {
            let candidatePath = (currentPath as NSString).appendingPathComponent(".contexteditor")
            if fileManager.fileExists(atPath: candidatePath) {
                return URL(fileURLWithPath: candidatePath)
            }

            let parentPath = (currentPath as NSString).deletingLastPathComponent
            if parentPath.isEmpty || parentPath == currentPath {
                return nil
            }

            currentPath = parentPath
        }
    }

    func targetApplication(for rawValue: String) -> TargetApplication {
        let aliases: [String: TargetApplication] = [
            "cursor": TargetApplication(appName: "Cursor", bundleIdentifier: "com.todesktop.230313mzl4w4u92"),
            "vscode": TargetApplication(appName: "Visual Studio Code", bundleIdentifier: "com.microsoft.VSCode"),
            "code": TargetApplication(appName: "Visual Studio Code", bundleIdentifier: "com.microsoft.VSCode"),
            "codium": TargetApplication(appName: "VSCodium", bundleIdentifier: "com.vscodium"),
            "windsurf": TargetApplication(appName: "Windsurf", bundleIdentifier: "com.exafunction.windsurf"),
            "zed": TargetApplication(appName: "Zed", bundleIdentifier: "dev.zed.Zed"),
            "sublime": TargetApplication(appName: "Sublime Text", bundleIdentifier: "com.sublimetext.4"),
            "sublimetext": TargetApplication(appName: "Sublime Text", bundleIdentifier: "com.sublimetext.4"),
            "nova": TargetApplication(appName: "Nova", bundleIdentifier: "com.panic.Nova"),
            "bbedit": TargetApplication(appName: "BBEdit", bundleIdentifier: "com.barebones.bbedit"),
            "textmate": TargetApplication(appName: "TextMate", bundleIdentifier: "com.macromates.TextMate"),
            "coteditor": TargetApplication(appName: "CotEditor", bundleIdentifier: "com.coteditor.CotEditor"),
            "macvim": TargetApplication(appName: "MacVim", bundleIdentifier: "org.vim.MacVim"),
            "textedit": TargetApplication(appName: "TextEdit", bundleIdentifier: "com.apple.TextEdit")
        ]

        if let target = aliases[rawValue.lowercased()] {
            return target
        }

        return TargetApplication(appName: rawValue, bundleIdentifier: nil)
    }

    func fallbackApplication() -> TargetApplication? {
        let candidates = ["cursor", "vscode", "zed", "sublime", "nova", "bbedit", "textmate", "coteditor", "macvim", "textedit"]

        for candidate in candidates {
            let target = targetApplication(for: candidate)
            if appLocator(target) != nil {
                return target
            }
        }

        return nil
    }

    func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }
}
