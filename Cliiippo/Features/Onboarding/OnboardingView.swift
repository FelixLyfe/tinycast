import AppKit
import SwiftUI

/// One deliberate first-run page; capture starts only after the user presses Done.
struct OnboardingView: View {
    static let windowSize = CGSize(width: 540, height: 470)

    @Environment(AppCore.self) private var core
    @State private var importFromTinycast = false
    @State private var importing = false
    @State private var errorMessage: String?

    private var canOfferImport: Bool {
        TinycastClipboardMigration.sourceExists && core.clipboardStore.isEmpty
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero
            OnboardingCard {
                OnboardingRow(
                    title: String(localized: "Clipboard history"),
                    subtitle: String(
                        localized: "Cliiippo records copied text and images after setup is complete."),
                    systemImage: "doc.on.clipboard", tint: .orange
                ) {
                    EmptyView()
                }
                OnboardingDivider()
                OnboardingRow(
                    title: String(localized: "Global shortcut"),
                    subtitle: String(localized: "Open clipboard history from any app."),
                    systemImage: "keyboard", tint: .blue
                ) {
                    ShortcutRecorder(action: .toggleClipboard)
                }
                OnboardingDivider()
                OnboardingRow(
                    title: String(localized: "Accessibility"),
                    subtitle: String(
                        localized: "Needed only when you paste an item into another app."),
                    systemImage: "accessibility", tint: .green
                ) {
                    Text("Requested on first paste")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if canOfferImport {
                    OnboardingDivider()
                    OnboardingRow(
                        title: String(localized: "Import from Tinycast"),
                        subtitle: String(
                            localized:
                                "Copies clipboard history and related settings. Tinycast data is left unchanged."
                        ),
                        systemImage: "arrow.down.doc", tint: .orange
                    ) {
                        Toggle("", isOn: $importFromTinycast)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(Theme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Theme.Colors.sheen, Color.clear],
                startPoint: .top, endPoint: .center)
        )
        .ignoresSafeArea()
        .shortcutRecorderPopoverHost()
        .onAppear { importFromTinycast = canOfferImport }
    }

    private var hero: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            Text("Welcome to Cliiippo")
                .font(.title2.weight(.bold))
            Text("A focused, local clipboard history for text and images.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            Text("Nothing is captured until you finish setup.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button {
                finish()
            } label: {
                if importing {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView().controlSize(.small)
                        Text("Importing…")
                    }
                } else {
                    Text("Done")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(importing)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func finish() {
        guard importFromTinycast, canOfferImport else {
            core.completeOnboarding()
            return
        }
        importing = true
        errorMessage = nil
        Task {
            defer { importing = false }
            do {
                _ = try await TinycastClipboardMigration.run(
                    store: core.clipboardStore, settings: core.settings)
                core.completeOnboarding()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
