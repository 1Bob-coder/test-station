; Purpose:  To run the tuning tests.

#include-once
#include <RegTstUtil.au3>


Func RunTuningTest($hTestSummary, $hTuning_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "Tuning Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT9", "rmt:DIGIT6", "rmt:DIGIT4")

	;Nexus  Source Format          : 720P  --> or 1080I, or 480I
	;Nexus Video Codec             : MPEG4
	;Nexus Aspect Ratio            : 4x3(1.3) derived with Sar x:y:(x*w/y*h)=10:11:1.33333  --> or 16x9 (1.7)
	;Input Source Type :    Ac3
	; All channels are 8PSK, 20.5 MBPS, 1.92 code rate.
	; Freq from 995250000* to 1435250000*

	; Symbol Rate is always 20.5 MBPS for all channels on live
	; Coding Rate is always 1.92 for all channels on live

	; CA:CA:StsDigitalCaSystem.cpp:515:displayAuthReason:NOT_SUBSCRIBED
	; CA:CA:StsDigitalCaSystem.cpp:403:notifyServiceInfo:CA1  SERVICE_DENIED CH : 966
	;local1.notice : CA:CA:StsDigitalCaSystem.cpp:403:notifyServiceInfo:CA1  SERVICE_DENIED CH : 307
	;local1.notice : CA:CA:StsDigitalCaSystem.cpp:515:displayAuthReason:NOT_SUBSCRIBED
	; or,
	; local1.notice : CA:CA:StsDigitalCaSystem.cpp:398:notifyServiceInfo:CA0 SERVICE_AUTHORIZED
	; CA:CA:StsDigitalCaSystem.cpp:398:notifyServiceInfo:CA0 SERVICE_AUTHORIZED CH : 125


	MakeRmtCmdDrip("rmt:CHAN_UP", 5000)        ; Chan Up, collect logs for 5 seconds
	Local $aTuneResults[1][5] = [["Chan", "Vid Src", "Aspect", "Auth", "AuthWhy"]]
	For $ii = 1 To 308
		RunDripTest("cmd")
		MakeAstTtl("ast vi", 3)                ; Get the video stats
		RunAstTtl()
		Local $sAuthState0 = "", $sAuthState1 = ""
		$sVideoSource = FindNextStringInFile("Nexus  Source Format", "ast")
		$sAspectRatio = FindNextStringInFile("Nexus Aspect Ratio", "ast")
		$sChanNum = FindNextStringInFile("CH :", "cmd")
		;$sChanNum = FindNextStringInFile("CH", "cmd")
		;Func GetStringInFile($sWhichString, $sWhichTest, $iOffset, $iLength)
		;$iOffset = StringLen("
		$sAuthState = FindNthStringInFile("notifyServiceInfo", "cmd", 2)
		;$sAuthState0 = FindNextStringInFile("notifyServiceInfo:CA0  ", "cmd")
		;$sAuthState1 = FindNextStringInFile("notifyServiceInfo:CA1  ", "cmd")
		;$sAuthState = FindNextStringInFile("notifyServiceInfo:", "cmd")
		$sAuthWhy = FindNthStringInFile("displayAuthReason", "cmd", 1)
		;$sAuthWhy = FindNextStringInFile("displayAuthReason:", "cmd")
		GUICtrlSetData($hTestSummary, "Channel " & $sChanNum & " " & $sVideoSource & " " & _
				$sAspectRatio & " " & $sAuthState & " " & $sAuthWhy & @CRLF)
		Local $vRow[1][5] = [[$sChanNum, $sVideoSource, $sAspectRatio, $sAuthState, $sAuthWhy]]
		_ArrayAdd($aTuneResults, $vRow)
		Sleep(1000)  ; Sleep for 1 second
		FileDelete($sChanNum & ".log")
		FileCopy("cmd.log", $sChanNum & ".log")
	Next
	GUICtrlSetData($hTestSummary, "Tuning Test Done")
	PF_Box("Done", $COLOR_BLUE, $hTuning_pf)
	_ArrayDisplay($aTuneResults)
EndFunc   ;==>RunTuningTest
