on run {input, paramaters}
	set adminPassword to item 1 of input
	set printerIP to item 2 of input
	
	try
		set printerQueueName to "COLOR"
		set printerDisplayName to "COLOR"
		set deviceURI to "ipp://" & printerIP & "/ipp/print"
		
		set command to "echo " & quoted form of adminPassword & " | sudo -S lpadmin -p " & quoted form of printerQueueName & " -E -v " & quoted form of deviceURI & " -m everywhere -D " & quoted form of printerDisplayName
		
		do shell script command
		
	on error errMsg number errNum
		if errNum is -128 then
			display dialog "User cancelled the administrator password prompt. Printer 'COLOR' was not added." with title "Operation Cancelled" buttons {"OK"} default button "OK"
		else
			display dialog "Error adding 'COLOR' printer (silently): " & errMsg & " (Error Code: " & errNum & ")" with title "Printer Addition Error" buttons {"OK"} default button "OK"
		end if
	end try
	
	repeat 50 times
		try
			set r to do shell script "lpstat -p " & quoted form of printerQueueName
			if r contains printerQueueName then exit repeat
		end try
		delay 0.5
	end repeat
end run