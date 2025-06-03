property printerIP : "printerIPaddress"
property adminPassword : "password"
-- property printerDriverModel : "Library/Printers/PPDs/Contents/Resources/SHARP MX-M565FN.PPD.gz"
property printerDriverModel : "Library/Printers/PPDs/Contents/Resources/SHARP BP-30M28.PPD.gz"

-- No initial dialog

set printerQueueName to "MONOA5"

try
	set printerDisplayName to "MONOA5"
	set deviceURI to "ipp://" & printerIP & "/ipp/print"
	
	set command to "echo " & quoted form of adminPassword & " | sudo -S lpadmin -p " & quoted form of printerQueueName & ¬
		" -E" & ¬
		" -v " & quoted form of deviceURI & ¬
		" -m " & quoted form of printerDriverModel & ¬
		" -D " & quoted form of printerDisplayName
	
	do shell script command
	
	-- No success dialog for silent version
	
on error errMsg number errNum
	if errNum is -128 then
		display dialog "User cancelled the administrator password prompt. Printer '" & printerQueueName & "' was not added." with title "Operation Cancelled" buttons {"OK"} default button "OK"
	else
		display dialog "Error adding '" & printerQueueName & "' printer (Model: " & printerDriverModel & "): " & errMsg & " (Error Code: " & errNum & ")" & return & return & ¬
			"Possible issues:" & return & ¬
			"- Incorrect IP address: " & printerIP & return & ¬
			"- Printer not found or not responding." & return & ¬
			"- PPD specified (" & printerDriverModel & ") could not be used (e.g., file missing, corrupted, or permissions issue)." & return & ¬
			"- CUPS service error." with title "Printer Addition Error" buttons {"OK"} default button "OK"
	end if
end try