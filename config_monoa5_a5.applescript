property targetPrinterName : "MONOA5"
property targetPresetName : "MONOA5_A5_Preset"
property targetPaperSizeName : "A5" -- 一般的な用紙サイズ名。正確な名前は exactA5PaperSizeName を使用
property exactA5PaperSizeName : "A5  148 x 210 mm" -- ダイアログ上の正確な表示名（空白2つに注意）

-- AXIdentifiers（Accessibility Inspector で確認した値）
property printerPopupAXID : "_NS:70" -- プリンタ選択ポップアップ
property paperSizePopupAXID : "_NS:42" -- 用紙サイズ選択ポップアップ
property presetsPopupAXID : "_NS:8" -- プリセット選択ポップアップ（「デフォルト設定」表示時）

global textEditLaunchedByScript
set textEditLaunchedByScript to false

try
	-- ① TextEdit を起動し、空のドキュメントを用意
	tell application "TextEdit"
		if not running then
			set textEditLaunchedByScript to true
			launch
			delay 2
		end if
		activate
		if not (exists document 1) then
			make new document
			delay 0.5
		end if
	end tell
	delay 1
	
	tell application "System Events"
		tell application process "TextEdit"
			set frontmost to true
			delay 0.5
			
			if not (exists window 1) then
				error "TextEdit のウィンドウが見つかりません。"
			end if
			set documentWindow to window 1
			
			-- Command+P でプリントダイアログを開く
			keystroke "p" using command down
			
			set printSheet to missing value
			repeat 20 times -- 最大10秒待機
				if exists sheet 1 of documentWindow then
					set printSheet to sheet 1 of documentWindow
					exit repeat
				end if
				delay 0.5
			end repeat
			
			if printSheet is missing value then
				error "プリントシートが見つかりませんでした。"
			end if
			
			tell printSheet
				-- ② プリンタを AXIdentifier で選択
				set allUIElementsOnSheet to entire contents
				set printerPopup to missing value
				repeat with anElement in allUIElementsOnSheet
					try
						if class of anElement is pop up button and (value of attribute "AXIdentifier" of anElement) is printerPopupAXID then
							set printerPopup to anElement
							exit repeat
						end if
					end try
				end repeat
				if printerPopup is missing value then
					error "プリンタ選択ポップアップボタン (AXID: " & printerPopupAXID & ") が見つかりません。"
				end if
				if value of printerPopup is not targetPrinterName then
					click printerPopup
					delay 0.7
					if not (exists menu item targetPrinterName of menu 1 of printerPopup) then
						key code 53
						error "プリンタ「" & targetPrinterName & "」がリストに見つかりません。"
					end if
					click menu item targetPrinterName of menu 1 of printerPopup
					delay 1.5
				end if
				
				-- ③ 既存のプリセットをすべて削除
				set presetsPopup to missing value
				-- プリセット選択ポップアップを取得
				repeat with anElement in allUIElementsOnSheet
					try
						if class of anElement is pop up button and (value of attribute "AXIdentifier" of anElement) is presetsPopupAXID then
							set presetsPopup to anElement
							exit repeat
						end if
					end try
				end repeat
				if presetsPopup is missing value then
					error "プリセットポップアップボタン (AXID: " & presetsPopupAXID & ") が見つかりません。"
				end if
				-- 「デフォルト設定」を選択
				if value of presetsPopup is not "デフォルト設定" then
					click presetsPopup
					delay 0.7
					if exists menu item "デフォルト設定" of menu 1 of presetsPopup then
						click menu item "デフォルト設定" of menu 1 of presetsPopup
						delay 1.5
					else
						key code 53
						error "「デフォルト設定」というメニュー項目が見つかりません。"
					end if
				end if
				-- プリセット編集メニューを開く
				click presetsPopup
				delay 0.7
				set editPresetsMenuItemFound to false
				if exists menu item "プリセットリストを編集…" of menu 1 of presetsPopup then
					click menu item "プリセットリストを編集…" of menu 1 of presetsPopup
					set editPresetsMenuItemFound to true
				else if exists menu item "Edit Preset List…" of menu 1 of presetsPopup then
					click menu item "Edit Preset List…" of menu 1 of presetsPopup
					set editPresetsMenuItemFound to true
				end if
				if not editPresetsMenuItemFound then
					error "「プリセットリストを編集…」メニュー項目が見つかりませんでした。"
				end if
				
				delay 1.5
				set editPresetsSheet to missing value
				repeat 10 times
					if exists sheet 1 of printSheet then
						set editPresetsSheet to sheet 1 of printSheet
						exit repeat
					end if
					delay 0.5
				end repeat
				if editPresetsSheet is missing value then
					error "プリセット編集シートが開きませんでした。"
				end if
				
				-- シートが二重になっている可能性を考慮：内部のシートを actualEditSheet として扱う
				set actualEditSheet to editPresetsSheet
				if exists sheet 1 of editPresetsSheet then
					set actualEditSheet to sheet 1 of editPresetsSheet
					delay 0.5
				end if
				
				tell actualEditSheet
					-- プリセット一覧のテーブル（またはアウトライン）を取得
					set presetsTable to missing value
					if exists table 1 of scroll area 1 then
						set presetsTable to table 1 of scroll area 1
					else if exists table 1 then
						set presetsTable to table 1
					else if exists outline 1 of scroll area 1 then
						set presetsTable to outline 1 of scroll area 1
					else if exists outline 1 then
						set presetsTable to outline 1
					else
						error "プリセット一覧のテーブル/アウトラインが見つかりません。"
					end if
					
					-- 「削除」ボタンを取得（buttons of actualEditSheet から AXIdentifier を確認）
					set deleteButton to missing value
					repeat with aBtn in (buttons of actualEditSheet)
						try
							if (value of attribute "AXIdentifier" of aBtn) is "_NS:8" then
								set deleteButton to aBtn
								exit repeat
							end if
						end try
					end repeat
					if deleteButton is missing value then
						error "削除ボタンが見つかりませんでした。AXIdentifier: _NS:8 を再確認してください。"
					end if
					
					-- 全行を削除
					set deletionCount to 0
					set maxDeletions to 50
					delay 0.5
					repeat while (exists row 1 of presetsTable) and (enabled of deleteButton) and deletionCount < maxDeletions
						try
							select row 1 of presetsTable
							delay 0.3
							if enabled of deleteButton then
								click deleteButton
								delay 0.6
								set deletionCount to deletionCount + 1
							else
								exit repeat
							end if
						on error
							exit repeat
						end try
					end repeat
					
					-- 編集シートを閉じる
					set doneButton to missing value
					if exists (button "OK") then
						set doneButton to button "OK"
					else if exists (button "完了") then
						set doneButton to button "完了"
					else if exists (button "Done") then
						set doneButton to button "Done"
					end if
					if doneButton is not missing value then
						click doneButton
						delay 1
					else
						key code 53 -- Escape キー
						delay 1
					end if
				end tell
				
				-- ④ 用紙サイズを AXIdentifier で選択
				set paperSizePopup to missing value
				repeat with anElement in allUIElementsOnSheet
					try
						if class of anElement is pop up button and (value of attribute "AXIdentifier" of anElement) is paperSizePopupAXID then
							set paperSizePopup to anElement
							exit repeat
						end if
					end try
				end repeat
				if paperSizePopup is missing value then
					error "用紙サイズポップアップボタン (AXID: " & paperSizePopupAXID & ") が見つかりません。"
				end if
				click paperSizePopup
				delay 0.7
				set paperSizeMenuItemFound to false
				if exists menu item exactA5PaperSizeName of menu 1 of paperSizePopup then
					click menu item exactA5PaperSizeName of menu 1 of paperSizePopup
					set paperSizeMenuItemFound to true
				else if exists menu item targetPaperSizeName of menu 1 of paperSizePopup then
					click menu item targetPaperSizeName of menu 1 of paperSizePopup
					set paperSizeMenuItemFound to true
				else if exists menu item "ISO A5" of menu 1 of paperSizePopup then
					click menu item "ISO A5" of menu 1 of paperSizePopup
					set paperSizeMenuItemFound to true
				end if
				if not paperSizeMenuItemFound then
					key code 53
					error "用紙サイズ「" & exactA5PaperSizeName & "」、「" & targetPaperSizeName & "」、または「ISO A5」が見つかりません。"
				end if
				delay 1.5
				
				-- ⑤ 新規プリセットを保存
				set presetsPopup to missing value
				repeat with anElement in allUIElementsOnSheet
					try
						if class of anElement is pop up button and (value of attribute "AXIdentifier" of anElement) is presetsPopupAXID then
							set presetsPopup to anElement
							exit repeat
						end if
					end try
				end repeat
				if presetsPopup is missing value then
					error "（保存用）プリセットポップアップボタンが見つかりません。"
				end if
				click presetsPopup
				delay 0.7
				
				set savePresetMenuItemNameJpn to "現在の設定をプリセットとして保存…"
				set savePresetMenuItemNameEng to "Save Current Settings as Preset…"
				set savePresetMenuItem to missing value
				if exists menu item savePresetMenuItemNameJpn of menu 1 of presetsPopup then
					set savePresetMenuItem to menu item savePresetMenuItemNameJpn of menu 1 of presetsPopup
				else if exists menu item savePresetMenuItemNameEng of menu 1 of presetsPopup then
					set savePresetMenuItem to menu item savePresetMenuItemNameEng of menu 1 of presetsPopup
				end if
				if savePresetMenuItem is missing value then
					key code 53
					error "「現在の設定をプリセットとして保存…」メニュー項目が見つかりません。"
				end if
				click savePresetMenuItem
				delay 1.5
				
				set savePresetSheet to missing value
				repeat 10 times
					if exists sheet 1 of printSheet then
						set savePresetSheet to sheet 1 of printSheet
						exit repeat
					end if
					delay 0.5
				end repeat
				if savePresetSheet is missing value then
					error "「プリセットを別名で保存」ダイアログシートが見つかりませんでした。"
				end if
				
				tell savePresetSheet
					if not (exists text field 1) then
						error "保存ダイアログにテキストフィールドが見つかりません。"
					end if
					try
						set value of attribute "AXFocused" of text field 1 to true
					on error
						-- フォーカス設定に失敗しても進める
					end try
					delay 0.3
					
					keystroke targetPresetName
					delay 0.5
					
					set saveButtonInDialog to missing value
					if exists button "保存" then
						set saveButtonInDialog to button "保存"
					else if exists button "Save" then
						set saveButtonInDialog to button "Save"
					else if exists button "OK" then
						set saveButtonInDialog to button "OK"
					end if
					if saveButtonInDialog is missing value then
						error "保存ダイアログの「保存」または「OK」ボタンが見つかりません。"
					end if
					click saveButtonInDialog
				end tell
				
				delay 1.5
				
				-- ⑥ 空印刷（Print ボタンをクリック）
				set printButtonNameJpn to "プリント"
				set printButtonNameEng to "Print"
				set finalPrintButton to missing value
				if exists button printButtonNameJpn then
					set finalPrintButton to button printButtonNameJpn
				else if exists button printButtonNameEng then
					set finalPrintButton to button printButtonNameEng
				end if
				
				if finalPrintButton is missing value then
					key code 53 -- Escape キーでダイアログ閉じ
				else
					click finalPrintButton
				end if
			end tell
		end tell
	end tell
	delay 1
	
	-- ⑦ TextEdit のクリーンアップ：ドキュメントを閉じてアプリを終了
	tell application "TextEdit"
		if exists document 1 then
			try
				close document 1 without saving
			end try
		end if
		if textEditLaunchedByScript and (count of documents) is 0 then
			quit
		end if
	end tell
	
	-- 最後に結果をダイアログで表示
	display dialog "プリンタ設定とプリセット登録、空印刷が完了しました。" buttons {"OK"} default button "OK" with title "完了"
	
on error errMsg number errNum
	display dialog "エラー: プリンタ設定中にエラーが発生しました。" & return & return & errMsg & " (エラーコード: " & (errNum as text) & ")" with title "プリンタ設定エラー" buttons {"OK"} default button "OK"
	try
		tell application "System Events"
			tell application process "TextEdit"
				if exists window 1 then
					if exists sheet 1 of window 1 then
						key code 53
						delay 0.5
					end if
				end if
			end tell
		end tell
		tell application "TextEdit"
			if exists document 1 then
				try
					close document 1 without saving
				end try
			end if
			if textEditLaunchedByScript and (count of documents) is 0 then
				quit
			end if
		end tell
	on error cleanupErr
		log "エラークリーンアップ中の追加エラー: " & cleanupErr
	end try
end try