import SwiftUI

struct PromptInputView: View {
    @Binding var promptText: String
    @State private var isEditing = false
    private let maxHeight: CGFloat = 60
    
    // Command+Enter時のコールバック
    var onAutofill: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.bubble")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("プロンプト入力")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("⌘+Enter で自動入力")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .opacity(0.8)
                if !promptText.isEmpty {
                    Text("\(promptText.count) 文字")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isEditing ? Color.blue.opacity(0.3) : Color.white.opacity(0.2),
                                        isEditing ? Color.blue.opacity(0.1) : Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isEditing ? 1.5 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isEditing)
                
                if promptText.isEmpty && !isEditing {
                    Text("メッセージを入力してください...")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                
                TextEditor(text: $promptText)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .onTapGesture {
                        isEditing = true
                    }
                    .onSubmit {
                        isEditing = false
                    }
                    .onKeyPress(.return, phases: .down) { keyPress in
                        // Command+Enterキーの検出
                        if keyPress.modifiers.contains(.command) {
                            print("🚀 Command+Enter detected - triggering autofill")
                            onAutofill?()
                            return .handled
                        }
                        return .ignored
                    }
            }
            .frame(minHeight: 35, maxHeight: maxHeight)
        }
    }
}
