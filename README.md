# ContextEditor

ContextEditor is a macOS app that routes text and source files to different editors depending on the current project.

It is designed for setups where one project should open in Cursor, another in VS Code, and another in Sublime Text, while macOS still uses a single default app in Finder.

## How It Works

1. macOS sends the clicked file to `ContextEditor`.
2. `ContextEditor` walks up the directory tree looking for `.contexteditor`.
3. It reads the `editor` value.
4. It opens the file in the matching real editor app.
5. If there is no `.contexteditor`, it asks macOS for the real default app for that file type and avoids routing back into `ContextEditor`.

## `.contexteditor`

Place a `.contexteditor` file at the root of a project:

```json
{
  "editor": "cursor"
}
```

Supported values:

- `cursor`
- `vscode`
- `code`
- `codium`
- `windsurf`
- `zed`
- `sublime`
- `sublimetext`
- `nova`
- `bbedit`
- `textmate`
- `coteditor`
- `macvim`
- `textedit`

## Download

Prebuilt binaries are available from the [Releases](https://github.com/driade/context-editor/releases) page.

The initial public release is `v0.1.0`.

## Build

Requirements:
- macOS
- Xcode
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
git clone https://github.com/driade/context-editor.git
cd context-editor
xcodegen generate
./scripts/build_universal.sh
```

The app will be generated at:

```bash
build-universal/output/ContextEditor.app
```

That command builds a universal macOS app with Apple Silicon and Intel slices.

## Tests

```bash
xcodebuild -project ContextEditor.xcodeproj -scheme ContextEditor -configuration Debug -derivedDataPath build test
```

The test suite covers configuration lookup and editor resolution behavior.

## Use in Finder

1. Build `ContextEditor.app`.
2. In Finder, select any text or source file and open `Get Info`.
3. Under `Open with`, choose `ContextEditor`.
4. Click `Change All...`.

## Notes

- The app is registered as an editor for common text and source-code content types through its `Info.plist`.
- Finder associations are still controlled per file type by macOS, so you may need to use `Get Info > Open with > Change All...` for the file families you care about.

## License

This project is intended to be available under a broad permissive license.
Use, modify, distribute, and include it in commercial or private projects with attribution.

Recommended license: MIT.
