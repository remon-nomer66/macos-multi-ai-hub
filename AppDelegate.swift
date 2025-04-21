import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ AppDelegate did finish launching")
        // Dock アイコンを隠してアクセサリアプリ化
        NSApp.setActivationPolicy(.accessory)

        // メニューバーアイコンの作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "brain.head.profile",
                accessibilityDescription: "AI Access"
            )
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // ポップオーバーの準備
        popover = NSPopover()
        popover.behavior = .transient
        let content = ContentView()
            .environmentObject(settings)
        popover.contentViewController = NSHostingController(rootView: content)
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            let size = settings.windowSize.size
            popover.contentSize = size

            // 画面内に収めるロジック
            if let screen = button.window?.screen {
                let visible = screen.visibleFrame
                let btnFrame = button.convert(button.bounds, to: nil)
                let below = visible.maxY - btnFrame.minY
                let above = btnFrame.minY - visible.minY
                let finalH = min(size.height, below)
                popover.contentSize.height = finalH

                if below >= finalH {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                } else if above >= finalH {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
