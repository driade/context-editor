import XCTest
@testable import ContextEditor

final class ContextEditorTests: XCTestCase {
    func testFindConfigWalksUpDirectoryTree() throws {
        let root = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectRoot = root.appendingPathComponent("workspace/project")
        let nested = projectRoot.appendingPathComponent("src/Feature")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let configURL = projectRoot.appendingPathComponent(".contexteditor")
        try #"{"editor":"cursor"}"#.write(to: configURL, atomically: true, encoding: .utf8)

        let resolver = EditorResolver()
        XCTAssertEqual(resolver.findConfig(startingFrom: nested), configURL)
    }

    func testResolveTargetApplicationUsesConfiguredAlias() throws {
        let root = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectRoot = root.appendingPathComponent("project")
        try FileManager.default.createDirectory(at: projectRoot, withIntermediateDirectories: true)
        try #"{"editor":"sublime"}"#.write(
            to: projectRoot.appendingPathComponent(".contexteditor"),
            atomically: true,
            encoding: .utf8
        )

        let fileURL = projectRoot.appendingPathComponent("index.php")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        let resolver = EditorResolver()
        XCTAssertEqual(
            try resolver.resolveTargetApplication(for: fileURL),
            TargetApplication(appName: "Sublime Text", bundleIdentifier: "com.sublimetext.4")
        )
    }

    func testResolveTargetApplicationRejectsBlankEditorValue() throws {
        let root = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectRoot = root.appendingPathComponent("project")
        try FileManager.default.createDirectory(at: projectRoot, withIntermediateDirectories: true)
        let configURL = projectRoot.appendingPathComponent(".contexteditor")
        try "{\"editor\":\"   \"}".write(to: configURL, atomically: true, encoding: .utf8)

        let fileURL = projectRoot.appendingPathComponent("index.php")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        let resolver = EditorResolver()

        XCTAssertThrowsError(try resolver.resolveTargetApplication(for: fileURL)) { error in
            XCTAssertEqual(error as? ConfigError, .invalidConfiguration(configURL))
        }
    }

    func testFallbackReturnsFirstInstalledEditor() {
        let resolver = EditorResolver { target in
            if target == TargetApplication(appName: "Nova", bundleIdentifier: "com.panic.Nova") {
                return URL(fileURLWithPath: "/Applications/Nova.app")
            }

            return nil
        }

        XCTAssertEqual(
            resolver.fallbackApplication(),
            TargetApplication(appName: "Nova", bundleIdentifier: "com.panic.Nova")
        )
    }

    func testSystemDefaultIsPreferredOverBuiltInFallback() throws {
        let root = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appendingPathComponent("notes.txt")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        let resolver = EditorResolver(
            appLocator: { _ in nil },
            systemDefaultLocator: { _ in
                TargetApplication(appName: "BBEdit", bundleIdentifier: "com.barebones.bbedit")
            }
        )

        XCTAssertEqual(
            try resolver.resolveTargetApplication(for: fileURL),
            TargetApplication(appName: "BBEdit", bundleIdentifier: "com.barebones.bbedit")
        )
    }

    func testUnknownEditorFallsBackToApplicationName() {
        let resolver = EditorResolver()

        XCTAssertEqual(
            resolver.targetApplication(for: "My Custom Editor"),
            TargetApplication(appName: "My Custom Editor", bundleIdentifier: nil)
        )
    }

    private func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
