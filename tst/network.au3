; Purpose:  To run the Networking tests.

#include-once
#include <RegTstUtil.au3>


; Purpose:  Entry point to WiFi Network testing.
; Note: WiFi Config needs to be set prior to running tests.
; This performs the following tests
; 3	DSR SI&T.Networking.WiFi:001-001	WiFi Network Detection
; 2	DSR SI&T.Networking.WiFi:001-002	Join a WiFi Network
; 3	DSR SI&T.Networking.WiFi:001-003	Retain WiFi Config
Func RunNetworkingTest($hTestSummary, $hNetworking_pf)
	Local $bPass = True, $bConnected
	Local $aDebugs[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:1000; rmt:EXIT", _
			"wait:1000; rmt:OPTIONS", _
			"wait:1000; rmt:ARROW_RIGHT", _
			"wait:1000; rmt:ARROW_RIGHT", _
			"wait:1000; rmt:SELECT"]

	PF_Box("Running", $COLOR_BLUE, $hNetworking_pf)
	GUICtrlSetData($hTestSummary, "==> Networking Test Started")

	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

	; Detect if WiFi connected.  Check for "wlan0" in "ifconfig".
	Sleep(15000)       ; Sleep for 15 seconds.
	MakeAstTtl("ifconfig", 3)  ; make the "ifconfig" command, 3 second timeout in case of no response.
	RunAstTtl()
	$iFoundLocation = FindStringInFile("wlan0", "ast")
	If $iFoundLocation Then
		; Found wlan0.  Now test if WiFi connected.
		For $ii = 1 To 2 Step 1
			$bIsConnected = IsWiFiConnected($hTestSummary, "Test_" & $ii & " Before - ")
			If $bIsConnected Then
				; Toggle off
				GUICtrlSetData($hTestSummary, "Test_" & $ii & " Turn off WiFi" & @CRLF)
				MakeRmtCmdDrip("rmt:GREEN", 1000)
				RunDripTest("cmd")
				$bIsConnected = IsWiFiConnected($hTestSummary, "Test_" & $ii & " After - ")
				If $bIsConnected Then
					GUICtrlSetData($hTestSummary, "Fail - WiFi did not toggle off." & @CRLF)
				EndIf
				$bPass = $bPass And Not $bIsConnected
			Else
				; Toggle on
				GUICtrlSetData($hTestSummary, "Test_" & $ii & " Turn on WiFi" & @CRLF)
				MakeRmtCmdDrip("rmt:SELECT", 1000)
				RunDripTest("cmd")
				Sleep(20000) ; sleep for 20 seconds
				RunDripTest("cmd")
				$bIsConnected = IsWiFiConnected($hTestSummary, "Test_" & $ii & " After - ")
				If Not $bIsConnected Then
					GUICtrlSetData($hTestSummary, "Fail - WiFi did not toggle on." & @CRLF)
				EndIf
				$bPass = $bPass And $bIsConnected
			EndIf
		Next
	Else
		$bPass = False
		GUICtrlSetData($hTestSummary, "No Wireless Capability - Failure" & @CRLF)
	EndIf

	SavePassFailTestResult("DSR SI&T.Networking.WiFi:001-001", $bPass)
	SavePassFailTestResult("DSR SI&T.Networking.WiFi:001-002", $bPass)
	SavePassFailTestResult("DSR SI&T.Networking.WiFi:001-003", $bPass)

	GUICtrlSetData($hTestSummary, "<== Networking Test Done")
	DisplayPassFail($bPass, $hNetworking_pf)
EndFunc   ;==>RunNetworkingTest


; Purpose: To find out if the WiFi is connected.
; Returns a True if connected.
Func IsWiFiConnected($hTestSummary, $sTitle)
	Local $sNextString = ""
	Local $bConnected = False
	Local $aStrings[] = ["wlan0", "inet addr"]
	MakeAstTtl("ifconfig", 3)      ; make the "ifconfig" command, 3 second timeout in case of no response.
	RunAstTtl()
	$sNextString = FindStringAfterStrings($aStrings, "ast")
	If $sNextString == "" Then
		GUICtrlSetData($hTestSummary, $sTitle & "WiFi is not connected" & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, $sTitle & "WiFi is connected, IP = " & $sNextString & @CRLF)
		$bConnected = True
	EndIf
	Return $bConnected
EndFunc   ;==>IsWiFiConnected
