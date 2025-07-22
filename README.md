# Prism - macOS AI Service Aggregator

複数のAIサービスを一つの便利なmacOSアプリで統合。効率的なAI作業フローを実現します。

![Prism Interface](screenshot.png)

## 🌟 特徴

- **複数AI統合**: ChatGPT、Gemini、Claude、カスタムAIサービスをひとつのアプリで
- **並行処理**: Parallelモードで複数AIに同時質問・回答比較
- **OCR機能**: 画面キャプチャしたテキストを自動認識
- **画像処理**: スクリーンショットをAIに送信して分析
- **オートフィル**: プロンプト自動入力でスムーズな作業
- **バックグラウンド動作**: メニューバーから素早くアクセス
- **カスタマイズ**: 独自AIサービスの追加・設定

## 💾 システム要件

- **OS**: macOS 15.4+
- **アーキテクチャ**: Apple Silicon (M1/M2) または Intel
- **メモリ**: 8GB RAM推奨

## 🚀 インストール

### GitHub Releases（推奨）

1. [Releases](https://github.com/remon-nomer66/macos-multi-ai-hub/releases)から最新版をダウンロード
2. `Prism.dmg`をマウントしてアプリケーションフォルダにドラッグ
3. 初回起動時は「システム環境設定 > セキュリティとプライバシー」で許可が必要

### ソースからビルド

```bash
git clone https://github.com/remon-nomer66/macos-multi-ai-hub.git
cd macos-multi-ai-hub
open Prism.xcodeproj
```

Xcode 16.3+でビルド・実行してください。

## 📱 使用方法

### 基本操作

1. **起動**: メニューバーのPrismアイコンをクリック
2. **AIサービス選択**: ChatGPT、Gemini、Claudeタブから選択
3. **プロンプト入力**: 下部のテキストフィールドに質問を入力
4. **送信**: Enterキーまたは送信ボタンでAIに質問

### OCR機能

1. **OCR**ボタンをクリック
2. キャプチャしたい画面領域を選択
3. 認識されたテキストが自動でプロンプトフィールドに入力

### 画像キャプチャ

1. **📷**ボタンでスクリーンショット撮影
2. 撮影した画像は下部のサムネイル表示
3. AIがテキストと画像を同時に分析

### 並行処理（Parallelモード）

1. **Parallel**ボタンを有効化
2. プロンプト送信で全AIサービスに同時質問
3. 各AIの回答を比較・検討

### カスタムAIサービス

1. 設定画面からカスタムサービスを追加
2. API URL、認証情報を設定
3. 独自のAIサービスを統合利用

## ⚙️ 設定オプション

- **自動起動**: システム起動時の自動起動設定
- **APIキー**: 各AIサービスのAPIキー管理
- **プロキシ**: ネットワークプロキシ設定
- **ショートカット**: キーボードショートカットのカスタマイズ

## 🛠 技術仕様

- **フレームワーク**: SwiftUI
- **最小システム**: macOS 15.4
- **アーキテクチャ**: Universal (Intel & Apple Silicon)
- **Web技術**: WKWebView
- **画像処理**: Vision Framework (OCR)
- **ネットワーク**: URLSession


## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 🐛 問題報告

バグや機能要望は[Issues](https://github.com/remon-nomer66/macos-multi-ai-hub/issues)にご報告ください。
