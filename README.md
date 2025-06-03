# mac_printer_setting

macOSのプリンター設定を自動化するAppleScriptコレクションです。
Automatorで以下の順序で実行することで、プリンターの再設定を行います。

## 実行順序

1. `delete_printer.applescript`
   - 既存のプリンターをすべて削除します

2. `add_color_printer.applescript`
   - カラープリンター "COLOR" を追加します

3. `add_mono_printer.applescript`
   - モノクロプリンター "MONO" を追加します

4. `add_monoa5_printer.applescript`
   - A5対応モノクロプリンター "MONOA5" を追加します

5. `config_monoa5_a5.applescript`
   - MONOA5プリンターのA5プリセットを設定します

## 使用前の準備

1. 各スクリプトファイル内の以下の設定を環境に合わせて変更してください：
   - `printerIP`: プリンターのIPアドレス
   - `adminPassword`: 管理者パスワード

## 注意事項

- スクリプトの実行には管理者権限が必要です
- プリンターがネットワークに接続されていることを確認してください
- PPDファイルが正しくインストールされていることを確認してください
