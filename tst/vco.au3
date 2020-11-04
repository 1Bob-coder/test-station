; Purpose:  To run the VCO tests.

#include-once
#include <RegTstUtil.au3>


Func RunVCOTest($TestSummary, $VCO_pf)
	Local $bPassFail = True
	; VCO needs Diag A to be run to get the xyz values of circle test.
	; Then press EXIT twice to get out of any GUI screens.
	Local $aVcoCmd[3] = ["wait:1000; diag:A", _
			"wait:1000; rmt:EXIT", _
			"wait:1000; rmt:EXIT"]
	Local $sFrom, $sTo        ; From channel and to channel

	Local $sVctId = GetVctId()    ; Set up the VCO based on the VCT_ID of the box.
	GUICtrlSetData($TestSummary, "Using VCTID of " & $sVctId & @CRLF)

	CollectSerialLogs("VcoSerial")        ; Start collection of serial log file

	PF_Box("Running", $COLOR_BLUE, $VCO_pf)
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)
	GUICtrlSetData($TestSummary, "VCO Test Started")

	Local $sVctId = GetVctId()
	GUICtrlSetData($TestSummary, "VCTID = " & $sVctId & @CRLF)
	If $sVctId = "4380" Then
		; VCO 55 seconds from 121 to 224 --> SourceID=fd6a (64,874), Transponder=2, ServiceNum=555 (VCT_ID 4380)
		; Channel change to channel 121
		$sFrom = 121
		$sTo = 224
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT1")
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT2")
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT1")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:55,121,64874,2,555")     ; Send vco command
		_ArrayAdd($aVcoCmd, "wait:6000; sea:all")                    ; Wait 6 seconds
	Else
		; Perform VCO for 55 seconds on channel 66, override with chan 166.
		; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788 (VCT_ID 4188)
		$sFrom = 66
		$sTo = 166
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT0")
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT6")
		_ArrayAdd($aVcoCmd, "wait:1000; rmt:DIGIT6")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:55,66,64869,2,788")       ; Send vco command
		_ArrayAdd($aVcoCmd, "wait:6000; sea:all")                      ; Wait 6 seconds
	EndIf


	MakeCmdDrip($aVcoCmd)                    ; Make cmd.drip file to be run with Drip.
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start(video CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start (audio CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:EXIT", 10000)
	GUICtrlSetData($TestSummary, "Send EXIT" & @CRLF)
	RunDripTest("cmd")
	MakeRmtCmdDrip("rmt:REWIND", 4000)
	GUICtrlSetData($TestSummary, "Send REWIND" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO RW", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	GUICtrlSetData($TestSummary, "Send FAST_FWD" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO FF", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	GUICtrlSetData($TestSummary, "Send PLAY" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Play (video)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Play (audio)", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:STOP", 2000)
	GUICtrlSetData($TestSummary, "Send STOP" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Stop (video)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Stop (audio)", $TestSummary, $VCO_pf) And $bPassFail
	GUICtrlSetData($TestSummary, "Wait 20 seconds for VCO to end." & @CRLF)
	MakeRmtCmdDrip("rmt:PLAY", 20000)  ; Wait 20 seconds for VCO to end
	GUICtrlSetData($TestSummary, "Send PLAY." & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (video CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (audio CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPassFail

	GUICtrlSetData($TestSummary, "VCO Test Done")
	WinKill("COM")    ; End collection of serial log file

	If $bPassFail Then
		PF_Box("Passed", $COLOR_GREEN, $VCO_pf)
	Else
		PF_Box("Failed", $COLOR_Red, $VCO_pf)
	EndIf
EndFunc   ;==>RunVCOTest

Func GetVctId()
	Local $aVctId[2] = ["wait:1000; diag:A,5,3", _             ; Diag A, line 5, column 3, e.g.,  VCT_ID = 4380
			"wait:1000; sea:ALL"]     ; Pause for a second
	MakeCmdDrip($aVctId)          ; Make cmd.drip file to be run with Drip.
	RunDripTest("cmd")                                ; Run cmd.drip
	Local $sVctId = GetStringInFile("VCT_ID = ", "cmd", 0, 13)
	$sVctId = StringReplace($sVctId, "VCT_ID = ", "")
	Return $sVctId
EndFunc   ;==>GetVctId

