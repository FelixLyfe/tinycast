# Local release

Cliiippo currently ships as a local self-signed `.app` and ZIP. It is not notarized and has no
App Store or automated GitHub Release workflow.

1. Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.
2. Run `xcodegen generate`, all tests, lint, and clean Debug and Release builds.
3. Build Release with the stable `Cliiippo Self-Signed` identity.
4. Verify bundle ID, version, languages, icon, and signature.
5. Archive with `ditto -c -k --sequesterRsrc --keepParent Cliiippo.app Cliiippo-<version>.zip`.

Do not publish or notarize without an explicit distribution decision.
