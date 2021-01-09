; Purpose:  This contains utility functions which can be used by the regression tests.

#include-once
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <ColorConstants.au3>
#include <Array.au3>

$sBindAddr = ""  ; Binding address for the NIC card

; Get the current working directory.  This is the test-center directory.
; From there, compute location of other directories relative to this.
RunWait(@ComSpec & " /c " & "cd > dir.log")
$sTestDir = FileRead(".\dir.log")
$sTestDir = StringReplace($sTestDir, " ", "")
$sTestDir = StringReplace($sTestDir, @CRLF, "")
FileDelete("dir.log")

; Location of TeraTerm and Python files
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe "   ; TeraTerm exe file
$sPython = "C:\Python27\python.exe "                           ; Python exe file

$sLogDir = $sTestDir & "\logs\"                   ; log directory
$sDripScripts = $sTestDir & "\DripScripts\"        ; DRIP scripts directory
$sTtlDir = $sTestDir & "\TtlScripts\"            ; TeraTerm scripts directory
$sDripClientDir = $sTestDir & "\DripClient\"    ; Drip Client directory

$sWaitTTL = $sTtlDir & "wait.ttl"
$sWaitLog = $sLogDir & "wait.log"
$sAstTTL = $sTtlDir & "ast.ttl"                ; ttl file for running the ast command
$sAstLog = $sLogDir & "ast.log"               ; log file for the ast command
$sCmdDrip = $sDripScripts & "cmd.drip"      ; Drip file for running a command
$sCmdLog = $sLogDir & "cmd.log"               ; Drip cmd log file
$sPyDrip = $sDripClientDir & "DripClient.py"               ; Python DRIP Client program
$sWinDrip = $sDripClientDir & "DRIP_client_5.5.exe"      ; Windows DRIP Client program

$sIpAddress = ""
$sComPort = ""                ; e.g., COM1
$sCodeVer = ""                ; e.g., DSR830 sprint04 70.09e
$sSITSpreadsheet = ""
Global $sVctId = ""

Global $aTestArray

; Purpose:  To get the list of com ports on the PC and set the GUI box.
Func UpdateComPortList($hComPort)
	; Get List of ComPorts
	RunWait(@ComSpec & " /c " & "mode > com_ports.log", "", @SW_HIDE)
	FileCopy("com_ports.log", $sLogDir, $FC_OVERWRITE + $FC_CREATEPATH)
	$lComPorts = FindAllStringsInFile("Status for device COM", "com_ports", -4)
	FileDelete("com_ports.log")
	GUICtrlSetData($hComPort, "|Com Port|" & $lComPorts, "Com Port")
EndFunc   ;==>UpdateComPortList


; Purpose: To get the list of NIC cards on the PC for choosing the binding address for DRIP.
Func UpdateBindingList($hBindAddr)
	; Get List of IP Addresses for binding.
	RunWait(@ComSpec & " /c " & "ipconfig > ip_addr.log", "", @SW_HIDE)
	FileCopy("ip_addr.log", $sLogDir, $FC_OVERWRITE + $FC_CREATEPATH)
	$lIpAddr = FindAllStringsInFile("IPv4 Address. . . . . . . . . . . :", "ip_addr", 0)
	FileDelete("ip_addr.log")
	GUICtrlSetData($hBindAddr, "|Binding Address|" & $lIpAddr, "Binding Address")
EndFunc   ;==>UpdateBindingList

;Purpose:  To handle hotkeys.
; Note: ALT+x will exit
Func HandleHotKey()
	Switch @HotKeyPressed ; The last hotkey pressed.

		Case "!x" ; String is the Shift-Alt-d hotkey.
			$idButton = MsgBox($MB_OKCANCEL + $MB_SYSTEMMODAL, "", "Program will exit.")
			If $idButton == $IDOK Then
				Exit
			EndIf

	EndSwitch
EndFunc   ;==>HandleHotKey


; Purpose:  Open the serial log files to look at.  Useful in case there is a reboot.
Func OpenLogFiles()
	Run(@ComSpec & " /c " & $sLogDir & 'DvrSerial.log')
	Run(@ComSpec & " /c " & $sLogDir & 'VcoSerial.log')
