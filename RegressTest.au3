#include <File.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>

#Region ### START Koda GUI section ### Form=
$Form1_1 = GUICreate("Regression Tests", 446, 379, 192, 124)
$HdmiSwitch = GUICtrlCreateGroup("HDMI Switch", 24, 8, 385, 57)
$HdmiBox1 = GUICtrlCreateRadio("Box1", 40, 32, 49, 17)
$HdmiBox2 = GUICtrlCreateRadio("Box2", 92, 32, 49, 17)
$HdmiBox3 = GUICtrlCreateRadio("Box3", 144, 32, 49, 17)
$HdmiBox4 = GUICtrlCreateRadio("Box4", 196, 32, 49, 17)
$HdmiBox5 = GUICtrlCreateRadio("Box5", 248, 32, 49, 17)
$HdmiBox6 = GUICtrlCreateRadio("Box6", 300, 32, 49, 17)
$HdmiBox7 = GUICtrlCreateRadio("Box7", 352, 32, 49, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$AllTests = GUICtrlCreateCheckbox("All Tests", 32, 88, 73, 17)
$Fingerprint = GUICtrlCreateCheckbox("Fingerprint", 32, 128, 81, 17)
$VCO = GUICtrlCreateCheckbox("VCO", 32, 152, 97, 17)
$ChannelChange = GUICtrlCreateCheckbox("Channel Change", 32, 176, 97, 17)
$ClosedCaptions = GUICtrlCreateCheckbox("Closed Captions", 32, 200, 97, 17)
$TrickPlay = GUICtrlCreateCheckbox("Trick Play", 32, 224, 97, 17)
$TestSummary = GUICtrlCreateLabel("Test Summary", 192, 96, 199, 257)
$RunTests = GUICtrlCreateButton("Run Tests", 32, 256, 75, 25)
$IP_Address = GUICtrlCreateLabel(" ", 208, 72, 7, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$sBindAddr = "192.168.1.156"  ; Binding address for the NIC card. Used for DRIP.

; Location of files
$sTestCenter = "C:\Users\dsr\Documents\GitHub\test-station"
;$sTestCenter = "."
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe "   ; TeraTerm exe file
$sPython = "C:\Python27\python.exe "                           ; Python exe file

$sLogDir = $sTestCenter & "\logs\"               ; log directory
$sDripScripts = $sTestCenter & "\DripScripts\"    ; DRIP scripts directory

$sAstTTL = $sTestCenter & "\ttl\ast.ttl"    ; ttl file for running the ast command
$sAstLog = $sTestCenter & "\logs\ast.log"   ; log file

$sPyDrip = $sTestCenter & "\DripClient.py"       ; Python DRIP Client program

$sTestSummary = "Test Summary" & @CRLF

$iComStart = 4  ; first com port
$iNumBoxes = 7
$iBoxNum = 0

$iHdmiCom = 1  ; Com port 1 for HDMI controller.

; Box IP Address, HDMI selector, and com port for test boxes on Test Rack 2
Global $aTestBoxes[7][3] = [ _
		["192.168.1.159", $HdmiBox1, 9], _
		["192.168.1.162", $HdmiBox2, 5], _
		["192.168.1.163", $HdmiBox3, 7], _
		["192.168.1.161", $HdmiBox4, 4], _
		["192.168.1.157", $HdmiBox5, 6], _
		["192.168.1.160", $HdmiBox6, 10], _
		["192.168.1.164", $HdmiBox7, 8]]

; Binding address
$iBindAddr = "192.168.1.156"


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $HdmiBox1
			;SwitchHdmiInput("sw i01" & @CRLF)
			RunWait(@ComSpec & " /c " & "echo sw i01 > COM1")
		Case $HdmiBox2
			SwitchHdmiInput("sw i02" & @CRLF)
		Case $HdmiBox3
			SwitchHdmiInput("sw i03" & @CRLF)
		Case $HdmiBox4
			SwitchHdmiInput("sw i04" & @CRLF)
		Case $HdmiBox5
			SwitchHdmiInput("sw i05" & @CRLF)
		Case $HdmiBox6
			SwitchHdmiInput("sw i06" & @CRLF)
		Case $HdmiBox7
			SwitchHdmiInput("sw i07" & @CRLF)

		Case $AllTests
			If _IsChecked($AllTests) Then
				GUICtrlSetState($Fingerprint, $GUI_CHECKED)
				GUICtrlSetState($VCO, $GUI_CHECKED)
				GUICtrlSetState($ChannelChange, $GUI_CHECKED)
				GUICtrlSetState($ClosedCaptions, $GUI_CHECKED)
				GUICtrlSetState($TrickPlay, $GUI_CHECKED)
			Else
				GUICtrlSetState($Fingerprint, $GUI_UNCHECKED)
				GUICtrlSetState($VCO, $GUI_UNCHECKED)
				GUICtrlSetState($ChannelChange, $GUI_UNCHECKED)
				GUICtrlSetState($ClosedCaptions, $GUI_UNCHECKED)
				GUICtrlSetState($TrickPlay, $GUI_UNCHECKED)
			EndIf

		Case $RunTests
			If FindBox() Then
				$sTestSummary = "Test Summary" & @CRLF
				GUICtrlSetData($TestSummary, $sTestSummary)

				RunTestCriteria("finger", "displayUA", "Fingerprint", $Fingerprint)
				RunTestCriteria("vco", "SEND LIVE PMT_CHANGED_EVENT (SVC NUM  = 788, CHANNEL = 166)", "VCO entry/exit", $VCO)
				If RunTestCriteria("chupdn", "SEND VIDEO_COMPONENT_START_SUCCESS", "Video", $ChannelChange) Then
					TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "chupdn", "Audio")
				EndIf

				If _IsChecked($ClosedCaptions) Then  ; If the closed captions box is checked
					ClosedCaptionTest()              ; then run the closed captions test
				EndIf

			Else
				MsgBox($MB_SYSTEMMODAL, "", "Which box not specified.")
			EndIf

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd


; Purpose:  First, check if the test should be run.
;           If so, then put up "running ..." and run the test.
;           Look for specified string in output file to determine pass/fail.
; Notes: sWhichTest refers to the .drip script filename
;        sWhichString is the pass/fail string to search for
;        sTestTitle can be anything, just for display purposes
;        hTestBox is the checkbox handle
Func RunTestCriteria($sWhichTest, $sWhichString, $sTestTitle, $hTestBox)
	Local $bRunTest = False
	If _IsChecked($hTestBox) Then
		GUICtrlSetData($TestSummary, $sTestSummary & @CRLF & $sTestTitle & ": Running ...")
		RunTest($sWhichTest)
		TestForString($sWhichString, $sWhichTest, $sTestTitle)
		$bRunTest = True
	EndIf
	Return ($bRunTest)
EndFunc   ;==>RunTestCriteria


Func TestForString($sWhichString, $sWhichTest, $sTestTitle)
	If FindStringInFile($sWhichString, $sWhichTest) Then
		$sTestSummary = $sTestSummary & @CRLF & $sTestTitle & ": Passed"
	Else
		$sTestSummary = $sTestSummary & @CRLF & $sTestTitle & ": Failed"
	EndIf
	GUICtrlSetData($TestSummary, $sTestSummary)
EndFunc   ;==>TestForString



; Purpose: Send command to control the HDMI switch.
Func SwitchHdmiInput($whichHdmiInput)
	If WinActivate("[CLASS:TMobaXtermForm]", "") Then
		If WinActivate("HDMISwitch", "") Then
			Send($whichHdmiInput)
		EndIf
	EndIf
EndFunc   ;==>SwitchHdmiInput


; Purpose: Find the marked HDMI input and save.
; Return:  True if found, False if not found.
Func FindBox()
	Local $bFoundIt = False
	For $i = 0 To $iNumBoxes - 1 Step 1
		If GUICtrlRead($aTestBoxes[$i][1]) == 1 Then
			$bFoundIt = True
			$iBoxNum = $i
			ExitLoop
		EndIf
	Next
	Return $bFoundIt
EndFunc   ;==>FindBox


; Purpose:  Run the Drip test on the specified box.
Func RunTest($whichTest)
	; Run the specified test.
	Local $sLogFile = $sLogDir & $whichTest & ".log"
	Local $sTestFile = $sDripScripts & $whichTest & ".drip"
	Local $sTestCommand = $sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $aTestBoxes[$iBoxNum][0] & _
			" /f " & $sTestFile & " /o " & $sLogFile
	ConsoleWrite($sTestCommand & @CRLF)
	;RunWait(@ComSpec & " /c " & "del " & $sLogFile)  ; Delete the log file.
	FileDelete($sAstLog)  ; Delete the log file.
	RunWait($sTestCommand)                           ; Run the test.
EndFunc   ;==>RunTest


; Purpose: To find a string in a file and pass back its position.
; Note: Returns 0 if not found.
Func FindStringInFile($whichString, $whichTest)
	Local $iPosition = 0
	Local $sLogFile = $sLogDir & $whichTest & ".log"
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindStringInFile FileRead error " & @error & "," & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $whichString)
		ConsoleWrite("Position = " & $iPosition & @CRLF)
	EndIf
	Return ($iPosition)
EndFunc   ;==>FindStringInFile


; Purpose: To search for a string, if found return the next string after it.
; Useful for returning a value given by the stats commands.
Func FindNextStringInFile($whichString, $whichTest)
	Local $iPosition = 0, $sChop = " ", $sNextWord = "", $aSplit = []
	Local $sLogFile = $sLogDir & $whichTest & ".log"
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FindNextStringInFile FileRead error " & @error & "," & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $whichString)
		If $iPosition Then
			$sChop = StringTrimLeft($sRead, $iPosition + StringLen($whichString))
			$aSplit = StringSplit($sChop, @CRLF)
			;ConsoleWrite("sChop = " & $sChop & ", aSplit[0] = " & $aSplit[0] & @CRLF)
			If $aSplit[0] Then
				$sNextWord = $aSplit[1]
			EndIf
		EndIf
	EndIf
	ConsoleWrite($sNextWord & @CRLF)
	Return $sNextWord
EndFunc   ;==>FindNextStringInFile


; Returns true if the checkbox is checked.
Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked


; Creates ast.ttl file to be run.
Func MakeAstTtl($whichString, $timeout)
	FileDelete($sAstLog)  ; Delete the log file.
	; Open file - deleting any existing content
	$hFilehandle = FileOpen($sAstTTL, $FO_OVERWRITE)
	If FileExists($sAstTTL) Then
		FileWrite($hFilehandle, "timeout = " & $timeout & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'sendln ""' & @CRLF)
		FileWrite($hFilehandle, 'wait "#"' & @CRLF)
		FileWrite($hFilehandle, "sendln " & ' "' & $whichString & '"' & @CRLF)
		FileWrite($hFilehandle, 'wait "Done"' & @CRLF)
		FileWrite($hFilehandle, "closett" & @CRLF)
		FileWrite($hFilehandle, "end" & @CRLF)
		FileClose($hFilehandle)
	Else
		MsgBox($MB_SYSTEMMODAL, $sAstTTL, "Does not exist")
	EndIf
EndFunc   ;==>MakeAstTtl


Func RunAstTtl()
	FileDelete($sAstLog)  ; Delete the log file.
	RunWait($sTeraTerm & " /C=" & $aTestBoxes[$iBoxNum][2] & " /W=" & "Box" & $iBoxNum & " /M=" & $sAstTTL & " /L=" & $sAstLog)
EndFunc   ;==>RunAstTtl


; Purpose:  To test closed captioning processing.
; Note:  This only tests if closed captions are being processed.  It does not
; First, test if cc is enabled.  Then turn on if needed.
; Finally, get counter data from two different timeperiods and compare them.
Func ClosedCaptionTest()
	ConsoleWrite("Running the Closed Caption Test" & @CRLF)

	Local $sCcCounter1 = ""
	Local $sCcCounter2 = ""
	GUICtrlSetData($TestSummary, $sTestSummary & @CRLF & "Closed Captions: Running ...")    ; Display test is running

	; Run the cc stats command to check if captions are on or off.
	MakeAstTtl("ast cc", 10)                            ; make the 'ast cc' command
	RunAstTtl()                                         ; run the 'ast cc' command and collect the log
	If FindStringInFile("Captions are off", "ast") Then
		ConsoleWrite("Captions are off, need to turn on" & @CRLF)
		; If captions were off, need to turn them on.  Run "cc.drip" to toggle captions on.
		RunTest("cc")
		RunAstTtl()                               ; Run TeraTerm with the 'ast cc' command and collect the log data
	Else
		ConsoleWrite("Captions are on" & @CRLF)
	EndIf

	$sCcCounter1 = FindNextStringInFile("CC counter =", "ast")    ; Get the 'CC counter' value
	ConsoleWrite("Counter1 = " & $sCcCounter1 & @CRLF)

	Sleep(5000)                     ; sleep for 5 seconds

	; Run the same 'cc stats' command again to see if the value incremented.
	RunAstTtl()

	$sCcCounter2 = FindNextStringInFile("CC counter =", "ast")
	ConsoleWrite("Counter2 = " & $sCcCounter2 & @CRLF)
	If $sCcCounter1 <> $sCcCounter2 Then
		; Counter changed. Test passed.
		$sTestSummary = $sTestSummary & @CRLF & "cc: Passed"
	Else
		$sTestSummary = $sTestSummary & @CRLF & "cc: Failed.  Check if captions on this channel, or change channel."
	EndIf
	GUICtrlSetData($TestSummary, $sTestSummary)
EndFunc   ;==>ClosedCaptionTest
