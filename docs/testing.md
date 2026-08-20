# Testing

`./Scripts/run-tests.sh` compiles and executes ten standalone Swift harnesses for clipboard storage,
migration and filtering, appearance, palette placement, scroll following, hover arming, hotkeys, callout
placement, icon caching, and Settings navigation.

The definition of done is:

```sh
xcodegen generate
./Scripts/run-tests.sh
./Scripts/lint.sh
xcodebuild -project Cliiippo.xcodeproj -scheme Cliiippo \
  -configuration Debug CODE_SIGNING_ALLOWED=NO clean build
xcodebuild -project Cliiippo.xcodeproj -scheme Cliiippo \
  -configuration Release CODE_SIGNING_ALLOWED=NO clean build
```

Also smoke-test text and image capture, search and type filters, pin/unpin, delete/clear, copy, both
paste modes, application exclusions, retention, language switching, onboarding, coexistence with
Tinycast, and migration rollback behavior.
