// JARVISApp.swift
import SwiftUI

@main
struct JARVISApp: App {
    // ここで AppDelegate を登録
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // ウィンドウはいらないので PreferenceScene だけ設置
        Settings {
            EmptyView()
        }
    }
}
