; Purpose:  Main GUI Screen and Button Handler for Regression Test.


; Includes for test files
#include <RegTstUtil.au3>
#include <cc.au3>
#include <av.au3>
#include <dvr.au3>
#include <finger.au3>
#include <vco.au3>

; Includes for GUI buttons.
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#Region ### START Koda GUI section ### Form=
$Form1_1 = GUICreate("Regression Tests", 670, 559, 192, 124)
$HdmiSwitch = GUICtrlCreateGroup("HDMI Switch", 128, 64, 385, 57)
$HdmiBox1 = GUICtrlCreateRadio("Box1", 144, 88, 49, 17)
$HdmiBox2 = GUICtrlCreateRadio("Box2", 196, 88, 49, 17)
$HdmiBox3 = GUICtrlCreateRadio("Box3", 248, 88, 49, 17)
$HdmiBox4 = GUICtrlCreateRadio("Box4", 300, 88, 49, 17)
$HdmiBox5 = GUICtrlCreateRadio("Box5", 352, 88, 49, 17)
$HdmiBox6 = GUICtrlCreateRadio("Box6", 404, 88, 49, 17)
$HdmiBox7 = GUICtrlCreateRadio("Box7", 456, 88, 49, 17)
$IP_Address = GUICtrlCreateLabel("", 208, 72, 7, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$AllTests = GUICtrlCreateCheckbox("All Tests", 32, 136, 73, 17)
$AV_Presentation = GUICtrlCreateCheckbox("A/V Presentation", 32, 176, 105, 17)
$AccessControl = GUICtrlCreateCheckbox("Access Control", 32, 200, 105, 17)
$ClosedCaptions = GUICtrlCreateCheckbox("Closed Caption", 32, 224, 105, 17)
$ConsumerSanity = GUICtrlCreateCheckbox("Consumer Sanity", 32, 248, 105, 17)
$Download = GUICtrlCreateCheckbox("Download", 32, 272, 105, 17)
$DVR = GUICtrlCreateCheckbox("DVR", 32, 296, 105, 17)
$Fingerprint = GUICtrlCreateCheckbox("Fingerprint", 32, 320, 105, 17)
$Networking = GUICtrlCreateCheckbox("Networking", 32, 344, 105, 17)
$SystemControl = GUICtrlCreateCheckbox("System Control", 32, 368, 105, 17)
$TextMessaging = GUICtrlCreateCheckbox("Text Messaging", 32, 392, 105, 17)
$Tuning = GUICtrlCreateCheckbox("Tuning", 32, 416, 105, 17)
$USB = GUICtrlCreateCheckbox("USB", 32, 440, 105, 17)
$VCO = GUICtrlCreateCheckbox("VCO", 32, 464, 105, 17)

$AV_Presentation_pf = GUICtrlCreateLabel("", 140, 176, 105, 17)
$AccessControl_pf = GUICtrlCreateLabel("", 140, 200, 105, 17)
$ClosedCaptions_pf = GUICtrlCreateLabel("", 140, 224, 105, 17)
$ConsumerSanity_pf = GUICtrlCreateLabel("", 140, 248, 105, 17)
$Download_pf = GUICtrlCreateLabel("", 140, 272, 105, 17)
$DVR_pf = GUICtrlCreateLabel("", 140, 296, 105, 17)
$Fingerprint_pf = GUICtrlCreateLabel("", 140, 320, 105, 17)
$Networking_pf = GUICtrlCreateLabel("", 140, 344, 105, 17)
$SystemControl_pf = GUICtrlCreateLabel(" ", 140, 368, 105, 17)
$TextMessaging_pf = GUICtrlCreateLabel(" ", 140, 392, 105, 17)
$Tuning_pf = GUICtrlCreateLabel("", 140, 416, 105, 17)
$USB_pf = GUICtrlCreateLabel("", 140, 440, 105, 17)
$VCO_pf = GUICtrlCreateLabel("", 140, 464, 105, 17)

$RunTests = GUICtrlCreateButton("Run Tests", 32, 504, 75, 25)
$BoxIPAddress = GUICtrlCreateLabel("IP Address of Box", 264, 128, 88, 17)
$Title = GUICtrlCreateLabel("Feature and Regression Tests", 176, 8, 295, 27)
GUICtrlSetFont(-1, 14, 800, 0, "Georgia")
$Subtitle = GUICtrlCreateLabel("DSR Test Rack 2", 248, 40, 103, 20)
GUICtrlSetFont(-1, 10, 400, 2, "Georgia")
$TestSummary = GUICtrlCreateList("", 256, 160, 369, 305, $WS_VSCROLL) ;
GUICtrlSetData(-1, "")
$TestSummaryButton = GUICtrlCreateButton("Test Summary", 408, 504, 75, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###



While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $TestSummaryButton
			DisplayTestSummary()

		Case $HdmiBox1
			BoxUnderTest(1, $BoxIPAddress)
		Case $HdmiBox2
			BoxUnderTest(2, $BoxIPAddress)
		Case $HdmiBox3
			BoxUnderTest(3, $BoxIPAddress)
		Case $HdmiBox4
			BoxUnderTest(4, $BoxIPAddress)
		Case $HdmiBox5
			BoxUnderTest(5, $BoxIPAddress)
		Case $HdmiBox6
			BoxUnderTest(6, $BoxIPAddress)
		Case $HdmiBox7
			BoxUnderTest(7, $BoxIPAddress)

		Case $AllTests
			If _IsChecked($AllTests) Then
				GUICtrlSetState($AV_Presentation, $GUI_CHECKED)
				GUICtrlSetState($AccessControl, $GUI_CHECKED)
				GUICtrlSetState($ConsumerSanity, $GUI_CHECKED)
				GUICtrlSetState($ClosedCaptions, $GUI_CHECKED)
				GUICtrlSetState($Download, $GUI_CHECKED)
				GUICtrlSetState($DVR, $GUI_CHECKED)
				GUICtrlSetState($Fingerprint, $GUI_CHECKED)
				GUICtrlSetState($Networking, $GUI_CHECKED)
				GUICtrlSetState($SystemControl, $GUI_CHECKED)
				GUICtrlSetState($TextMessaging, $GUI_CHECKED)
				GUICtrlSetState($Tuning, $GUI_CHECKED)
				GUICtrlSetState($USB, $GUI_CHECKED)
				GUICtrlSetState($VCO, $GUI_CHECKED)
			Else
				GUICtrlSetState($AV_Presentation, $GUI_UNCHECKED)
				GUICtrlSetState($AccessControl, $GUI_UNCHECKED)
				GUICtrlSetState($ConsumerSanity, $GUI_UNCHECKED)
				GUICtrlSetState($ClosedCaptions, $GUI_UNCHECKED)
				GUICtrlSetState($Download, $GUI_UNCHECKED)
				GUICtrlSetState($DVR, $GUI_UNCHECKED)
				GUICtrlSetState($Fingerprint, $GUI_UNCHECKED)
				GUICtrlSetState($Networking, $GUI_UNCHECKED)
				GUICtrlSetState($SystemControl, $GUI_UNCHECKED)
				GUICtrlSetState($TextMessaging, $GUI_UNCHECKED)
				GUICtrlSetState($Tuning, $GUI_UNCHECKED)
				GUICtrlSetState($USB, $GUI_UNCHECKED)
				GUICtrlSetState($VCO, $GUI_UNCHECKED)
			EndIf

		Case $RunTests
			If StringCompare($sIpAddress, "") Then
				GUICtrlSetData($TestSummary, "")    ; Clear out Test Summary window

				If _IsChecked($AV_Presentation) Then
					RunAVPresentationTest($TestSummary, $AV_Presentation_pf)
				EndIf

				If _IsChecked($ClosedCaptions) Then  ; If  closed captions box is checked
					RunClosedCaptionTest($TestSummary, $ClosedCaptions_pf)              ; then run the closed captions test
				EndIf

				If _IsChecked($DVR) Then
					RunDvrTest($TestSummary, $DVR_pf)
				EndIf

				If _IsChecked($Fingerprint) Then
					RunFingerTest($TestSummary, $Fingerprint_pf)
				EndIf

				If _IsChecked($VCO) Then
					RunVCOTest($TestSummary, $VCO_pf)
				EndIf

			Else
				MsgBox($MB_SYSTEMMODAL, "IP Address not found", "Could not get IP address.")
			EndIf

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd




