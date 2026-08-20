import SwiftUI

struct ApplicationsSettingsView: View {
    var body: some View {
        Form {
            // Scopes first: they decide what gets indexed, so they read before the results.
            SearchScopesSection()

            LauncherItemsSection(
                kind: .application,
                header: String(localized: "Applications"),
                searchPrompt: String(localized: "Search applications…"))
        }
        .formStyle(.grouped)
        .releasesFocusOnOutsideClick()
    }
}
