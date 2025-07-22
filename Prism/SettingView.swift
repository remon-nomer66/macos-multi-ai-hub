import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var customServiceManager: CustomAIServiceManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: SettingsTab = .general
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    
    enum SettingsTab: String, CaseIterable {
        case general = "一般"
        case services = "AIサービス"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .services: return "brain"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("閉じる") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if selectedTab == .general {
                        GeneralSettingsView()
                            .environmentObject(settings)
                    } else if selectedTab == .services {
                        CustomServicesView()
                            .environmentObject(customServiceManager)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: 600)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            hotKeySection
            Divider()
            windowSizeSection
            Divider()
            zoomScaleSection
        }
    }
    
    private var windowSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ウィンドウサイズ")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                windowSizeButton(.small)
                windowSizeButton(.medium)
                windowSizeButton(.large)
                windowSizeButton(.custom)
            }
            
            if settings.windowSize == .custom {
                customSizeSection
            }
        }
    }
    
    private func windowSizeButton(_ size: SettingsStore.WindowSize) -> some View {
        let isSelected = settings.windowSize == size
        
        return Button(action: {
            settings.windowSize = size
        }) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading) {
                    Text(size.displayName)
                        .font(.body)
                    
                    if size != .custom {
                        let width = Int(size.size.width)
                        let height = Int(size.size.height)
                        Text("\(width) × \(height)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
    
    private var customSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("カスタムサイズ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("最小サイズ: 300 × 600")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("幅")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("幅", value: $settings.tempCustomWindowWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: settings.tempCustomWindowWidth) { oldValue, newValue in
                            if newValue < 300 {
                                settings.tempCustomWindowWidth = max(newValue, 0) // 負の値は防ぐが制限は適用時に
                            }
                        }
                }
                
                Text("×")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("高さ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("高さ", value: $settings.tempCustomWindowHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: settings.tempCustomWindowHeight) { oldValue, newValue in
                            if newValue < 600 {
                                settings.tempCustomWindowHeight = max(newValue, 0) // 負の値は防ぐが制限は適用時に
                            }
                        }
                }
                
                Button("適用") {
                    settings.applyCustomWindowSize()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.leading, 20)
        .padding(.top, 8)
    }
    
    private var zoomScaleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("サイトの拡大率")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("リセット") {
                    settings.webViewZoomScale = 1.0
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            let currentPercentage = Int(settings.webViewZoomScale * 100)
            Text("現在の拡大率: \(currentPercentage)%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Slider(
                value: $settings.webViewZoomScale,
                in: 0.5...2.0,
                step: 0.1
            ) {
                Text("ズーム")
            } minimumValueLabel: {
                Text("50%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("200%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                zoomButton(0.75)
                zoomButton(1.0)
                zoomButton(1.25)
                zoomButton(1.5)
            }
        }
    }
    
    private func zoomButton(_ scale: Double) -> some View {
        let isSelected = abs(settings.webViewZoomScale - scale) < 0.01
        let percentage = Int(scale * 100)
        
        return Button("\(percentage)%") {
            settings.webViewZoomScale = scale
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
        )
        .foregroundStyle(isSelected ? .white : .primary)
    }
    
    // MARK: - HotKey Section
    private var hotKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("グローバルホットキー")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("アクセシビリティ許可") {
                    hotKeyManager.requestAccessibilityPermission()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
                .opacity(hotKeyManager.checkAccessibilityPermission() ? 0.5 : 1.0)
            }
            
            Text("メニューバーをクリックせずにPrismを開くためのキーボードショートカットを設定できます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(HotKeyOption.allCases) { option in
                    hotKeyButton(option)
                }
            }
        }
    }
    
    private func hotKeyButton(_ option: HotKeyOption) -> some View {
        let isSelected = hotKeyManager.selectedHotKey == option
        
        return Button(action: {
            hotKeyManager.selectedHotKey = option
        }) {
            HStack {
                // ラジオボタン
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                    )
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .fontWeight(.medium)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .strokeBorder(
                        isSelected ? Color.blue : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Services Tab
struct CustomServicesView: View {
    @EnvironmentObject var customServiceManager: CustomAIServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            
            if customServiceManager.customServices.isEmpty {
                emptyStateView
            } else {
                servicesListView
            }
            
            if customServiceManager.canAddMore {
                addServiceButton
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("カスタムAIサービス")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("最大3つまで")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.6))
            
            Text("カスタムAIサービスが設定されていません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("独自のAIサービスを追加して、より多くのAIと会話できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var servicesListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(customServiceManager.customServices.enumerated()), id: \.element.id) { index, service in
                    CustomServiceRowView(
                        service: service,
                        onUpdate: { updatedService in
                            customServiceManager.updateService(at: index, with: updatedService)
                        },
                        onDelete: {
                            customServiceManager.removeService(at: index)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var addServiceButton: some View {
        Button(action: {
            _ = customServiceManager.addService()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("新しいサービスを追加")
            }
            .font(.body)
            .fontWeight(.medium)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}