EndFunc   ;==>OpenLogFiles


; Purpose:  Find the box version information.
Func FindBoxVer($hBoxVersion)
	If $sIpAddress == "" Or $sBindAddr == "" Then
		ConsoleWrite("IP Address = " & $sIpAddress & ", Bind Address = " & $sBindAddr & @CRLF)
	Else
		Local $aVersion[2] = [ _
				"wait:1000; diag:A,2,1", _ ; Diag A, line 2, column 1, e.g., NepVer = DSR830 sprint04 70.08e
				"wait:1000; sea:ALL"] ; Pause for a second
		MakeCmdDrip($aVersion)      ; Make cmd.drip file to be run with Drip.
		RunDripTest("cmd")            ; Run cmd.drip
		$sCodeVer = GetStringInFile("NepVer = ", "cmd", 0, -1)
		$sCodeVer = StringReplace($sCodeVer, "NepVer = ", "")
		ConsoleWrite("sCodeVer = " & $sCodeVer & @CRLF)
		GUICtrlSetData($hBoxVersion, $sCodeVer)
		If StringInStr($sCodeVer, "DSR800 ") Then
			$sSITSpreadsheet = $sTestDir & "\docs\Gomesia_800.txt"
		ElseIf StringInStr($sCodeVer, "DSR830 ") Then
			$sSITSpreadsheet = $sTestDir & "\docs\Gomesia_830.txt"
		Else
			$sSITSpreadsheet = $sTestDir & "\docs\Gomesia_830_p2.txt"
		EndIf
		_FileReadToArray($sSITSpreadsheet, $aTestArray, $FRTA_NOCOUNT, @TAB)
		If @error <> 0 Then
			MsgBox($MB_SYSTEMMODAL, "Error opening file and creating array", $sSITSpreadsheet)
		EndIf
	EndIf
EndFunc   ;==>FindBoxVer


; Purpose:  Gets the VCT_ID.  Useful for VCO and SD channel tests based on the VCT_ID.
; Found on Diag A, line 5, column 3, e.g.,  VCT_ID = 4380
Func GetVctId()
	If $sIpAddress == "" Or $sBindAddr == "" Then
		ConsoleWrite("IP Address = " & $sIpAddress & ", Bind Address = " & $sBindAddr & @CRLF)
	Else
		$sVctId = GetDiagData("A,5,3", "VCT_ID")
		ConsoleWrite("Diag A VCT_ID = " & $sVctId & @CRLF)
	EndIf
EndFunc   ;==>GetVctId


; Purpose:  Get Diagnostics information
; DiagScreenLineItem - Something like "A,5,2" for Diag A, Line 5, Item 2, or just "A", or "A,5"
; ItemName - Something like "NumChannels" which is the name of the item as reported to the Drip Client
; Returns a string with the value.
Func GetDiagData($sDiagScreenLineItem, $sItemName)
	MakeRmtCmdDrip("diag:" & $sDiagScreenLineItem, 1000)
	RunDripTest("cmd")
	Local $sValue = FindNextStringInFile($sItemName, "cmd")
	Return $sValue
EndFunc   ;==>GetDiagData


; Purpose:  Search for a string, and return a string +/- it's position, of specified length
; sWhichString - The string to search for
; sWhichTest - The .log file
; iOffset - The starting offset from the beginning of the string
; iLength - The length of the string to be returned (-1 means rest of string)
; Returns a string of specified offset from beginning of search string and with specified length
Func GetStringInFile($sWhichString, $sWhichTest, $iOffset, $iLength)
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	Local $sRetString = ""
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindStringInFile FileRead error " & @error & ",  " & $sLogFile & @CRLF)
	Else
		Local $iPosition = StringInStr($sRead, $sWhichString)
		$sRetString = StringMid($sRead, $iPosition + $iOffset, $iLength)
	EndIf
	Return ($sRetString)
EndFunc   ;==>GetStringInFile


