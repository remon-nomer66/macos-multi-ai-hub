import SwiftUI

struct DonationView: View {
    // @State: Viewの状態を管理するためのプロパティラッパー
    @State private var selectedAmount: Double = 500 // 選択または入力された寄付金額 (初期値: 500)
    @State private var customAmount: String = ""    // 任意金額入力用のテキストフィールドの文字列

    var body: some View {
        VStack(spacing: 20) { // 垂直方向に要素を配置 (間隔: 20ポイント)
            Text("寄付する金額を選択")
                .font(.headline) // 見出しスタイル

            // 金額選択ボタン (水平方向に配置)
            HStack(spacing: 20) {
                Button("コーヒー ¥500") {
                    selectedAmount = 500
                    customAmount = "" // プリセット選択時に任意金額フィールドをクリア
                }
                Button("ラーメン ¥1000") {
                    selectedAmount = 1000
                    customAmount = "" // プリセット選択時に任意金額フィールドをクリア
                }
            }

            // 任意金額入力欄 (水平方向に配置)
            HStack {
                Text("任意金額: ¥")
                TextField("金額", text: $customAmount)
                    .frame(width: 80) // テキストフィールドの幅を固定
                    // --- ここが修正点 ---
                    // customAmountの値が変更されたときに実行されるアクション
                    .onChange(of: customAmount) { oldValue, newValue in
                        // newValue (新しい文字列) を Double 型に変換できたら
                        if let v = Double(newValue) {
                            // selectedAmount を更新
                            selectedAmount = v
                        } else if newValue.isEmpty {
                            // 入力フィールドが空になった場合は、選択金額を0にリセット
                            // これにより、Apple Payボタンが無効化される（後述の条件分岐のため）
                            selectedAmount = 0
                        }
                        // newValueが空でもなく、有効な数値でもない場合（例: "abc"）は、
                        // selectedAmount は変更せず、直前の有効な値を保持します。
                    }
            }

            // Apple Pay ボタン
            // selectedAmount が 0 より大きい場合のみ表示・有効化
            //if selectedAmount > 0 {
                //ApplePayButton(amount: selectedAmount)
                    //.frame(height: 44) // ボタンの高さを指定
            //} else {
                // 金額が0以下の場合は、代わりにメッセージを表示するか、
                // ボタンを無効状態で表示します（ここではメッセージを表示）。
                //Text("金額を選択または入力してください")
                    //.foregroundColor(.gray)
                    //.frame(height: 44) // 高さをボタンと合わせる
            //}


            Spacer() // 残りのスペースを埋めて、要素を上部に寄せる
        }
        .padding() // View全体にパディングを追加
    }
}
