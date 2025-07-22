import SwiftUI

struct ServiceSelectorView: View {
    @Binding var selectedService: AIService
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AIService.allCases) { service in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedService = service
                    }
                } label: {
                    Text(service.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .foregroundStyle(selectedService == service ? .white : .primary)
                        .background(
                            ZStack {
                                if selectedService == service {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue,
                                                    Color.blue.opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "selector", in: animation)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.clear)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
    }
}
