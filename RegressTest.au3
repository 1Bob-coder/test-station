#include <File.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <StaticConstants.au3>
#Region ### START Koda GUI section ### Form=
$Form1_1 = GUICreate("Regression Tests", 449, 382, 192, 124)
$HdmiSwitch = GUICtrlCreateGroup("HDMI Switch", 24, 24, 385, 57)
$HdmiBox1 = GUICtrlCreateRadio("Box1", 40, 48, 49, 17)
$HdmiBox2 = GUICtrlCreateRadio("Box2", 92, 48, 49, 17)
$HdmiBox3 = GUICtrlCreateRadio("Box3", 144, 48, 49, 17)
$HdmiBox4 = GUICtrlCreateRadio("Box4", 196, 48, 49, 17)
$HdmiBox5 = GUICtrlCreateRadio("Box5", 248, 48, 49, 17)
$HdmiBox6 = GUICtrlCreateRadio("Box6", 300, 48, 49, 17)
$HdmiBox7 = GUICtrlCreateRadio("Box7", 352, 48, 49, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$AllTests = GUICtrlCreateCheckbox("All Tests", 32, 88, 73, 17)
$Fingerprint = GUICtrlCreateCheckbox("Fingerprint", 32, 128, 81, 17)
$VCO = GUICtrlCreateCheckbox("VCO", 32, 152, 97, 17)
$ChannelChange = GUICtrlCreateCheckbox("Channel Change", 32, 176, 97, 17)
$ClosedCaptions = GUICtrlCreateCheckbox("Closed Captions", 32, 200, 97, 17)
$TrickPlay = GUICtrlCreateCheckbox("Trick Play", 32, 224, 97, 17)
$TestSummary = GUICtrlCreateLabel("Test Summary", 152, 96, 271, 209, BitOR($SS_SUNKEN,$WS_VSCROLL))
$RunTests = GUICtrlCreateButton("Run Tests", 32, 256, 75, 25)
$IP_Address = GUICtrlCreateLabel("", 208, 72, 7, 17)
$BoxIPAddress = GUICtrlCreateLabel("IP Address of Box", 160, 8, 88, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$sBindAddr = "192.168.1.156"  ; Binding address for the NIC card. Used for DRIP.

; Location of files
$sTestCenter = "C:\Users\dsr\Documents\GitHub\test-station"
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe "   ; TeraTerm exe file
$sPython = "C:\Python27\python.exe "                           ; Python exe file

$sLogDir = $sTestCenter & "\logs\"               ; log directory
$sDripScripts = $sTestCenter & "\DripScripts\"    ; DRIP scripts directory

$sAstTTL = $sTestCenter & "\ttl\ast.ttl"    ; ttl file for running the ast command
$sAstLog = $sLogDir & "ast.log"   ; log file
Const $sCmdDrip = $sDripScripts & "cmd.drip"      ; Drip file for running a single command
$sCmdLog = $sLogDir & "cmd.log"   ; log file

$sPyDrip = $sTestCenter & "\DripClient.py"       ; Python DRIP Client program

$sTestSummary = "Test Summary" & @CRLF
$sIpAddress = ""

$iComStart = 4  ; first com port
$iNumBoxes = 7
$iBoxNum = 0

; Box com port for test boxes on Test Rack 2
Global $aTestBoxes[7] = [9, 5, 7, 4, 6, 10, 8]

; Binding address
$iBindAddr = "192.168.1.156"


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $HdmiBox1
			; The HDMI switch can be controlled using COM1 with the 'sw i##' command
			RunWait(@ComSpec & " /c " & "echo sw i01 > COM1" & @CRLF)
			$iBoxNum = 0
			FindBoxIPAddress()
		Case $HdmiBox2
			RunWait(@ComSpec & " /c " & "echo sw i02 > COM1" & @CRLF)
			$iBoxNum = 1
			FindBoxIPAddress()
		Case $HdmiBox3
			RunWait(@ComSpec & " /c " & "echo sw i03 > COM1" & @CRLF)
			$iBoxNum = 2
			FindBoxIPAddress()
		Case $HdmiBox4
			RunWait(@ComSpec & " /c " & "echo sw i04 > COM1" & @CRLF)
			$iBoxNum = 3
			FindBoxIPAddress()
		Case $HdmiBox5
			RunWait(@ComSpec & " /c " & "echo sw i05 > COM1" & @CRLF)
			$iBoxNum = 4
			FindBoxIPAddress()
		Case $HdmiBox6
			RunWait(@ComSpec & " /c " & "echo sw i06 > COM1" & @CRLF)
			$iBoxNum = 5
			FindBoxIPAddress()
		Case $HdmiBox7
			RunWait(@ComSpec & " /c " & "echo sw i07 > COM1" & @CRLF)
			$iBoxNum = 6
			FindBoxIPAddress()

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
			If StringCompare($sIpAddress, "") Then
				ConsoleWrite("IpAddress = " & $sIpAddress & @CRLF)

				$sTestSummary = "Test Summary" & @CRLF ; Clear out window and just put up "Test Summary"
				GUICtrlSetData($TestSummary, $sTestSummary)

				; Fingerprint test
				If _IsChecked($Fingerprint) Then
					$sSeqNum = StringFormat("%.2d", Random(1, 99, 1)) ; Need to randomize a sequence number
					Local $aFinCmd[2] = ["wait:1000; msp:96,00,0c,00," & $sSeqNum & ",80,33,ff,ff,ff,02", _
							"wait:7000; sea:all"]
					MakeCmdDrip($aFinCmd)
					RunTestCriteria("cmd", "displayUA", "Fingerprint", $Fingerprint)
				EndIf

				If _IsChecked($VCO) Then
					; Perform VCO for 30 seconds on channel 66, override with chan 166.
					; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788
					Local $aVcoCmd[6] = ["wait:1000; diag:A", _  ; VCO command needs Diag A to be run first
							"wait:1000; rmt:DIGIT0", _    ; Channel change to channel 66
							"wait:500; rmt:DIGIT6", _
							"wait:500; rmt:DIGIT6", _
							"wait:6000; vco:30,66,64869,2,788", _
							"wait:7000; sea:all"]
					MakeCmdDrip($aVcoCmd)
					RunTestCriteria("cmd", "SEND LIVE PMT_CHANGED_EVENT (SVC NUM  = 788, CHANNEL = 166)", "VCO (start)", $VCO)
					MakeRmtCmdDrip("rmt:REWIND", 3000)
					RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO (RW)", $VCO)
					MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
					RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO (FF)", $VCO)
					MakeRmtCmdDrip("rmt:PLAY", 2000)
					If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Play (video)", $VCO) Then
						TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "     (audio)")
					EndIf
					MakeRmtCmdDrip("rmt:STOP", 2000)
					If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Stop (video)", $VCO) Then
						TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "     (audio)")
					EndIf
				EndIf

				; Channel change test, channel change one time.  Check for video and audio lock.
				If RunTestCriteria("chupdn", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "Chan Change Video", $ChannelChange) Then
					TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "chupdn", "Chan Change Audio")
				EndIf

				; Closed captions test.  Has to run the 'stats' command twice and compare the two counter values.
				If _IsChecked($ClosedCaptions) Then  ; If the closed captions box is checked
					RunClosedCaptionTest()              ; then run the closed captions test
				EndIf

				If _IsChecked($TrickPlay) Then
					MakeRmtCmdDrip("rmt:REWIND", 3000)
					RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "Trick RW", $TrickPlay)
					MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
					RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick FF", $TrickPlay)
					MakeRmtCmdDrip("rmt:PLAY", 2000)
					If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Play (video)", $TrickPlay) Then
						TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "     (audio)")
					EndIf
					MakeRmtCmdDrip("rmt:STOP", 2000)
					If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Stop (video)", $TrickPlay) Then
						TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "     (audio)")
					EndIf
					MakeRmtCmdDrip("rmt:REWIND", 5000)
					RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick RW", $TrickPlay)
					MakeRmtCmdDrip("rmt:PLAY", 2000)
					If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Play (video)", $TrickPlay) Then
						TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "     (audio)")
					EndIf

				EndIf
			Else
				MsgBox($MB_SYSTEMMODAL, "IP Address not found", "Could not get IP address.")
			EndIf

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd




