import SwiftUI

struct PromptInputView: View {
    @Binding var promptText: String
    private let maxHeight: CGFloat = 80

    var body: some View {
        VStack(alignment: .trailing) {
            TextEditor(text: $promptText)
                .frame(minHeight: 30, maxHeight: maxHeight)
                .border(Color.gray.opacity(0.5), width: 1)
                .cornerRadius(5)

            .padding(.top, 4)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}
