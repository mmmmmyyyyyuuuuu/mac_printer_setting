property adminPassword : "password"

try
	set printerListCmd to "lpstat -e"
	set printerNamesText to ""
	
	try
		set printerNamesText to do shell script printerListCmd
	on error errMsgTmp number errNumTmp
		if errNumTmp is -128 then error number -128
		error "lpstat command failed: " & errMsgTmp number errNumTmp
	end try
	
	set printerNameArray to {}
	if printerNamesText is not "" then
		set normalizedText to printerNamesText
		set oldDelimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to {return & linefeed}
		set tempList to every text item of normalizedText
		set AppleScript's text item delimiters to {linefeed}
		set normalizedText to tempList as text
		set AppleScript's text item delimiters to {return}
		set tempList to every text item of normalizedText
		set AppleScript's text item delimiters to {linefeed}
		set normalizedText to tempList as text
		set AppleScript's text item delimiters to {linefeed}
		set tempLines to every text item of normalizedText
		set AppleScript's text item delimiters to oldDelimiters
		
		repeat with aLine in tempLines
			set currentLine to aLine as string
			if length of currentLine > 0 then
				if currentLine starts with " " then
					repeat while currentLine starts with " "
						set currentLine to text 2 thru -1 of currentLine
						if length of currentLine = 0 then exit repeat
					end repeat
				end if
				if length of currentLine > 0 and currentLine ends with " " then
					repeat while currentLine ends with " "
						set currentLine to text 1 thru -2 of currentLine
						if length of currentLine = 0 then exit repeat
					end repeat
				end if
				if length of currentLine > 0 then set end of printerNameArray to currentLine
			end if
		end repeat
	end if
	
	if (count of printerNameArray) > 0 then
		repeat with printerName in printerNameArray
			set currentPrinterName to printerName as string
			if currentPrinterName is not "" then
				try
					set deleteCmd to "echo " & quoted form of adminPassword & " | sudo -S lpadmin -x " & quoted form of currentPrinterName
					do shell script deleteCmd
					delay 0.05
				on error errMsgDel number errNumDel
					if errNumDel is -128 then error number -128
					if not (errMsgDel contains "プリンタまたはクラスは存在しません" or errMsgDel contains "printer or class does not exist") then
						error "Failed to delete " & quoted form of currentPrinterName & ": " & errMsgDel number errNumDel
					end if
				end try
			end if
		end repeat
	end if
	
on error errMsg number errNum
	if errNum is -128 then error "Operation cancelled by user." number -128
	error "Script error during printer deletion: " & errMsg number errNum
end try