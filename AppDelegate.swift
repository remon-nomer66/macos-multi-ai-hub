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
        
        // バックグラウンド実行の設定
        setupBackgroundExecution()

        // ホットキーマネージャーの設定
        setupHotKeyManager()

        // メニューバーアイコンの作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Apple HIG準拠のメニューバーアイコン実装
            if let customIcon = NSImage(named: "MenuBarIcon") {
                button.image = customIcon
                button.image?.isTemplate = true
                print("✅ MenuBarIcon loaded successfully")
            } else {
                // フォールバック: SF Symbols使用
                button.image = NSImage(systemSymbolName: "diamond.fill", accessibilityDescription: "Prism AI")
                button.image?.isTemplate = true
                print("⚠️ MenuBarIcon not found, using fallback")
            }
            
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
    
    // MARK: - HotKey Setup
    private func setupHotKeyManager() {
        HotKeyManager.shared.setHotKeyCallback { [weak self] in
            print("🔥 Global hotkey activated - toggling popover")
            
            // メインスレッドでポップオーバーを操作
            DispatchQueue.main.async {
                if let button = self?.statusItem.button {
                    self?.togglePopover(button)
                }
            }
        }
        
        print("✅ HotKey manager configured")
    }
    
    // MARK: - Background Execution Setup
    private func setupBackgroundExecution() {
        print("🔄 Setting up background execution for AI services...")
        
        // アプリケーションレベルでのバックグラウンド実行設定
        NSApp.delegate = self
        
        // 自動終了を無効化（バックグラウンドで動作し続ける）
        if #available(macOS 10.7, *) {
            NSApp.disableRelaunchOnLogin()
        }
        
        // アプリがバックグラウンドに移行しても処理を継続
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("📱 App resigned active - maintaining background execution")
            // アプリがバックグラウンドに移行しても何もしない（継続実行）
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("📱 App became active - resuming foreground operations")
        }
        
        // ウィンドウが閉じられてもアプリを終了しない
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🪟 Window closing - maintaining app execution")
            // ウィンドウが閉じられてもアプリは終了しない
        }
        
        print("✅ Background execution setup completed")
    }
    
    // アプリケーションの終了処理をカスタマイズ
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // メニューバーアプリなので、ウィンドウが閉じられてもアプリは終了しない
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Dockアイコンがクリックされた場合の処理（ただし、このアプリはDockアイコンを隠している）
        if !flag {
            if let button = statusItem.button {
                togglePopover(button)
            }
        }
        return true
    }
}
