; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>

; Purpose:  Entry point to the Fingerprint test.
; Test Matrix Requirement:
; 2	DSR SI&T.DRM.Fingerprint:001-001	Fingerprint display
; 3	DSR SI&T.DRM.Fingerprint:001-002	Fingerprint duration
; 3	DSR SI&T.DRM.Fingerprint:001-003	Fingerprint on composite
; 3	DSR SI&T.DRM.Fingerprint:001-004	Fingerprint on HDMI
; 3	DSR SI&T.DRM.Fingerprint:001-008	Fingerprint over DVR playback
; 3	DSR SI&T.DRM.Fingerprint:001-010	No fingerprints on background recording use case
; 5	DSR SI&T.DRM.Fingerprint:001-011	No fingerprints on foreground recording use case
; 5	DSR SI&T.DRM.Fingerprint:001-012	Standby cycle use case
; 5	DSR SI&T.DRM.Fingerprint:001-014	Fingerprint durations

Func RunFingerTest($TestSummary, $Fingerprint_pf)
	Local $bPass = True, $bPassFail = True
	GUICtrlSetData($TestSummary, "==> Fingerprint Test Started")
	PF_Box("Running", $COLOR_BLUE, $Fingerprint_pf)

	; Exit out of any screens and channel change up two times and down two times.
	Local $aStartFresh[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:CHAN_UP", _
			"wait:3000; rmt:CHAN_UP", _
			"wait:3000; rmt:CHAN_DOWN", _
			"wait:3000; rmt:CHAN_DOWN"]
	MakeCmdDrip($aStartFresh)
	RunDripTest("cmd")
	GUICtrlSetData($TestSummary, "Wait 5 seconds and then send fingerprint." & @CRLF)

	Sleep(5000)        ; Wait 5 seconds and then send the fingerprint.
	$bPassFail = SendFingerprint($TestSummary, $Fingerprint_pf, "Fingerprint (Live)")

	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-001", $bPassFail)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-002", $bPassFail)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-003", $bPassFail)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-004", $bPassFail)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-014", $bPassFail)
	$bPass = $bPass And $bPassFail

	If $sBoxType <> "DSR800" Then
		; Perform DVR Fingerprint tests.
		$bPassFail = DvrFingerprintTests($TestSummary, $Fingerprint_pf)
	EndIf
	$bPass = $bPass And $bPassFail

	; Standby test.  Make sure it doesn't render in Standby.
	MakeRmtCmdDrip("rmt:POWER", 3000)
	$bPassFail = RunTestCriteria("cmd", "ALL VIDEO OUTPUTS: DISABLED", "Standby mode", $TestSummary, $Fingerprint_pf)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-012", $bPassFail)
	$bPass = $bPass And $bPassFail
	$bPass = RunTestCriteria("cmd", "ALL VIDEO OUTPUTS: ENABLED", "Non-standby mode", $TestSummary, $Fingerprint_pf) And $bPass

	GUICtrlSetData($TestSummary, "<== Fingerprint Test Done")
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $Fingerprint_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $Fingerprint_pf)
	EndIf
EndFunc   ;==>RunFingerTest

; Purpose:  Sends a fingerprint message to the box.
; Returns a True/False if the code responded with display of the Unit Address.
Func SendFingerprint($TestSummary, $Fingerprint_pf, $sTitle)
	$sSeqNum = StringFormat("%.2d", Random(1, 99, 1))                     ; Need to randomize a sequence number
	Local $aFinCmd[2] = ["wait:1000; msp:96,00,0c,00," & $sSeqNum & ",80,33,ff,ff,ff,02", _
			"wait:7000; sea:all"]
	MakeCmdDrip($aFinCmd)
	$bPassFail = RunTestCriteria("cmd", "displayUA", $sTitle, $TestSummary, $Fingerprint_pf)
	Return $bPassFail
EndFunc   ;==>SendFingerprint

; Purpose:  To run the DVR fingerprint tests.
; Test cases:
; 3	DSR SI&T.DRM.Fingerprint:001-008	Fingerprint over DVR playback
; 3	DSR SI&T.DRM.Fingerprint:001-010	No fingerprints on background recording use case
; 5	DSR SI&T.DRM.Fingerprint:001-011	No fingerprints on foreground recording use case
Func DvrFingerprintTests($TestSummary, $Fingerprint_pf)
	Local $bPass = True, $bPassFail = True
	; Test fingerprint does not get recorded.
	GUICtrlSetData($TestSummary, "Skip back and check if fingerprint was recorded." & @CRLF)
	Local $aSkipBack[] = [ _
			"wait:1000; rmt:STOP", _
			"wait:2000; rmt:SKIP_BACK", _
			"wait:2000; rmt:DIGIT0", _
			"wait:1000; rmt:PLAY", _
			"wait:2000; rmt:EXIT", _
			"wait:10000; rmt:EXIT"]
	MakeCmdDrip($aSkipBack)
	RunDripTest("cmd")
	$bPassFail = Not FindStringInFile("displayUA", "cmd")
	If $bPassFail Then
		GUICtrlSetData($TestSummary, "Fingerprint not recorded - Pass" & @CRLF)
	Else
		GUICtrlSetData($TestSummary, "Fingerprint was recorded - Fail" & @CRLF)
	EndIf
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-010", $bPassFail)
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-011", $bPassFail)
	$bPass = $bPassFail And $bPass

	; Test fingerprint during LOD.
	$bPassFail = SendFingerprint($TestSummary, $Fingerprint_pf, "Fingerprint (Playback) ")
	SavePassFailTestResult("DSR SI&T.DRM.Fingerprint:001-008", $bPassFail)
	$bPass = $bPassFail And $bPass
	MakeRmtCmdDrip("rmt:STOP", 1000)
	RunDripTest("cmd")
	Return $bPass
EndFunc   ;==>DvrFingerprintTests
