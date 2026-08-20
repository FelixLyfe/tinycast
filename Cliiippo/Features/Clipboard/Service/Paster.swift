import AppKit
import Carbon.HIToolbox

enum Paster {
    /// Stamped on Cliiippo's synthetic keystrokes so they remain identifiable to the system.
    static let cliiippoEventTag: Int64 = 0x434C4950

    /// Covers the gap between `activate()` returning and the target app accepting a keystroke.
    private static let activationDelay: TimeInterval = 0.08

    /// Shorter: no activation to wait on, only the pasteboard write reaching the target's process.
    private static let directPostDelay: TimeInterval = 0.05

    /// Write the item and paste it into `previousApp`, activating it so ⌘V lands there.
    @MainActor @discardableResult
    static func paste(
        _ item: ClipboardItem, store: ClipboardStore, previousApp: NSRunningApplication?
    ) -> Bool {
        guard write(item, store: store) else { return false }
        previousApp?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + activationDelay) {
            postCommandV()
        }
        return true
    }

    /// Put the item on the pasteboard without pasting; the marker stops re-capture.
    @MainActor @discardableResult
    static func copy(_ item: ClipboardItem, store: ClipboardStore) -> Bool {
        write(item, store: store)
    }

    /// Paste into `app` without activating it, so the palette stays open.
    @MainActor @discardableResult
    static func pasteInPlace(
        _ item: ClipboardItem, store: ClipboardStore, into app: NSRunningApplication?
    ) -> Bool {
        guard write(item, store: store) else { return false }
        if let pid = app?.processIdentifier {
            DispatchQueue.main.asyncAfter(deadline: .now() + directPostDelay) {
                postCommandV(toPid: pid)
            }
        }
        return true
    }

    /// Whether anything was written; a vanished item leaves the pasteboard untouched.
    @MainActor @discardableResult
    private static func write(_ item: ClipboardItem, store: ClipboardStore) -> Bool {
        let pb = NSPasteboard.general
        switch item.kind {
        case .text:
            guard let text = item.text else { return false }
            pb.clearContents()
            pb.declareTypes([.string, ClipboardManager.internalType], owner: nil)
            pb.setString(text, forType: .string)
        case .image:
            guard let url = store.imageURL(for: item), let data = try? Data(contentsOf: url) else {
                return false
            }
            pb.clearContents()
            pb.declareTypes([.png, ClipboardManager.internalType], owner: nil)
            pb.setData(data, forType: .png)
        }
        pb.setData(Data(), forType: ClipboardManager.internalType)
        // The poller skips marked writes, so this is the only promotion point.
        store.promote(item)
        return true
    }

    /// Synthesize ⌘V, to `pid` alone when given, else through the system tap.
    @MainActor
    static func postCommandV(toPid pid: pid_t? = nil) {
        guard Permissions.ensureAccessibility() else { return }
        let source = CGEventSource(stateID: .combinedSessionState)

        let v = CGKeyCode(kVK_ANSI_V)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false)
        else { return }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.setIntegerValueField(.eventSourceUserData, value: cliiippoEventTag)
        up.setIntegerValueField(.eventSourceUserData, value: cliiippoEventTag)

        if let pid {
            down.postToPid(pid)
            up.postToPid(pid)
        } else {
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}
