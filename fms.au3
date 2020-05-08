#pragma compile(Out, fms.exe)
#pragma compile(FileDescription, Flight Management System)
#pragma compile(ProductName, Flight Management System Primary cFS Application)
#pragma compile(ProductVersion, 1.0)
#pragma compile(FileVersion, 1.0) ; The last parameter is optional.
#pragma compile(LegalCopyright, © Darren Long)
#pragma compile(LegalTrademarks, 'Darren Long')
#pragma compile(CompanyName, 'Darren Long')

; FMS Variables...
Local Const $conf = @ScriptDir & "\config.ini"
Global Const $phproot = @ScriptDir & "\" & IniRead($conf, "php", "root", "php")
Global $PingHost = IniRead($conf, "ping", "timeout", "www.ask.com")
Global $PingTimeout = IniRead($conf, "ping", "timeout", 250)
Global $Missionalt = IniRead($conf, "mission", "targetalt", "")
Global $Landalt = IniRead($conf, "mission", "landalt", "")
Local Const $missionnm = IniRead($conf, "mission", "name", "Unknown")
Global $outtemp, $intemp, $alt, $idlealt, $prevalt, $fmsState = 0, $reset = False
Local Const $RefreshRate = IniRead($conf, "mission", "refresh", 1000)
Global Const $afmsState[7] = ["IDLE", "TAKEOFF", "CLIMB", "CRUISE", "DESCEND", "LAND", "TERMINATE"]
Global $cap = "", $avi = "", $user = ""
Global $tCount = 0
Global $tCameraInterval = IniRead($conf, "mission", "camerainterval", 10)
Global $datalog = @ScriptDir & "\" & IniRead($conf, "php", "root", "php") & "\datalog.html"
Local $bootlog = $phproot & "\bootlog.html"
Global $maxalt = $phproot & "\maxalt.html"
Global $datacsv = $phproot & "\data.csv"
Global $writecsv
Local $phpconfig = @ScriptDir & "\QuickPHP.ini"

