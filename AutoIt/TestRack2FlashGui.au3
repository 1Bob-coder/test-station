#include <File.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>

#Region ### START Koda GUI section ### Form=
$Form1_1 = GUICreate("Flash Boxes", 442, 375, 192, 124)
$FlashAllBoxes = GUICtrlCreateButton("Flash All Boxes", 24, 24, 99, 25)
$idComboBox = GUICtrlCreateCombo("Which Box", 24, 64, 135, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$FlashBox = GUICtrlCreateButton("Flash Box", 184, 64, 75, 25)
$SummarizeResults = GUICtrlCreateButton("Summarize Flash Results", 24, 104, 187, 25)
$HdmiSwitch = GUICtrlCreateGroup("HDMI Switch", 24, 152, 385, 57)
$HdmiBox1 = GUICtrlCreateRadio("Box1", 40, 176, 49, 17)
$HdmiBox2 = GUICtrlCreateRadio("Box2", 92, 176, 49, 17)
$HdmiBox3 = GUICtrlCreateRadio("Box3", 144, 176, 49, 17)
$HdmiBox4 = GUICtrlCreateRadio("Box4", 196, 176, 49, 17)
$HdmiBox5 = GUICtrlCreateRadio("Box5", 248, 176, 49, 17)
$HdmiBox6 = GUICtrlCreateRadio("Box6", 300, 176, 49, 17)
$HdmiBox7 = GUICtrlCreateRadio("Box7", 352, 176, 49, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Fingerprint = GUICtrlCreateButton("Fingerprint", 24, 216, 75, 25)
$VCO = GUICtrlCreateButton("VCO", 24, 248, 75, 25)
$FP_TestResults = GUICtrlCreateLabel("Fingerprint Test Results", 128, 224, 171, 17)
$VCO_TestResults = GUICtrlCreateLabel("VCO Test Results", 128, 256, 176, 17)
$ChUpDn = GUICtrlCreateButton("Channel Up Down", 24, 288, 99, 25)
$TrickPlay = GUICtrlCreateButton("Trick Play", 24, 328, 99, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$sBindAddr = "192.168.1.156"  ; Binding address for the NIC card. Used for DRIP.

; Location of files
; $sTestCenter = "C:\Users\dsr\Documents\TestCenter"
$sTestCenter = "."
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe "   ; TeraTerm exe file
$sPython = "C:\Python27\python.exe "                           ; Python exe file

$sFlashTTL = $sTestCenter & "\ttl\flash.ttl"         ; ttl file for flashing
$sLogDir = $sTestCenter & "\logs\"               ; log directory
$sDripScripts = $sTestCenter & "\DripScripts\"    ; DRIP scripts directory

$sAllVerLogs = $sLogDir & "*_ver_*.log"     ; log files for 'ver' command
$sAllFinLogs = $sLogDir & "*_fin_*.log"     ; log files for fingerprint command

$sPyDrip = $sTestCenter & "\DripClient.py"       ; Python DRIP Client program


; DEV rack Boxes:  A01 - A12 (Com 4-15), B01-B10 (Com20-29), C01-C08 (Com36-43) -- Total Number of Boxes = 30
; SI&T Boxes:  A01-A16 (Com4-19), B01-B16 (Com20-35)  -- Total Number of Boxes = 32
; Test Rack 2:  A01-A07

$iComStart = 4  ; first com port
$iNumBoxes = 7
$iComEnd = $iComStart + $iNumBoxes - 1

Global $aBoxList[$iNumBoxes]
For $i = 1 To $iNumBoxes Step 1
	If $i < 17 Then
		$aBoxList[$i - 1] = "A" & $i
	ElseIf $i < 33 Then
		$aBoxList[$i - 1] = "B" & $i - 16
	Else
		$aBoxList[$i - 1] = "C" & $i - 32
	EndIf
Next

; Combo box strings
Global $sBoxList = ""
For $i = 0 To $iNumBoxes - 1 Step 1
	$sBoxList = $sBoxList & "|Unit" & $i + 1 & " " & "Box" & $aBoxList[$i] & " Com" & $i + $iComStart - 1
Next
GUICtrlSetData($idComboBox, $sBoxList)

; Box IP Address and HDMI selector for test boxes
Global $aTestBoxes[7][2] = [ _
		["192.168.1.159", $HdmiBox1], _
		["192.168.1.162", $HdmiBox2], _
		["192.168.1.163", $HdmiBox3], _
		["192.168.1.161", $HdmiBox4], _
		["192.168.1.157", $HdmiBox5], _
		["192.168.1.160", $HdmiBox6], _
		["192.168.1.164", $HdmiBox7]]

; Binding address
$iBindAddr = "192.168.1.156"


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $FlashAllBoxes
			; Erase all previous logs
			Local $sCommandLine = @ComSpec & " /k " & 'del ' & $sAllVerLogs
			Run($sCommandLine, "", @SW_HIDE)
			ConsoleWrite($sCommandLine & @CRLF)

			For $i = 0 To $iNumBoxes - 1 Step 1
				$sCommandLine = $sTeraTerm & " /C=" & $i + $iComStart & " /W=" & "Box" & $i + 1 & " /M=" & $sFlashTTL
				Run($sCommandLine)
				ConsoleWrite($sCommandLine & @CRLF)
			Next

		Case $FlashBox
			Local $sComboRead = GUICtrlRead($idComboBox)
			; get the com port for this box
			Local $sBoxNum = StringMid($sComboRead, 5, 2)
			Local $iBoxNum = Number($sBoxNum)
			Local $iComNum = $iBoxNum + $iComStart - 1

			; Erase the previous log
			Local $sFileDelete = $sLogDir & "Box" & $iBoxNum & "_ver_*.log"
			Local $sCommandDelete = @ComSpec & " /k " & 'del ' & $sFileDelete
			Run(@ComSpec & " /k " & 'del ' & $sFileDelete, "", @SW_HIDE)
			Run($sTeraTerm & " /C=" & $iComNum & " /W=" & "Box" & $sBoxNum & " /M=" & $sFlashTTL)

		Case $SummarizeResults
			Local $aFlashList[1][2]

			For $i = 0 To $iNumBoxes - 1 Step 1
				Local $hSearch = FileFindFirstFile($sLogDir & "Box" & $i + 1 & "_ver*.log")
				If $hSearch = -1 Then
					_ArrayAdd($aFlashList, $aBoxList[$i] & "|" & "Not Flashed")
				Else
					Local $sFileName = "", $iResult = 0, $sRead = "", $sFlashVersion = ""

					$sFileName = FileFindNextFile($hSearch)  ; Get the filename
					If @error Then
						ConsoleWrite("No log file for Unit" & $i + 1 & @CRLF)
					Else
						Local $sLogFile = $sLogDir & $sFileName
						$sRead = FileRead($sLogFile)
						If @error Then
							ConsoleWrite("FileRead error " & @error & $sRead & @CRLF)
						Else
							$position = StringInStr($sRead, "sprint")
							$sFlashVersion = StringMid($sRead, $position - 7, 21)
						EndIf
					EndIf

					_ArrayAdd($aFlashList, $aBoxList[$i] & "|" & $sFlashVersion)
					FileClose($hSearch)
				EndIf
			Next
			Local $n = _ArrayDisplay($aFlashList, "Flash Results per Box", "", 64)

		Case $HdmiBox1
			SwitchHdmiInput("sw i01" & @CRLF)
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

		Case $Fingerprint
			GUICtrlSetData($FP_TestResults, "Running ...")
			RunTest("finger")
			If FindStringInFile("displayUA", "finger") Then
				GUICtrlSetData($FP_TestResults, "Passed")
				GUICtrlSetColor($FP_TestResults, $COLOR_GREEN)
			Else
				GUICtrlSetData($FP_TestResults, "Failed")
				GUICtrlSetColor($FP_TestResults, $COLOR_Red)
			EndIf

		Case $VCO
			GUICtrlSetData($VCO_TestResults, "Running ...")
			RunTest("vco")
			If FindStringInFile("SEND LIVE PMT_CHANGED_EVENT (SVC NUM  = 788, CHANNEL = 166)", "vco") Then
				GUICtrlSetData($VCO_TestResults, "Passed")
				GUICtrlSetColor($VCO_TestResults, $COLOR_GREEN)
			Else
				GUICtrlSetData($VCO_TestResults, "Failed")
				GUICtrlSetColor($VCO_TestResults, $COLOR_Red)
			EndIf

		Case $ChUpDn
			RunTest("chupdn")


		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd

Func SwitchHdmiInput($whichHdmiInput)
	If WinActivate("[CLASS:TMobaXtermForm]", "") Then
		If WinActivate("HDMISwitch", "") Then
			Send($whichHdmiInput)
		EndIf
	EndIf
EndFunc   ;==>SwitchHdmiInput


; Purpose:  To run the test on the specified box.
Func RunTest($whichTest)
	; First find the specified box.
	Local $bFoundIt = False, $iBoxNum = 0
	For $i = 0 To $iNumBoxes - 1 Step 1
		If GUICtrlRead($aTestBoxes[$i][1]) == 1 Then
			$bFoundIt = True
			$iBoxNum = $i
			ExitLoop
		EndIf
	Next

	If $bFoundIt Then
		; Run the specified test.
		Local $sLogFile = $sLogDir & $whichTest & ".log"
		Local $sTestFile = $sDripScripts & $whichTest & ".drip"
		RunWait(@ComSpec & " /c " & "del " & $sLogFile)
		ConsoleWrite("del " & $sLogFile & @CRLF)
		RunWait($sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $aTestBoxes[$i][0] & _
				" /f " & $sTestFile & " /o " & $sLogFile)
		ConsoleWrite($sPython & $sPyDrip & " /b " & $sBindAddr & " /i " & $aTestBoxes[$i][0] & _
				" /f " & $sTestFile & " /o " & $sLogFile & @CRLF)
	Else
		ConsoleWrite("No HDMI Box Checked")
	EndIf
EndFunc   ;==>RunTest


; Purpose: To find a sting in a file and pass back its position.
; Note: Returns 0 if not found.
Func FindStringInFile($whichString, $whichTest)
	Local $iPosition = 0
	Local $sLogFile = $sLogDir & $whichTest & ".log"
	Local $sRead = FileRead($sLogFile)
	If @error Then
		ConsoleWrite("FileRead error " & @error & $sLogFile & @CRLF)
	Else
		$iPosition = StringInStr($sRead, $whichString)
		ConsoleWrite("Position = " & $iPosition & @CRLF)
	EndIf
	Return ($iPosition)
EndFunc   ;==>FindStringInFile
