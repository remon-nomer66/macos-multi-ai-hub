// ApplePayButton.swift

import SwiftUI
import PassKit

struct ApplePayButton: NSViewRepresentable {
    let amount: Double

    func makeNSView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: .black)
        button.target = context.coordinator
        button.action = #selector(Coordinator.pay)
        return button
    }

    func updateNSView(_ nsView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(amount: amount)
    }

    class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        let amount: Double
        /// シート表示用に保持しておく非表示ウィンドウ
        private var hostWindow: NSWindow?

        init(amount: Double) {
            self.amount = amount
        }

        @objc func pay() {
            // 1) ダミーウィンドウを作成して保持
            let w = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                styleMask: [],
                backing: .buffered,
                defer: false
            )
            w.isOpaque = false
            w.backgroundColor = .clear
            // 画面外にオーダー（可視化はしない）
            w.setFrameOrigin(NSPoint(x: -1000, y: -1000))
            w.orderFrontRegardless()
            hostWindow = w

            // 2) Payment Request を作成
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.your.identifier"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .threeDSecure
            request.countryCode = "JP"
            request.currencyCode = "JPY"
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "寄付", amount: NSDecimalNumber(value: amount))
            ]

            // 3) コントローラを生成し、デリゲートをセット
            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self
            controller.present(completion: nil)
        }

        // MARK: - PKPaymentAuthorizationControllerDelegate

        /// presentationWindow(for:) で非 nullptr を返す
        func presentationWindow(for controller: PKPaymentAuthorizationController) -> NSWindow? {
            return hostWindow
        }

        func paymentAuthorizationController(
            _ controller: PKPaymentAuthorizationController,
            didAuthorizePayment payment: PKPayment,
            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
        ) {
            // 決済成功
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }

        func paymentAuthorizationControllerDidFinish(
            _ controller: PKPaymentAuthorizationController
        ) {
            // シートを閉じる
            controller.dismiss(completion: nil)
            // ダミーウィンドウを破棄
            hostWindow?.orderOut(nil)
            hostWindow = nil
        }
    }
}
