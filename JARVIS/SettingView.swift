import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TabView {
                // ■ Setting タブ
                VStack(alignment: .leading, spacing: 20) {
                    Text("ウィンドウサイズ")
                        .font(.headline)
                    Picker("ウィンドウサイズ", selection: $settings.windowSize) {
                        ForEach(SettingsStore.WindowSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    Spacer()
                }
                .padding()
                .tabItem { Text("Setting") }

                // ■ Donation タブ
                DonationView()
                    .tabItem { Text("Donation") }
            }
            .frame(width: 400, height: 300)

            Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}
