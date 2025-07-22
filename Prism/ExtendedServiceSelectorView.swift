import SwiftUI

struct ExtendedServiceSelectorView: View {
    let availableServices: [ExtendedAIService]
    @Binding var selectedService: ExtendedAIService
    @Namespace private var animation
    
    var body: some View {
        let displayServices = Array(availableServices.prefix(6))
        
        HStack(spacing: 4) {
            ForEach(displayServices, id: \.id) { service in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedService = service
                    }
                } label: {
                    let isSelected = selectedService.id == service.id
                    let horizontalPadding = service.isCustom ? 12.0 : 18.0
                    let buttonColor = service.isCustom ? Color.purple : Color.blue
                    
                    HStack(spacing: 4) {
                        if service.isCustom {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.yellow)
                        }
                        Text(service.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, horizontalPadding)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                buttonColor,
                                                buttonColor.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: buttonColor.opacity(0.3), radius: 4, x: 0, y: 2)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            // 現在選択されているサービスが利用可能なサービスに含まれていない場合、デフォルトを選択
            if !availableServices.contains(where: { $0.id == selectedService.id }) {
                if let firstService = availableServices.first {
                    selectedService = firstService
                }
            }
        }
        .onChange(of: availableServices) { _, newServices in
            // サービスリストが変更された場合の処理
            if !newServices.contains(where: { $0.id == selectedService.id }) {
                if let firstService = newServices.first {
                    selectedService = firstService
                }
            }
        }
    }
}