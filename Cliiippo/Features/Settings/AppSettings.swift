import SwiftUI

@MainActor
@Observable
final class AppSettings {
    @ObservationIgnored private let defaults = UserDefaults.standard
    private typealias Key = AppSettingsKey

    var clipboardRetention: ClipboardRetention {
        didSet {
            defaults.set(clipboardRetention.rawValue, forKey: Key.clipboardRetention.rawValue)
        }
    }

    var clipboardDisabledApps: [String] {
        didSet { defaults.set(clipboardDisabledApps, forKey: Key.clipboardDisabledApps.rawValue) }
    }

    var launchAtLogin: Bool {
        didSet { LaunchAtLogin.set(launchAtLogin) }
    }

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance.rawValue) }
    }

    var appLanguage: AppLanguage {
        didSet {
            defaults.set(appLanguage.rawValue, forKey: Key.appLanguage.rawValue)
            appLanguage.prepareForNextLaunch(in: defaults)
        }
    }

    init() {
        clipboardRetention =
            ClipboardRetention(rawValue: defaults.integer(forKey: Key.clipboardRetention.rawValue))
            ?? .threeMonths
        clipboardDisabledApps =
            defaults.stringArray(forKey: Key.clipboardDisabledApps.rawValue)
            ?? ["com.apple.keychainaccess", "com.apple.Passwords"]
        launchAtLogin = LaunchAtLogin.isEnabled
        appearance =
            defaults.string(forKey: Key.appearance.rawValue).flatMap(AppAppearance.init) ?? .system
        appLanguage = AppLanguage.saved(in: defaults)
    }

    /// Imports only clipboard-adjacent preferences from Tinycast's stable channel.
    func importTinycastPreferences() -> Int {
        guard let source = UserDefaults(suiteName: TinycastClipboardMigration.sourceBundleID) else {
            return 0
        }
        var imported = 0
        if let value = source.object(forKey: Key.clipboardRetention.rawValue) as? Int,
            let retention = ClipboardRetention(rawValue: value)
        {
            clipboardRetention = retention
            imported += 1
        }
        if let apps = source.stringArray(forKey: Key.clipboardDisabledApps.rawValue) {
            clipboardDisabledApps = apps
            imported += 1
        }
        if let value = source.string(forKey: Key.appearance.rawValue),
            let importedAppearance = AppAppearance(rawValue: value)
        {
            appearance = importedAppearance
            imported += 1
        }
        if let value = source.string(forKey: Key.appLanguage.rawValue),
            let language = AppLanguage(rawValue: value)
        {
            appLanguage = language
            imported += 1
        }
        return imported
    }
}
