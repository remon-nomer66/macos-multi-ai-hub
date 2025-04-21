import SwiftUI

struct ServiceSelectorView: View {
    @Binding var selectedService: AIService
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AIService.allCases) { service in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedService = service
                    }
                } label: {
                    Text(service.displayName)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .foregroundColor(selectedService == service ? .white : .primary)
                        .background(
                            ZStack {
                                if selectedService == service {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accentColor)
                                        .matchedGeometryEffect(id: "selector", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
