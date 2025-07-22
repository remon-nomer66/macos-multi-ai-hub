# Assets Directory

このディレクトリにはPrismアプリのスクリーンショットやその他のメディアファイルを配置します。

## スクリーンショットの追加方法

1. Prismアプリのスクリーンショットを撮影
2. 以下のコマンドで画像を保存：

```bash
# macOSのクリップボードから画像を保存
pbpaste > prism-screenshot.png

# または、ファイルをコピー
cp /path/to/your/screenshot.png prism-screenshot.png
```

3. Gitに追加：

```bash
git add assets/prism-screenshot.png
git commit -m "Add Prism app screenshot"
```

## 必要なファイル

- `prism-screenshot.png` - メインのアプリインターフェーススクリーンショット
- その他のメディアファイル (必要に応じて)