; Purpose:  Display the test spreadsheet with final results.
Func DisplayTestSummary()
	;SaveTestResult("A/V Presentation.Audio:001-003", "Passed")
	_ArrayDisplay($aTestArray, "DSR8xx Regression Test Plan", "", 64, 0, "Level|Test Case|Case Description|Results")
EndFunc   ;==>DisplayTestSummary


; Purpose:  To put up Pass/Fail/Running criteria in appropriate color.
; sWhichString - usually "pass", "fail", or "running"
; whichColor - color for the string
; hWhichBox_pf - handle for the pass/fail box to print in
Func PF_Box($sWhichString, $whichColor, $hWhichBox_pf)
	GUICtrlSetData($hWhichBox_pf, $sWhichString)
	GUICtrlSetColor($hWhichBox_pf, $whichColor)
EndFunc   ;==>PF_Box


; Purpose:  Display Pass/Fail on the PF_Box.
; bPass - True if pass
Func DisplayPassFail($bPass, $hWhichBox_pf)
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $hWhichBox_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $hWhichBox_pf)
	EndIf
EndFunc   ;==>DisplayPassFail


; Purpose:  This will run a Drip script and test the log file for a certain word.
;           First, check if the test should be run.
;           If so, then put up "running ..." and run the test.
;           Look for specified string in output file to determine pass/fail.
; sWhichTest - refers to the .drip script filename
; sWhichString - is the pass/fail string to search for
; sTestTitle - can be anything, just for display purposes
; hTestSummary - box which holds the test summary
; hTestBox - is the display box next to the checkbox
Func RunTestCriteria($sWhichTest, $sWhichString, $sTestTitle, $hTestSummary, $hTestBox)
	RunDripTest($sWhichTest)
	;ConsoleWrite("Looking for " & $sWhichString & @CRLF)
	$bPassFail = TestForString($sWhichTest, $sWhichString, $sTestTitle, $hTestSummary, $hTestBox)
	Return ($bPassFail)
EndFunc   ;==>RunTestCriteria


; Purpose:  If the given string is found, put "passed" in the test summary.
; sWhichString - The string to search for
; sWhichTest - The .log file to search in
; sTestTitle - Any name, will be echoed to the screen
; hTestSummary - box which holds the test summary
; hTestBox - is the display box next to the checkbox
Func TestForString($sWhichTest, $sWhichString, $sTestTitle, $hTestSummary, $hTestBox)
	Local $bPassFail = False
	If FindStringInFile($sWhichString, $sWhichTest) Then
		GUICtrlSetData($hTestSummary, $sTestTitle & ": Passed")
		$bPassFail = True
	Else
		GUICtrlSetData($hTestSummary, $sTestTitle & ": Failed")
		GUICtrlSetColor($hTestBox, $COLOR_RED)
	EndIf
	Return ($bPassFail)
EndFunc   ;==>TestForString


; Purpose:  Save the test result into the array.
; sTestCase - String to search for, e.g., "Closed Caption.608_708:001-001"
; sTestResult - String to put in the Results column, e.g., "Passed"
Func SaveTestResult($sTestCase, $sTestResult)
	Local $iIndex = _ArraySearch($aTestArray, $sTestCase, 0, 0, 0, 0, 1, 1)
	If @error == 0 Then
		$aTestArray[$iIndex][3] = $sTestResult
	Else
		ConsoleWrite("Row " & $iIndex & "  error " & @error & @CRLF)
	EndIf
EndFunc   ;==>SaveTestResult


; Purpose:  Run 'ifconfig', and get the ip address.
; hBoxIPAddress - handle for text box display
Func FindBoxIPAddress($hBoxIPAddress)
	MakeAstTtl("ifconfig", 1)  ; make the "ifconfig" command, 1 second timeout in case of no response.
	RunAstTtl()
	$sIpAddress = FindNextStringInFile("inet addr", "ast")
	GUICtrlSetData($hBoxIPAddress, $sIpAddress)
EndFunc   ;==>FindBoxIPAddress

