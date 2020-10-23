; Purpose:  Main GUI Screen and Button Handler for Regression Test.
; This has the HDMI switch control and com ports specific for Test Rack 2


; Includes for test files
#include <RegTstUtil.au3>  ; Utilities
#include <cc.au3>          ; Closed Caption tests
#include <av.au3>          ; A/V tests
#include <dvr.au3>         ; DVR tests
#include <finger.au3>      ; Fingerprint tests
#include <vco.au3>         ; VCO tests

; Includes for GUI buttons.
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#Region ### START Koda GUI section ### Form=
$hForm = GUICreate("Regression Tests", 670, 559, 192, 124)
$hHdmiGroup = GUICtrlCreateGroup("HDMI Switch", 128, 64, 385, 57)
$hHdmiBox1 = GUICtrlCreateRadio("Box1", 144, 88, 49, 17)
$hHdmiBox2 = GUICtrlCreateRadio("Box2", 196, 88, 49, 17)
$hHdmiBox3 = GUICtrlCreateRadio("Box3", 248, 88, 49, 17)
$hHdmiBox4 = GUICtrlCreateRadio("Box4", 300, 88, 49, 17)
$hHdmiBox5 = GUICtrlCreateRadio("Box5", 352, 88, 49, 17)
$hHdmiBox6 = GUICtrlCreateRadio("Box6", 404, 88, 49, 17)
$hHdmiBox7 = GUICtrlCreateRadio("Box7", 456, 88, 49, 17)
$IP_Address = GUICtrlCreateLabel("", 208, 72, 7, 17)
$hAllTests = GUICtrlCreateCheckbox("All Tests", 32, 136, 73, 17)
$hAV_Presentation = GUICtrlCreateCheckbox("A/V Presentation", 32, 176, 105, 17)
$hAccessControl = GUICtrlCreateCheckbox("Access Control", 32, 200, 105, 17)
$hClosedCaptions = GUICtrlCreateCheckbox("Closed Caption", 32, 224, 105, 17)
$hConsumerSanity = GUICtrlCreateCheckbox("Consumer Sanity", 32, 248, 105, 17)
$hDownload = GUICtrlCreateCheckbox("Download", 32, 272, 105, 17)
$hDVR = GUICtrlCreateCheckbox("DVR", 32, 296, 105, 17)
$hFingerprint = GUICtrlCreateCheckbox("Fingerprint", 32, 320, 105, 17)
$hNetworking = GUICtrlCreateCheckbox("Networking", 32, 344, 105, 17)
$hSystemControl = GUICtrlCreateCheckbox("System Control", 32, 368, 105, 17)
$hTextMessaging = GUICtrlCreateCheckbox("Text Messaging", 32, 392, 105, 17)
$hTuning = GUICtrlCreateCheckbox("Tuning", 32, 416, 105, 17)
$hUSB = GUICtrlCreateCheckbox("USB", 32, 440, 105, 17)
$hVCO = GUICtrlCreateCheckbox("VCO", 32, 464, 105, 17)
$hAV_Presentation_pf = GUICtrlCreateLabel("", 140, 176, 105, 17)
$hAccessControl_pf = GUICtrlCreateLabel("", 140, 200, 105, 17)
$hClosedCaptions_pf = GUICtrlCreateLabel("", 140, 224, 105, 17)
$hConsumerSanity_pf = GUICtrlCreateLabel("", 140, 248, 105, 17)
$hDownload_pf = GUICtrlCreateLabel("", 140, 272, 105, 17)
$hDVR_pf = GUICtrlCreateLabel("", 140, 296, 105, 17)
$hFingerprint_pf = GUICtrlCreateLabel("", 140, 320, 105, 17)
$hNetworking_pf = GUICtrlCreateLabel("", 140, 344, 105, 17)
$hSystemControl_pf = GUICtrlCreateLabel(" ", 140, 368, 105, 17)
$hTextMessaging_pf = GUICtrlCreateLabel(" ", 140, 392, 105, 17)
$hTuning_pf = GUICtrlCreateLabel("", 140, 416, 105, 17)
$hUSB_pf = GUICtrlCreateLabel("", 140, 440, 105, 17)
$hVCO_pf = GUICtrlCreateLabel("", 140, 464, 105, 17)
$hRunTests = GUICtrlCreateButton("Run Tests", 32, 504, 75, 25)
$hBoxIPAddress = GUICtrlCreateLabel("IP Address of Box", 264, 128, 88, 17)
$hTitle = GUICtrlCreateLabel("Feature and Regression Tests", 176, 8, 295, 27)
GUICtrlSetFont(-1, 14, 800, 0, "Georgia")
$hSubtitle = GUICtrlCreateLabel("DSR Test Rack 2", 248, 40, 103, 20)
GUICtrlSetFont(-1, 10, 400, 2, "Georgia")
$hTestSummary = GUICtrlCreateList("", 256, 160, 369, 305, $WS_VSCROLL) ;
GUICtrlSetData(-1, "")
$hTestSummaryButton = GUICtrlCreateButton("Test Summary", 408, 504, 75, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$comPort = 0

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $hTestSummaryButton
			DisplayTestSummary()

		Case $hHdmiBox1
			BoxUnderTest(1, $hBoxIPAddress)
		Case $hHdmiBox2
			BoxUnderTest(2, $hBoxIPAddress)
		Case $hHdmiBox3
			BoxUnderTest(3, $hBoxIPAddress)
		Case $hHdmiBox4
			BoxUnderTest(4, $hBoxIPAddress)
		Case $hHdmiBox5
			BoxUnderTest(5, $hBoxIPAddress)
		Case $hHdmiBox6
			BoxUnderTest(6, $hBoxIPAddress)
		Case $hHdmiBox7
			BoxUnderTest(7, $hBoxIPAddress)

		Case $hAllTests
			If _IsChecked($hAllTests) Then
				GUICtrlSetState($hAV_Presentation, $GUI_CHECKED)
				GUICtrlSetState($hAccessControl, $GUI_CHECKED)
				GUICtrlSetState($hConsumerSanity, $GUI_CHECKED)
				GUICtrlSetState($hClosedCaptions, $GUI_CHECKED)
				GUICtrlSetState($hDownload, $GUI_CHECKED)
				GUICtrlSetState($hDVR, $GUI_CHECKED)
				GUICtrlSetState($hFingerprint, $GUI_CHECKED)
				GUICtrlSetState($hNetworking, $GUI_CHECKED)
				GUICtrlSetState($hSystemControl, $GUI_CHECKED)
				GUICtrlSetState($hTextMessaging, $GUI_CHECKED)
				GUICtrlSetState($hTuning, $GUI_CHECKED)
				GUICtrlSetState($hUSB, $GUI_CHECKED)
				GUICtrlSetState($hVCO, $GUI_CHECKED)
			Else
				GUICtrlSetState($hAV_Presentation, $GUI_UNCHECKED)
				GUICtrlSetState($hAccessControl, $GUI_UNCHECKED)
				GUICtrlSetState($hConsumerSanity, $GUI_UNCHECKED)
				GUICtrlSetState($hClosedCaptions, $GUI_UNCHECKED)
				GUICtrlSetState($hDownload, $GUI_UNCHECKED)
				GUICtrlSetState($hDVR, $GUI_UNCHECKED)
				GUICtrlSetState($hFingerprint, $GUI_UNCHECKED)
				GUICtrlSetState($hNetworking, $GUI_UNCHECKED)
				GUICtrlSetState($hSystemControl, $GUI_UNCHECKED)
				GUICtrlSetState($hTextMessaging, $GUI_UNCHECKED)
				GUICtrlSetState($hTuning, $GUI_UNCHECKED)
				GUICtrlSetState($hUSB, $GUI_UNCHECKED)
				GUICtrlSetState($hVCO, $GUI_UNCHECKED)
			EndIf

		Case $hRunTests
			If StringCompare($sIpAddress, "") Then
				GUICtrlSetData($hTestSummary, "")    ; Clear out Test Summary window

				If _IsChecked($hAV_Presentation) Then
					RunAVPresentationTest($hTestSummary, $hAV_Presentation_pf, $comPort)
				EndIf

				If _IsChecked($hClosedCaptions) Then
					RunClosedCaptionTest($hTestSummary, $hClosedCaptions_pf, $comPort)
				EndIf

				If _IsChecked($hDVR) Then
					RunDvrTest($hTestSummary, $hDVR_pf)
				EndIf

				If _IsChecked($hFingerprint) Then
					RunFingerTest($hTestSummary, $hFingerprint_pf)
				EndIf

				If _IsChecked($hVCO) Then
					RunVCOTest($hTestSummary, $hVCO_pf)
				EndIf

			Else
				MsgBox($MB_SYSTEMMODAL, "IP Address not found", "Could not get IP address.")
			EndIf

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd





; Purpose:  Control the HDMI switch input, set the box number, and find the IP Address.
; whichBox - 1 to 7
; hBoxIPAddress - handle of the Text Box to show the IP address.
Func BoxUnderTest($whichBox, $hBoxIPAddress)
	RunWait(@ComSpec & " /c " & "echo sw i0" & $whichBox & " > COM1" & @CRLF)  ; Sends "sw i0x" command to switch HDMI port
	; Box com ports for test boxes on Test Rack 2
	; Box 1 is Com 9, Box 2 is Com 5, etc.
	Local $aBoxComPorts[7] = [9, 5, 7, 4, 6, 10, 8]
	$comPort = $aBoxComPorts[$whichBox - 1]
	FindBoxIPAddress($hBoxIPAddress, $comPort)
EndFunc   ;==>BoxUnderTest