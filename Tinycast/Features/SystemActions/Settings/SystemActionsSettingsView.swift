import SwiftUI

struct SystemActionsSettingsView: View {
    var body: some View {
        Form {
            LauncherItemsSection(
                kind: .systemAction,
                header: String(localized: "System Actions"),
                searchPrompt: String(localized: "Search system actions…"))
        }
        .formStyle(.grouped)
        .releasesFocusOnOutsideClick()
    }
}
