#NoTrayIcon
#pragma compile(Out, encoder.exe)
#pragma compile(FileDescription, Encoder for binary beep radio transmission)
#pragma compile(ProductName, 4bit Binary Radio Transmission Encoder cFS Application)
#pragma compile(ProductVersion, 1.0)
#pragma compile(FileVersion, 1.0) ; The last parameter is optional.
#pragma compile(LegalCopyright, © Darren Long)
#pragma compile(LegalTrademarks, 'Darren Long')
#pragma compile(CompanyName, 'Darren Long')

Local Const $conf = @ScriptDir & "\config.ini"
Global Const $frequency = IniRead($conf, "Encode", "Freq", 1000)
Global Const $length = IniRead($conf, "Encode", "Length", 100)
Global Const $gap = IniRead($conf, "Encode", "Gap", 100)
Global Const $pause = IniRead($conf, "Encode", "Pause", 1400)

If $CmdLine[0] == 1 Then
	Call("binfour", $CmdLine[1])
	Exit
EndIf

Func binfour($num)
	$num = StringReplace($num, " ", "P")
	$num = StringSplit($num, "")
	ConsoleWrite($num)
	For $i = 1 To $num[0]
		If $num[$i] = 1 Then
			ConsoleWrite("1")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = 2 Then
			ConsoleWrite("2")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = 3 Then
			ConsoleWrite("3")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = 4 Then
			ConsoleWrite("4")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = 5 Then
			ConsoleWrite("5")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = 6 Then
			ConsoleWrite("6")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = 7 Then
			ConsoleWrite("7")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = 8 Then
			ConsoleWrite("8")
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = 9 Then
			ConsoleWrite("9")
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = "P" Then
			ConsoleWrite("P")
			Sleep(1000)
		ElseIf $num[$i] = "=" Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = "[" Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = "." Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = "]" Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = "/" Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		ElseIf $num[$i] = "E" Then
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
			Beep($frequency, $length * 3)
			Sleep($gap)
		ElseIf $num[$i] = 0 Then
			ConsoleWrite("0")
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
			Beep($frequency, $length)
			Sleep($gap)
		EndIf
		Sleep($pause - $gap)
	Next
EndFunc   ;==>binfour