; Purpose:  This will run a Drip script and test the log file for a certain word.
;           First, check if the test should be run.
;           If so, then put up "running ..." and run the test.
;           Look for specified string in output file to determine pass/fail.
; sWhichTest - refers to the .drip script filename
; sWhichString - is the pass/fail string to search for
; sTestTitle - can be anything, just for display purposes
; hTestBox - is the checkbox handle
Func RunTestCriteria($sWhichTest, $sWhichString, $sTestTitle, $hTestBox)
	Local $bRunTest = False
	If _IsChecked($hTestBox) Then
		GUICtrlSetData($TestSummary, $sTestSummary & @CRLF & $sTestTitle & ": Running ...")
		RunDripTest($sWhichTest)
		ConsoleWrite("Looking for " & $sWhichString & @CRLF)
		TestForString($sWhichString, $sWhichTest, $sTestTitle)
		$bRunTest = True
	EndIf
	Return ($bRunTest)
EndFunc   ;==>RunTestCriteria


; Purpose:  If the given string is found, put "passed" in the test summary.
; sWhichString - The string to search for
; sWhichTest - The .log file to search in
; sTestTitle - Any name, will be echoed to the screen
Func TestForString($sWhichString, $sWhichTest, $sTestTitle)
	If FindStringInFile($sWhichString, $sWhichTest) Then
		$sTestSummary = $sTestSummary & @CRLF & $sTestTitle & ": Passed"
	Else
		$sTestSummary = $sTestSummary & @CRLF & $sTestTitle & ": Failed"
	EndIf
	GUICtrlSetData($TestSummary, $sTestSummary)