; Purpose:  Run the Drip test on the box.
; sWhichTest - Name of the .drip file, e.g., 'cmd'
Func RunDripTest($sWhichTest)
	; Run the specified test.
	If $sIpAddress == "" Then
		MsgBox($MB_SYSTEMMODAL, "IP Address of Box", "Does not exist")
	ElseIf $sBindAddr == "" Then
		MsgBox($MB_SYSTEMMODAL, "Binding Address of Network Card", "Does not exist")
	Else
		Local $sLogFile = $sLogDir & $sWhichTest & ".log"
		Local $sTestFile = $sDripScripts & $sWhichTest & ".drip"
		Local $sTestCommand = $sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $sIpAddress & _
				" /f " & $sTestFile & " /o " & $sLogFile
		FileDelete($sLogFile)
		RunWait($sTestCommand, "", @SW_HIDE)    ; Run the test (minimized).
		;RunWait($sTestCommand, "")				; Run the test (show Python box).
	EndIf
EndFunc   ;==>RunDripTest


; Purpose:  Run the Drip command on the box and immediately continue on.
; Note:  This is useful with the RunWaitTtl() function.
Func RunDripCmdNoLog()
	; Run the specified test.
	If $sIpAddress == "" Then
		MsgBox($MB_SYSTEMMODAL, "IP Address of Box", "Does not exist")
	ElseIf $sBindAddr == "" Then
		MsgBox($MB_SYSTEMMODAL, "Binding Address of Network Card", "Does not exist")
	Else
		Local $sTestFile = $sDripScripts & "cmd.drip"
		Local $sTestCommand = $sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $sIpAddress & _
				" /f " & $sTestFile
		RunWait($sTestCommand, "", @SW_HIDE)    ; Run the test (minimized).
		;RunWait($sTestCommand, "")				; Run the test (show Python box).
	EndIf
EndFunc   ;==>RunDripCmdNoLog


; Purpose:  Run the DRIP Client 5.5 for Windows.
Func RunDripClient55()
	Run($sWinDrip & " /b " & $sBindAddr & " /i " & $sIpAddress)
EndFunc   ;==>RunDripClient55


; Purpose: To find a string in a file and pass back its position.
; Note: Returns 0 if not found.
; sWhichString - The string to search for
; sWhichTest - The .log file to search in
Func FindStringInFile($sWhichString, $sWhichTest)
	Local $iPosition = 0
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindStringInFile FileRead error " & @error & ",  " & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $sWhichString)
		ConsoleWrite("Position = " & $iPosition & ", test = " & $sWhichTest & ", string = " & $sWhichString & @CRLF)
	EndIf
	Return ($iPosition)
EndFunc   ;==>FindStringInFile


; Purpose: To find a set of strings in a file.  An array is passed back with the
; the next word after the string (separated by space or :), + or - the position indicated.
; For example, a position of 0 would mean the next word immediately after the search string.
; A position of -3 and a search string of "device COM" would go back 3 characters and would
; return the string "COM4", for instance.
; Useful for finding all com ports or all IP addresses of system.
; sWhichString - The string to search for
; sWhichTest - The .log file to search in
; iOffset - Number of characters after or before end of string to skip
; Returns an array of strings.
Func FindAllStringsInFile($sWhichString, $sWhichTest, $iOffset)
	Local $iPosition = 1, $sChop = " ", $sNextWord = "", $aSplit = [], $lStrings = ""
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	Local $sRead = FileRead($sLogFile)

	If @error Then
		ConsoleWrite("FindStringInFile FileRead error " & @error & ",  " & $sLogFile & @CRLF)
	Else
		; Loop through sRead searching for all sWhichString
		While $iPosition
			$iPosition = StringInStr($sRead, $sWhichString)
			If $iPosition Then
				$sRead = StringTrimLeft($sRead, $iPosition + StringLen($sWhichString) + $iOffset)
				$aSplit = StringSplit($sRead, " :=" & @CRLF) ; Array of strings where spaces and colons are separators

				If $aSplit[0] Then
					$sNextWord = $aSplit[1]
					$lStrings = $lStrings & $sNextWord & "|"
				EndIf
			EndIf
		WEnd
	EndIf
	Return ($lStrings)
