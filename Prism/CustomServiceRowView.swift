import SwiftUI

struct CustomServiceRowView: View {
    @State private var service: CustomAIService
    @State private var isExpanded = false
    
    let onUpdate: (CustomAIService) -> Void
    let onDelete: () -> Void
    
    init(service: CustomAIService, onUpdate: @escaping (CustomAIService) -> Void, onDelete: @escaping () -> Void) {
        self._service = State(initialValue: service)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    if !service.url.isEmpty {
                        Text(service.url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if service.isValid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("基本設定")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("サービス名 (10文字以内)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("例: MyAI", text: $service.name)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: service.name) { _, newValue in
                                        if newValue.count > 10 {
                                            service.name = String(newValue.prefix(10))
                                        }
                                        onUpdate(service)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("サービスURL")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("例: https://example.com/chat", text: $service.url)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: service.url) { _, _ in
                                        onUpdate(service)
                                    }
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        Button("削除") {
                            onDelete()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}