EndFunc   ;==>TestForString



; Purpose:  Run 'ifconfig', and get the ip address.
Func FindBoxIPAddress()
	MakeAstTtl("ifconfig", 1)
	RunAstTtl()
	$sIpAddress = FindNextStringInFile("inet addr", "ast")
	GUICtrlSetData($BoxIPAddress, $sIpAddress)
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
	RunWait($sTestCommand)                           ; Run the test.
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
	;ConsoleWrite("FindStringInFile Try to read " & $sLogFile & @CRLF)
	If @error Then
		ConsoleWrite("FindStringInFile FileRead error " & @error & ",  " & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $sWhichString)
		;ConsoleWrite("Position = " & $iPosition & @CRLF)
	EndIf
	Return ($iPosition)
EndFunc   ;==>FindStringInFile


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
; timeout - Just in case 'Done' never happens.
Func MakeAstTtl($sAstCmd, $timeout)
	$hFilehandle = FileOpen($sAstTTL, $FO_OVERWRITE)
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
Func RunAstTtl()
	ConsoleWrite("RunAstTtl Delete " & $sAstLog & @CRLF)
	FileDelete($sAstLog)  ; Delete the log file.
	RunWait($sTeraTerm & " /C=" & $aTestBoxes[$iBoxNum] & " /W=" & "Box" & $iBoxNum & " /M=" & $sAstTTL & " /L=" & $sAstLog)
EndFunc   ;==>RunAstTtl


; Purpose:  To test closed captioning processing.
; Note:  This only tests if closed captions are being processed.
;        It does not test on-screen visual rendering or characters that are incorrect.
; First, test if cc is enabled.  Then turn on if needed.
; Finally, get counter data from two different timeperiods and compare them.
Func RunClosedCaptionTest()
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
		RunDripTest("cc")
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
EndFunc   ;==>RunClosedCaptionTest