EndFunc   ;==>FindAllStringsInFile


; Purpose: To search for a string, if found return the next string after it.
; Note:  Useful for returning a value given by the stats commands.
; sWhichString - which string to search for
; sWhichTest - which .log file to search in
Func FindNextStringInFile($sWhichString, $sWhichTest)
	$sNextWord = FindNthStringInFile($sWhichString, $sWhichTest, 1)
	Return $sNextWord
EndFunc   ;==>FindNextStringInFile


; Purpose: To search for a string, if found return the Nth string after it.
; Note:  Useful for returning a value given by the stats commands.
; sWhichString - which string to search for
; sWhichTest - which .log file to search in
; iWhichOne - 1 for the next string, 2 to skip one, etc.
Func FindNthStringInFile($sWhichString, $sWhichTest, $iWhichOne)
	Local $iPosition = 0, $sChop = " ", $sNextWord = "", $aSplit = []
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindNextStringInFile FileRead error " & @error & "," & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $sWhichString)
		If $iPosition Then
			$sChop = StringTrimLeft($sRead, $iPosition + StringLen($sWhichString))
			$aSplit = StringSplit($sChop, " :=" & @CRLF)  ; Array of strings where spaces and colons are separators
			$iWhichOne = $iWhichOne + 1 ; Skip the first element in the array (the original searched-for word)
			If $aSplit[0] > $iWhichOne Then
				Local $aNewArray[] = []
				For $sItem In $aSplit
					If $sItem <> "" Then
						_ArrayAdd($aNewArray, $sItem)
					EndIf
				Next
				$sNextWord = $aNewArray[$iWhichOne]
			Else
				ConsoleWrite("No split")
			EndIf
		Else
			ConsoleWrite("Did not find string " & $sWhichString & " in file" & @CRLF)
		EndIf
	EndIf
	;ConsoleWrite($sNextWord & @CRLF)
	Return $sNextWord
EndFunc   ;==>FindNthStringInFile


; Purpose: Returns true if the checkbox is checked.
; hControlID - handle for the checkbox
Func _IsChecked($hControlID)
	Return BitAND(GUICtrlRead($hControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked


; Purpose: Creates ast.ttl file to be run.
; Note:  This will be run by a TeraTerm session.
; sAstCmd - The command to be run, e.g., "ast CcStats"
; timeout - Just in case 'Done' never happens (in seconds)
Func MakeAstTtl($sAstCmd, $timeout)
	$hFilehandle = FileOpen($sAstTTL, $FO_OVERWRITE + $FO_CREATEPATH)
	;ConsoleWrite("file open " & $sAstTTL)
	If FileExists($sAstTTL) Then
		FileWrite($hFilehandle, "timeout = " & $timeout & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'wait "#"' & @CRLF)
		FileWrite($hFilehandle, "sendln " & ' "' & $sAstCmd & '"' & @CRLF)
		FileWrite($hFilehandle, 'wait "Done"' & @CRLF)
		FileWrite($hFilehandle, "closett" & @CRLF)
		FileWrite($hFilehandle, "end" & @CRLF)
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sAstTTL, "Does not exist")
	EndIf
EndFunc   ;==>MakeAstTtl

; Purpose: Creates the wait.ttl file to be run.
; Note:  This will be run by a TeraTerm session.
; sWaitCmd - The string to wait for, e.g., "TRANSPORT_LOCKED"
; timeout - Just in case the string never happens (in seconds)
Func MakeWaitTtl($aWaitStrings, $timeout = 90)
	$hFilehandle = FileOpen($sWaitTTL, $FO_OVERWRITE + $FO_CREATEPATH)
	If FileExists($sWaitTTL) Then
		FileWrite($hFilehandle, "timeout = " & $timeout & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'wait "#"' & @CRLF)
		Local $iSize = UBound($aWaitStrings)
		For $i = 0 To $iSize - 1
			FileWrite($hFilehandle, "wait " & ' "' & $aWaitStrings[$i] & '"' & @CRLF)
		Next
		FileWrite($hFilehandle, "closett" & @CRLF)
		FileWrite($hFilehandle, "end" & @CRLF)
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sWaitTTL, "Does not exist")
	EndIf