; Write mission to file...
If FileExists(@ScriptDir & "\" & $phproot & "\mission.txt") Then
	FileDelete(@ScriptDir & "\" & $phproot & "\mission.txt")
EndIf
FileWrite(@ScriptDir & "\" & $phproot & "\mission.txt", $missionnm)

; Delete data log file...
If FileExists($datalog) Then
	FileDelete($datalog)
EndIf

; Delete boot log file...
If FileExists($bootlog) Then
	FileDelete($bootlog)
EndIf

; Write max altitude file...
If FileExists($maxalt) Then
	FileDelete($maxalt)
EndIf
FileWrite($maxalt, "<a href=""#"">Awaiting Launch</a>" & @CRLF)

; Delete previous FMS state files...
If FileExists($phproot & "\terminate.txt") Then
	FileDelete($phproot & "\terminate.txt")
EndIf
If FileExists($phproot & "\cruise.txt") Then
	FileDelete($phproot & "\cruise.txt")
EndIf

; Move previous data csv file to repository and create new...
If FileExists($datacsv) Then
	FileCopy($datacsv, $phproot & "\repository\data_" & StringFormat("%02d", @MDAY) & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%04d", @YEAR) & "_" & StringFormat("%02d", @HOUR) & "-" & StringFormat("%02d", @MIN) & "-" & StringFormat("%02d", @SEC) & ".csv")
	FileDelete($datacsv)
EndIf
FileWriteLine($datacsv, "DATE,TIME,FMS_STATE,OUTTEMP,INTEMP,ALT,BATT,EXEC_TIME")

; Write Quick PHP config file (alternately use a different PHP server)
If FileExists($phpconfig) Then
	FileDelete($phpconfig)
EndIf
Local $phpconfigOpen = FileOpen($phpconfig, 1)
FileWrite($phpconfigOpen, "[QuickPHP]" & @CRLF)
FileWrite($phpconfigOpen, "Menu=""MainMenu1""" & @CRLF)
FileWrite($phpconfigOpen, "edBindAddr.Text=""" & IniRead($conf, "php", "ip", "127.0.0.1") & """" & @CRLF)
FileWrite($phpconfigOpen, "cbAllowDirList.Checked=""1""" & @CRLF)
FileWrite($phpconfigOpen, "edPort.Text=""" & IniRead($conf, "php", "port", "80") & """" & @CRLF)
FileWrite($phpconfigOpen, "edRoot.Text=""" & $phproot & "\""" & @CRLF)
FileWrite($phpconfigOpen, "edDefaultFileName.Text=""index.php;index.html""" & @CRLF)
FileWrite($phpconfigOpen, "edPhpMaxTime.Text=""10""" & @CRLF)
FileWrite($phpconfigOpen, "menuSuppressConfirm.Checked=""0""" & @CRLF)
FileWrite($phpconfigOpen, "menuShowTrayIcon.Checked=""1""" & @CRLF)
FileClose($phpconfigOpen)

; Start Quick PHP...
If Not ProcessExists("QuickPHP.exe") Then
	Local $phppid = Run(@ScriptDir & "\QuickPHP.exe /start", "", @SW_HIDE)
	If Not $phppid = 0 Then
		FileWriteLine($bootlog, "PHP PID:" & $phppid & @CRLF)
	Else
		FileWriteLine($bootlog, "PHP failed to start" & @CRLF)
	EndIf
Else
	FileWriteLine($bootlog, "PHP already running" & @CRLF)
EndIf

; Setup webcam capture...
$gui = GUICreate("Webcam UDF Test", 640, 480)
WebcamInit()
Webcam($gui, 640, 480, 0, 0)
GUISetState(@SW_HIDE)
Sleep(2000)

; Start FMS loop...
While $reset = False
	FlightManagement()
	Sleep($RefreshRate)
WEnd

; Shut down / Restart FMS...
WebcamStop()
If $reset = True Then
	RestartScript()
EndIf

; FMS functions...

Func FlightManagement()
	Local $hTimer = TimerInit()
	If FileExists($phproot & "\terminate.txt") Then
		$fmsState = 6
		FileDelete($phproot & "\terminate.txt")
		$writecsv = 1
	ElseIf FileExists($phproot & "\cruise.txt") Then
		$fmsState = 3
		$writecsv = 1
	ElseIf Round($alt) <= Round($idlealt) Then
		If Not IsDeclared("takeoff") Then
			$fmsState = 0
		Else
			$fmsState = 5
		EndIf
		$writecsv = 0
	ElseIf Round($alt) <= $Landalt Then
		$fmsState = 5
		$writecsv = 0
	ElseIf Round($alt) > Round($prevalt) Then
		If Not IsDeclared("takeoff") Then
			$fmsState = 1
			Assign("takeoff", True)
			$writecsv = 1
		Else
			$fmsState = 2
			$writecsv = 1
		EndIf
	ElseIf Round($alt) = Round($prevalt) Then
		$fmsState = 3
		$writecsv = 1
	ElseIf Round($alt) < Round($prevalt) Then
		$fmsState = 4
		$writecsv = 1
	EndIf
	$prevalt = $alt
	Local $tafont1, $tafont2
	If $alt >= $Missionalt Then
		$tafont1 = "<font style=""color:#0f0;"">"
		$tafont2 = "</font>"
		ConsoleWrite("MISSION TARGET ALTITUDE REACHED" & @CRLF)
	Else
		$tafont1 = ""
		$tafont2 = ""
	EndIf
	If $reset = True Then
		ConsoleWrite("RESET" & @CRLF)
	EndIf
	If FileExists($datalog) Then
		FileDelete($datalog)
	EndIf
	Local $opencsv = FileOpen($datacsv, 1)
	Switch $fmsState
		Case 0
			ConsoleWrite($afmsState[0] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[0] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
		Case 1
			Photo("10", $alt, 1)
			ConsoleWrite($afmsState[1] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[1] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
			FileWrite($opencsv, StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & "," & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "," & $afmsState[1] & "," & $outtemp & "," & $intemp & "," & $alt & "," & BattStat())
		Case 2
			Photo("10", $alt, 1)
			ConsoleWrite($afmsState[2] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[2] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
			FileWrite($opencsv, StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & "," & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "," & $afmsState[2] & "," & $outtemp & "," & $intemp & "," & $alt & "," & BattStat())
		Case 3
			Photo("10", $alt, 1)
			ConsoleWrite($afmsState[3] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[3] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
			FileWrite($opencsv, StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & "," & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "," & $afmsState[3] & "," & $outtemp & "," & $intemp & "," & $alt & "," & BattStat())
		Case 4
			Photo("10", $alt)
			ConsoleWrite($afmsState[4] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[4] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
			FileWrite($opencsv, StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & "," & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "," & $afmsState[4] & "," & $outtemp & "," & $intemp & "," & $alt & "," & BattStat())
		Case 5
			ConsoleWrite($afmsState[5] & @CRLF)
			If Not ProcessExists("encoder.exe") And WebStat($PingHost, $PingTimeout) = 0 Then
				Run(@ScriptDir & "\encoder.exe [1=" & $outtemp & "/2=" & $intemp & "/3=" & $alt & "]")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: " & $afmsState[5] & "<br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
		Case 6
			ConsoleWrite($afmsState[6] & @CRLF)
			If ProcessExists("QuickPHP.exe") Then
				ProcessClose("QuickPHP.exe")
			EndIf
			FileWrite($datalog, "Date / Time: " & StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & " " & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "<br>FMS State: <font style=""color:#f00;"">" & $afmsState[6] & "</font><br>Outside Temp: " & $outtemp & "<br>Inside Temp: " & $intemp & "<br>" & $tafont1 & "Altitude: " & $alt & $tafont2 & "<br>Battery: " & BattStat() & @CRLF)
			FileWrite($opencsv, StringFormat("%02d", @MDAY) & "/" & StringFormat("%02d", @MON) & "/" & StringFormat("%04d", @YEAR) & "," & StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & "." & StringFormat("%02d", @SEC) & "," & $afmsState[6] & "," & $outtemp & "," & $intemp & "," & $alt & "," & BattStat() & "," & Round(TimerDiff($hTimer), 3))
			$reset = False
			Exit
	EndSwitch
	Local $fDiff = TimerDiff($hTimer)
	If $writecsv = 1 Then
		FileWrite($opencsv, "," & Round($fDiff, 3) & @CRLF)
	EndIf
	FileClose($opencsv)
	ConsoleWrite("Execution Time " & $fDiff)
EndFunc   ;==>FlightManagement

Func RestartScript()
	If @Compiled = 1 Then
		Run(FileGetShortName(@ScriptFullPath))
	Else
		Run(FileGetShortName(@AutoItExe) & " " & FileGetShortName(@ScriptFullPath))
	EndIf
	Exit
EndFunc   ;==>RestartScript

Func Photo($thresh, $data, $maw = 0)
	Local $snapfile, $snapstamp
	$tCount += 1
	If $tCount = $tCameraInterval Then
		$snapstamp = StringFormat("%02d", @MDAY) & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%04d", @YEAR) & "_" & StringFormat("%02d", @HOUR) & "-" & StringFormat("%02d", @MIN) & "-" & StringFormat("%02d", @SEC) & "_" & $data & ".bmp"
		$snapfile = $phproot & "\camera\" & $snapstamp
		DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x0000043D, "int", 0, "int", 0)
		DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x00000419, "int", 0, "str", $snapfile)
		ConsoleWrite("Photo taken")
		$tCount = 0
		If $maw = 1 Then
			FileDelete($maxalt)
			FileWrite($maxalt, "<a href=""\camera\" & $snapstamp & """ target=""_blank"">" & $snapstamp & "</a>" & @CRLF)
		EndIf
	EndIf
EndFunc   ;==>Photo

Func Webcam($gui, $w, $h, $l, $t)
	$cap = DllCall($avi, "int", "capCreateCaptureWindow", "str", "cap", "int", BitOR(0x40000000, 0x10000000), "int", $l, "int", $t, "int", $w, "int", $h, "hwnd", $gui, "int", 1)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x0000040A, "int", 0, "int", 0)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x00000435, "int", 1, "int", 0)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x00000433, "int", 1, "int", 0)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x00000432, "int", 1, "int", 0)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x00000434, "int", 1, "int", 0)
EndFunc   ;==>Webcam

Func WebcamInit()
	$avi = DllOpen("avicap32.dll")
	$user = DllOpen("user32.dll")
EndFunc   ;==>WebcamInit

Func WebcamStop()
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x000004B5, "int", 0, "int", 0)
	DllCall($user, "int", "SendMessage", "hWnd", $cap[0], "int", 0x0000040B, "int", 0, "int", 0)
	DllClose($user)
	DllClose($avi)
EndFunc   ;==>WebcamStop

Func WebStat($addy, $refresh)
	Local $sP = Ping($addy, $refresh)
	Local $eP = @error
	If $sP > 0 Then
		ConsoleWrite("internet online, time=" & $sP & "ms.")
		Return 1
	Else
		ConsoleWrite("internet offline, error=" & $eP)
		Return 0
	EndIf
EndFunc   ;==>WebStat

Func BattStat()
	Local $tSYSTEM_POWER_STATUS = DllStructCreate('byte ACLineStatus;byte BatteryFlag;byte BatteryLifePercent;byte Reserved1;' & 'int BatteryLifeTime;int BatteryFullLifeTime')
	Local $aRet = DllCall('kernel32.dll', 'bool', 'GetSystemPowerStatus', 'struct*', $tSYSTEM_POWER_STATUS)
	If @error Or Not $aRet[0] Then Return "Unknown"
	Return DllStructGetData($tSYSTEM_POWER_STATUS, 3)
EndFunc   ;==>BattStat
