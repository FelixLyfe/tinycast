# Development

## Requirements

- macOS 26+
- Xcode 26
- XcodeGen
- SwiftLint

```sh
brew install xcodegen swiftlint
xcodegen generate
open Cliiippo.xcodeproj
```

Debug uses `io.github.felixlyfe.cliiippo.dev` and builds as `Cliiippo Dev.app`. Release uses
`io.github.felixlyfe.cliiippo` and builds as `Cliiippo.app`.

## Command-line validation

```sh
xcodegen generate
xcodebuild -project Cliiippo.xcodeproj -scheme Cliiippo \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Cliiippo.xcodeproj -scheme Cliiippo \
  -configuration Release CODE_SIGNING_ALLOWED=NO build
./Scripts/run-tests.sh
./Scripts/lint.sh
```

Use a custom `-derivedDataPath` when the environment cannot write to Xcode's default DerivedData.