EndFunc   ;==>MakeWaitTtl

; Purpose:  Creates cmd.drip file to be run with a single Drip command.
; Note:  This will be run by a Drip session.
; sDripCmd - Drip command, e.g., "rmt:SKIP_BACK"
; timeout - 1000 means one second
Func MakeRmtCmdDrip($sDripCmd, $timeout)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:1000; send:1,53" & @CRLF)   ; Turn on unsolicited messages
		FileWrite($hFilehandle, "wait:1000; " & $sDripCmd & @CRLF)  ; The particular command we want to send
		FileWrite($hFilehandle, "wait:" & $timeout & "; sea:all" & @CRLF)  ; Wait for a bit, possibly to collect logs
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>MakeRmtCmdDrip

; Purpose: Creates cmd.drip file for single command.  Will not collect log file.
Func MakeDripCmdNoLog($sDripCmd)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:1000; " & $sDripCmd & @CRLF)  ; The particular command we want to send
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>MakeDripCmdNoLog

; Purpose:  Creates cmd.drip file to be run with Drip.
; Note:  This currently holds a maximum of 7 entries.
; aDripCmd - Array of Drip commands, e.g., "wait:500; rmt:SKIP_BACK"
Func MakeCmdDrip($aDripCmd)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:500; send:1,53" & @CRLF)           ; Turn on unsolicited messages
		Local $iSize = UBound($aDripCmd)
		For $i = 0 To $iSize - 1
			FileWrite($hFilehandle, $aDripCmd[$i] & @CRLF)
		Next
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>MakeCmdDrip


; Channel change to a particular channel.
; sKey - The three key commands, e.g. 'rmt:DIGIT0' for '0'
Func ChanChangeDrip($sKey1, $sKey2, $sKey3)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Open and delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:500; " & $sKey1 & @CRLF)
		FileWrite($hFilehandle, "wait:500; " & $sKey2 & @CRLF)
		FileWrite($hFilehandle, "wait:500; " & $sKey3 & @CRLF)
		FileWrite($hFilehandle, "wait:6000; sea:all" & @CRLF)  ; Wait 6 seconds for chan change to be done
		FileClose($hFilehandle)
		RunDripTest("cmd")
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>ChanChangeDrip


; Purpose: Run TeraTerm and collect a serial log file.
; bShow - True if you want the serial port session to be displayed
; Notes: Useful for collecting logs in case the system reboots.
;        Only one TeraTerm session per com port can be run at any given time.
;        To end, use WinKill("COM").
Func CollectSerialLogs($sWhichTest, $bShow)
	Local $sWhichLog = $sLogDir & $sWhichTest & ".log" ; log file
	FileDelete($sWhichLog)
	If $bShow Then
		Run($sTeraTerm & " /C=" & $sComPort & " /W=" & $sWhichTest & " /L=" & $sWhichLog)
	Else
		Run($sTeraTerm & " /C=" & $sComPort & " /W=" & $sWhichTest & " /L=" & $sWhichLog, "", @SW_MINIMIZE)
	EndIf
EndFunc   ;==>CollectSerialLogs


; Purpose: Run TeraTerm with the ast.ttl macro and save to ast.log
Func RunAstTtl()
	FileDelete($sAstLog)      ; Delete ast.log
	RunWait($sTeraTerm & " /C=" & $sComPort & " /W=" & "COM_" & $sComPort & " /M=" & $sAstTTL & " /L=" & $sAstLog, "", @SW_MINIMIZE)
EndFunc   ;==>RunAstTtl


; Purpose: Run TeraTerm with the wait.ttl macro and save to wait.log
Func RunWaitTtl()
	FileDelete($sWaitLog)      ; Delete wait.log
	RunWait($sTeraTerm & " /C=" & $sComPort & " /W=" & "COM_" & $sComPort & " /M=" & $sWaitTTL & " /L=" & $sWaitLog, "", @SW_MINIMIZE)
EndFunc   ;==>RunWaitTtl
