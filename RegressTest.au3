; Purpose:  Main GUI Screen and Button Handler for Regression Test

; Includes for GUI buttons.
#include-once
#include <Date.au3>
#include <AutoItConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#Region ### START Koda GUI section ### Form=
$hForm = GUICreate("Regression Tests", 674, 563, 192, 124)
$hAllTests = GUICtrlCreateCheckbox("All Tests", 32, 104, 73, 17)
$hAV_Presentation = GUICtrlCreateCheckbox("A/V Presentation", 32, 144, 105, 17)
$hAccessControl = GUICtrlCreateCheckbox("Access Control", 32, 168, 105, 17)
$hClosedCaptions = GUICtrlCreateCheckbox("Closed Caption", 32, 192, 105, 17)
$hConsumerSanity = GUICtrlCreateCheckbox("Consumer Sanity", 32, 216, 105, 17)
$hDownload = GUICtrlCreateCheckbox("Download", 32, 240, 105, 17)
$hDVR = GUICtrlCreateCheckbox("DVR", 32, 264, 105, 17)
$hFingerprint = GUICtrlCreateCheckbox("Fingerprint", 32, 288, 105, 17)
$hNetworking = GUICtrlCreateCheckbox("Networking", 32, 312, 105, 17)
$hSystemControl = GUICtrlCreateCheckbox("System Control", 32, 336, 105, 17)
$hTextMessaging = GUICtrlCreateCheckbox("Text Messaging", 32, 360, 105, 17)
$hTuning = GUICtrlCreateCheckbox("Tuning", 32, 384, 105, 17)
$hUSB = GUICtrlCreateCheckbox("USB", 32, 448, 105, 17)
$hVCO = GUICtrlCreateCheckbox("VCO", 32, 472, 105, 17)
$hAV_Presentation_pf = GUICtrlCreateLabel("", 140, 144, 105, 17)
$hAccessControl_pf = GUICtrlCreateLabel("", 140, 168, 105, 17)
$hClosedCaptions_pf = GUICtrlCreateLabel("", 140, 192, 105, 17)
$hConsumerSanity_pf = GUICtrlCreateLabel("", 140, 216, 105, 17)
$hDownload_pf = GUICtrlCreateLabel("", 140, 240, 105, 17)
$hDVR_pf = GUICtrlCreateLabel("", 140, 264, 105, 17)
$hFingerprint_pf = GUICtrlCreateLabel("", 140, 288, 105, 17)
$hNetworking_pf = GUICtrlCreateLabel("", 140, 312, 105, 17)
$hSystemControl_pf = GUICtrlCreateLabel("", 140, 336, 105, 17)
$hTextMessaging_pf = GUICtrlCreateLabel("", 140, 360, 105, 17)
$hTuning_pf = GUICtrlCreateLabel("", 140, 384, 105, 17)
$hUSB_pf = GUICtrlCreateLabel("", 140, 448, 105, 17)
$hVCO_pf = GUICtrlCreateLabel("", 140, 472, 105, 17)
$hRunTests = GUICtrlCreateButton("Run Tests", 32, 504, 75, 25)
$hBoxIPAddress = GUICtrlCreateLabel("IP Address of Box", 344, 104, 144, 17)
$hBoxVersion = GUICtrlCreateLabel("Box Type and Code Version", 152, 104, 144, 17)
$hTitle = GUICtrlCreateLabel("Feature and Regression Tests", 176, 8, 295, 27)
GUICtrlSetFont(-1, 14, 800, 0, "Georgia")
$hSubtitle = GUICtrlCreateLabel("DSR8xx Digital Satellite Receiver", 216, 40, 215, 20)
GUICtrlSetFont(-1, 10, 400, 2, "Georgia")
$hTestSummary = GUICtrlCreateList("", 256, 136, 369, 344, $WS_VSCROLL)
GUICtrlSetData(-1, "")
$hTestSummaryButton = GUICtrlCreateButton("Test Summary", 544, 504, 75, 25)
$hComPort = GUICtrlCreateCombo("Com Port", 152, 72, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$hBindAddr = GUICtrlCreateCombo("Binding Address", 344, 72, 145, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
$hDripClient = GUICtrlCreateButton("DRIP Client", 544, 72, 75, 25)
$hSerialLogs = GUICtrlCreateButton("Serial Logs", 120, 504, 75, 25)
$hTuneTest = GUICtrlCreateButton("Tune Results", 216, 504, 75, 25)
$TuningGroup = GUICtrlCreateGroup("", 40, 400, 97, 41)
$hShortTest = GUICtrlCreateRadio("Short Test", 48, 408, 113, 17)
$hLongTest = GUICtrlCreateRadio("Long Test", 48, 424, 113, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###


; Includes for test files
#include <tst/RegTstUtil.au3> ; Utilities
#include <tst/av.au3> ; A / V tests
#include <tst/acc.au3>  ; Access Control
#include <tst/cc.au3> ; Closed Caption tests
#include <tst/consumer.au3>  ; Consumer Sanity
#include <tst/download.au3>  ; Download tests
#include <tst/dvr.au3> ; DVR tests
#include <tst/finger.au3> ; Fingerprint tests
#include <tst/network.au3> ; Networking tests
#include <tst/sys.au3>  ; System Control tests
#include <tst/text.au3>  ; Test Messaging
#include <tst/tuning.au3> ; Tuning tests
#include <tst/usb.au3>  ; USB tests
#include <tst/vco.au3> ; VCO tests


; Get List of ComPorts
RunWait(@ComSpec & " /c " & "mode > com_ports.log", "", @SW_HIDE)
FileCopy("com_ports.log", $sLogDir, $FC_OVERWRITE + $FC_CREATEPATH)
$lComPorts = FindAllStringsInFile("Status for device COM", "com_ports", -4)
FileDelete("com_ports.log")
GUICtrlSetData($hComPort, $lComPorts)

; Get List of IP Addresses for binding.
RunWait(@ComSpec & " /c " & "ipconfig > ip_addr.log", "", @SW_HIDE)
FileCopy("ip_addr.log", $sLogDir, $FC_OVERWRITE + $FC_CREATEPATH)
$lIpAddr = FindAllStringsInFile("IPv4 Address. . . . . . . . . . . :", "ip_addr", 0)
FileDelete("ip_addr.log")
GUICtrlSetData($hBindAddr, $lIpAddr)


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $hTestSummaryButton
			DisplayTestSummary()

		Case $hComPort                            ; Changing the com port will change IPAddress and BoxVersion
			$sComboRead = GUICtrlRead($hComPort)
			$sComPort = StringReplace($sComboRead, "COM", "")  ; Save as 0, 1, 2, etc.
			FindBoxIPAddress($hBoxIPAddress)        ; IP Address used by DRIP
			FindBoxVer($hBoxVersion)
			GetVctId()

		Case $hBindAddr                            ; Binding address used by DRIP, needed for BoxVersion
			$sBindAddr = GUICtrlRead($hBindAddr)
			$sBindAddr = StringReplace($sBindAddr, " ", "")
			$sBindAddr = StringReplace($sBindAddr, @CRLF, "")  ; Save the binding address
			FindBoxVer($hBoxVersion)
			GetVctId()

		Case $hDripClient
			RunDripClient55()

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
			GUICtrlSetState($hShortTest, $GUI_CHECKED)
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

		Case $hSerialLogs
			OpenLogFiles()

		Case $hTuneTest
			ShowTuneTestLogs()

		Case $hTuning
			GUICtrlSetState($hShortTest, $GUI_CHECKED)

		Case $hRunTests
			GUICtrlSetData($hAV_Presentation_pf, "")
			GUICtrlSetData($hAccessControl_pf, "")
			GUICtrlSetData($hConsumerSanity_pf, "")
			GUICtrlSetData($hClosedCaptions_pf, "")
			GUICtrlSetData($hDownload_pf, "")
			GUICtrlSetData($hDVR_pf, "")
			GUICtrlSetData($hFingerprint_pf, "")
			GUICtrlSetData($hNetworking_pf, "")
			GUICtrlSetData($hSystemControl_pf, "")
			GUICtrlSetData($hTextMessaging_pf, "")
			GUICtrlSetData($hTuning_pf, "")
			GUICtrlSetData($hUSB_pf, "")
			GUICtrlSetData($hVCO_pf, "")

			If StringCompare($sIpAddress, "") = 0 Then
				MsgBox($MB_SYSTEMMODAL, "IP Address not found", "Could not get IP address.")
			ElseIf StringCompare($sBindAddr, "") = 0 Then
				MsgBox($MB_SYSTEMMODAL, "Binding Address not found", "Could not get IP address.")
			Else
				GUICtrlSetData($hTestSummary, "")    ; Clear out Test Summary window
				Local $timestamp = @HOUR & ":" & @MIN & ":" & @SEC
				GUICtrlSetData($hTestSummary, "-- Regression Test Begin -- " & _NowTime() & @CRLF)

				If _IsChecked($hAV_Presentation) Then
					RunAVPresentationTest($hTestSummary, $hAV_Presentation_pf)
				EndIf

				If _IsChecked($hAccessControl) Then
					RunAccTest($hTestSummary, $hAccessControl_pf)
				EndIf

				If _IsChecked($hClosedCaptions) Then
					RunClosedCaptionTest($hTestSummary, $hClosedCaptions_pf)
				EndIf

				If _IsChecked($hConsumerSanity) Then
					RunConsumerTest($hTestSummary, $hConsumerSanity_pf)
				EndIf

				If _IsChecked($hDownload) Then
					RunDownloadTest($hTestSummary, $hDownload_pf)
				EndIf

				If _IsChecked($hDVR) Then
					RunDvrTest($hTestSummary, $hDVR_pf)
				EndIf

				If _IsChecked($hFingerprint) Then
					RunFingerTest($hTestSummary, $hFingerprint_pf)
				EndIf

				If _IsChecked($hNetworking) Then
					RunNetworkingTest($hTestSummary, $hNetworking_pf)
				EndIf

				If _IsChecked($hSystemControl) Then
					RunSysControlTest($hTestSummary, $hSystemControl_pf)
				EndIf

				If _IsChecked($hTextMessaging) Then
					RunTextMessagingTest($hTestSummary, $hTextMessaging_pf)
				EndIf

				If _IsChecked($hTuning) Then
					If _IsChecked($hShortTest) Then
						RunTuningTest($hTestSummary, $hTuning_pf, 0)
					Else
						RunTuningTest($hTestSummary, $hTuning_pf, 1)
					EndIf
				EndIf

				If _IsChecked($hUSB) Then
					RunUsbTest($hTestSummary, $hUSB_pf)
				EndIf

				If _IsChecked($hVCO) Then
					RunVCOTest($hTestSummary, $hVCO_pf)
				EndIf

				GUICtrlSetData($hTestSummary, "-- Regression Test End -- " & _NowTime() & @CRLF)
			EndIf

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd
