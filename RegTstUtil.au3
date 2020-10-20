; Purpose:  This contains utility functions which can be used by the regression tests.

#include-once
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <ColorConstants.au3>
#include <Array.au3>


$sBindAddr = ""  ; Binding address for the NIC card

RunWait(@ComSpec & " /c " & "echo %USERPROFILE% > logs\userprofile.log")
$sUserProfile = FileRead(".\logs\userprofile.log")
$sUserProfile = StringReplace($sUserProfile, " ", "")
$sUserProfile = StringReplace($sUserProfile, @CRLF, "")

; Location of files
$sTestCenter = $sUserProfile & "\Documents\GitHub\test-station"
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe "   ; TeraTerm exe file
$sPython = "C:\Python27\python.exe "                           ; Python exe file

$sLogDir = $sTestCenter & "\logs\"               ; log directory
$sDripScripts = $sTestCenter & "\DripScripts\"    ; DRIP scripts directory

$sAstTTL = $sTestCenter & "\ttl\ast.ttl"    ; ttl file for running the ast command
$sAstLog = $sLogDir & "ast.log"   ; log file
$sCmdDrip = $sDripScripts & "cmd.drip"      ; Drip file for running a single command
$sCmdLog = $sLogDir & "cmd.log"   ; log file
$sSITSpreadsheet = $sTestCenter & "\docs\Gomesia_CyclePlan_TestCases.txt"
$sPyDrip = $sTestCenter & "\DripClient.py"       ; Python DRIP Client program

ConsoleWrite("sCmdLog = " & $sCmdLog & @CRLF)
ConsoleWrite("sCmdDrip = " & $sCmdDrip & @CRLF)

$sIpAddress = ""

$iBoxNum = 0



Global $aTestArray
_FileReadToArray($sSITSpreadsheet, $aTestArray, $FRTA_NOCOUNT, @TAB)
If @error <> 0 Then
	MsgBox($MB_SYSTEMMODAL, "Error opening file and creating array", $sSITSpreadsheet)
EndIf

; Purpose:  Display the test spreadsheet with final results.
Func DisplayTestSummary()
	SaveTestResult("A/V Presentation.Audio:001-003", "Passed")
	_ArrayDisplay($aTestArray, "Master Regression Test Plan", "", 64, 0, "Box Type|Level|Test Case|Case Description|Results")
EndFunc   ;==>DisplayTestSummary


; Purpose:  To put up Pass/Fail/Running criteria in appropriate color.
; sWhichString - usually "pass", "fail", or "running"
; whichColor - color for the string
; hWhichBox_pf - handle for the pass/fail box to print in
Func PF_Box($sWhichString, $whichColor, $hWhichBox_pf)
	GUICtrlSetData($hWhichBox_pf, $sWhichString)
	GUICtrlSetColor($hWhichBox_pf, $whichColor)
EndFunc   ;==>PF_Box


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
	Local $bRunTest = False
	RunDripTest($sWhichTest)
	ConsoleWrite("Looking for " & $sWhichString & @CRLF)
	TestForString($sWhichString, $sWhichTest, $sTestTitle, $hTestSummary, $hTestBox)
	$bRunTest = True
	Return ($bRunTest)
EndFunc   ;==>RunTestCriteria


; Purpose:  If the given string is found, put "passed" in the test summary.
; sWhichString - The string to search for
; sWhichTest - The .log file to search in
; sTestTitle - Any name, will be echoed to the screen
; hTestSummary - box which holds the test summary
; hTestBox - is the display box next to the checkbox
Func TestForString($sWhichString, $sWhichTest, $sTestTitle, $hTestSummary, $hTestBox)
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
	Local $iIndex = _ArraySearch($aTestArray, $sTestCase, 0, 0, 0, 0, 1, 0)
	If @error == 0 Then
		$aTestArray[$iIndex][4] = $sTestResult
	Else
		ConsoleWrite("Row " & $iIndex & "  error " & @error & @CRLF)
	EndIf
EndFunc   ;==>SaveTestResult


; Purpose:  Run 'ifconfig', and get the ip address.
; hBoxIPAddress - handle for text box display
; $comPort - The com port number (i.e., serial port)
Func FindBoxIPAddress($hBoxIPAddress, $comPort)
	MakeAstTtl("ifconfig", 2)  ; make the "ifconfig" command, 2 second timeout in case of no response.
	RunAstTtl($comPort)
	$sIpAddress = FindNextStringInFile("inet addr", "ast")
	GUICtrlSetData($hBoxIPAddress, $sIpAddress)
EndFunc   ;==>FindBoxIPAddress


; Purpose:  Run the Drip test on the box.
; sWhichTest - Name of the .drip file, e.g., 'cmd'
Func RunDripTest($sWhichTest)
	; Run the specified test.
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	Local $sTestFile = $sDripScripts & $sWhichTest & ".drip"
	Local $sTestCommand = $sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $sIpAddress & _
			" /f " & $sTestFile & " /o " & $sLogFile
	ConsoleWrite($sTestCommand & @CRLF)
	FileDelete($sLogFile)
	ConsoleWrite("RunDripTest delete " & $sLogFile & @CRLF)
	RunWait($sTestCommand, "", @SW_HIDE)                           ; Run the test.
	ConsoleWrite($sTestCommand & @CRLF)
EndFunc   ;==>RunDripTest


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
				$aSplit = StringSplit($sRead, " :") ; Array of strings where spaces and colons are separators

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
	Local $iPosition = 0, $sChop = " ", $sNextWord = "", $aSplit = []
	Local $sLogFile = $sLogDir & $sWhichTest & ".log"
	ConsoleWrite("FindNextStringInFile Try to read " & $sLogFile & @CRLF)
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindNextStringInFile FileRead error " & @error & "," & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $sWhichString)
		If $iPosition Then
			$sChop = StringTrimLeft($sRead, $iPosition + StringLen($sWhichString))
			$aSplit = StringSplit($sChop, " :")  ; Array of strings where spaces and colons are separators

			If $aSplit[0] Then
				$sNextWord = $aSplit[1]
			EndIf
		EndIf
	EndIf
	ConsoleWrite($sNextWord & @CRLF)
	Return $sNextWord
EndFunc   ;==>FindNextStringInFile


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
	$hFilehandle = FileOpen($sAstTTL, $FO_OVERWRITE)
	ConsoleWrite("file open " & $sAstTTL)
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


; Purpose:  Creates cmd.drip file to be run with a single Drip command.
; Note:  This will be run by a Drip session.
; sDripCmd - Drip command, e.g., "rmt:SKIP_BACK"
; timeout - 1000 means one second
Func MakeRmtCmdDrip($sDripCmd, $timeout)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:300; send:1,53" & @CRLF)   ; Turn on unsolicited messages
		FileWrite($hFilehandle, "wait:1000; " & $sDripCmd & @CRLF)  ; The particular command we want to send
		FileWrite($hFilehandle, "wait:" & $timeout & "; sea:all" & @CRLF)  ; Wait for a bit, possibly to collect logs
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>MakeRmtCmdDrip



; Purpose:  Creates cmd.drip file to be run with Drip.
; Note:  This currently holds a maximum of 7 entries.
; aDripCmd - Array of Drip commands, e.g., "wait:500; rmt:SKIP_BACK"
Func MakeCmdDrip($aDripCmd)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:300; send:1,53" & @CRLF)           ; Turn on unsolicited messages
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
	ConsoleWrite("ChanChangeDrip" & @CRLF)
	$hFilehandle = FileOpen($sCmdDrip, $FO_OVERWRITE)  ; Open and delete any existing content
	If FileExists($sCmdDrip) Then
		FileWrite($hFilehandle, "wait:500; " & $sKey1 & @CRLF)
		FileWrite($hFilehandle, "wait:500; " & $sKey2 & @CRLF)
		FileWrite($hFilehandle, "wait:500; " & $sKey3 & @CRLF)
		FileWrite($hFilehandle, "wait:6000; sea:all" & @CRLF)  ; Wait 6 seconds for chan change to be done
		FileClose($hFilehandle)
		ConsoleWrite("Run the Drip Test with file " & $sCmdDrip & @CRLF)
		RunDripTest("cmd")
	Else
		MsgBox($MB_SYSTEMMODAL, $sCmdDrip, "Does not exist")
	EndIf
EndFunc   ;==>ChanChangeDrip


; Purpose: Run TeraTerm with the ast.ttl macro and save to ast.log
; comPort - The com port number (i.e., serial port)
Func RunAstTtl($comPort)
	FileDelete($sAstLog)      ; Delete ast.log
	RunWait($sTeraTerm & " /C=" & $comPort & " /W=" & "Box" & $iBoxNum & " /M=" & $sAstTTL & " /L=" & $sAstLog)
EndFunc   ;==>RunAstTtl
