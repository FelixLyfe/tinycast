# Cliiippo

Cliiippo is a focused, native macOS clipboard-history app. It records copied text and images locally,
lets you search and filter them, and pastes them back into the app you were using.

## Features

- Searchable text and image clipboard history
- Type filters for text, images, links, and email addresses
- Pin, copy, paste, paste while keeping the window open, delete, and clear
- Source-application display and per-application exclusions
- Configurable retention, appearance, launch at login, and global shortcut
- English and Simplified Chinese interface
- Menu-bar operation with no Dock icon

Clipboard history is stored in the app's Application Support directory. Cliiippo does not use
telemetry or third-party dependencies.

## Tinycast migration

On first launch, Cliiippo can copy clipboard history and clipboard-related preferences from an
existing Tinycast installation. Tinycast must be closed. Migration never moves or deletes Tinycast
data, and a failed import rolls back the partial Cliiippo copy.

Tinycast shortcut, login-item, onboarding, and Accessibility permission state are intentionally not
migrated. Notes, snippets, extensions, and all other Tinycast data are left untouched.

## Build

Requirements: macOS 26+, Xcode 26, XcodeGen, and SwiftLint.

```sh
xcodegen generate
xcodebuild -project Cliiippo.xcodeproj -scheme Cliiippo \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
./Scripts/run-tests.sh
./Scripts/lint.sh
```

See [development](docs/development.md), [testing](docs/testing.md), and
[signing](docs/signing.md) for the full local workflow.

## Attribution and license

Cliiippo is forked from [Tinycast](https://github.com/abue-ammar/tinycast) by Abue Ammar and retains
its copyright and license notices. Cliiippo is licensed under [AGPL-3.0](LICENSE).
