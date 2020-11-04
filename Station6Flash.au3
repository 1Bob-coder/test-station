#include <File.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Region ### START Koda GUI section ### Form=
$Form1_1 = GUICreate("Flash Boxes", 306, 191, 192, 124)
$FlashAllBoxes = GUICtrlCreateButton("Flash All Boxes", 40, 24, 99, 25)
$idComboBox = GUICtrlCreateCombo("Which Box", 40, 64, 135, 25)
$FlashBox = GUICtrlCreateButton("Flash Box", 200, 64, 75, 25)
$SummarizeResults = GUICtrlCreateButton("Summarize Flash Results", 40, 104, 187, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

; Location of files
$sTeraTerm = "c:\Program Files (x86)\teraterm\ttermpro.exe"          ; TeraTerm string
$sFlashTTL = "C:\Users\LAB\Documents\TestCenter\flash.ttl"           ; ttl file for flashing
$sLogDir = "C:\Users\LAB\Documents\TestCenter\logs\"

$sAllVerLogs = $sLogDir & "*_ver_*.log"     ; log files

; DEV rack Boxes:  A01 - A12 (Com 4-15), B01-B10 (Com20-29), C01-C08 (Com36-43) -- Total Number of Boxes = 30
; SI&T Boxes:  A01-A16 (Com4-19), B01-B16 (Com20-35)  -- Total Number of Boxes = 32

$iComStart = 4  ; first com port
$iNumBoxes = 32
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

MakeComboBoxList()


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $FlashAllBoxes
			; Erase all previous logs
			Local $sCommandLine = @ComSpec & " /k " & 'del ' & $sAllVerLogs
			Run($sCommandLine, "", @SW_HIDE)
			ConsoleWrite($sCommandLine)

			For $i = 1 To $iNumBoxes - 1 Step 1
				$sCommandLine = $sTeraTerm & " /C=" & $i + $iComStart & " /W=" & "Box" & $i + 1 & " /M=" & $sFlashTTL
				Run( $sCommandLine )
				ConsoleWrite($sCommandLine)
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
			ConsoleWrite($sCommandDelete & @CRLF)
			ConsoleWrite("BoxNum=" & $iBoxNum & ", ComNum=" & $iComNum & @CRLF)
			Run($sTeraTerm & " /C=" & $iComNum & " /W=" & "Box" & $sBoxNum & " /M=" & $sFlashTTL)

		Case $SummarizeResults
			Local $sBoxCom = ""
			Local $aFlashList[1][2]

			For $i = 1 To $iNumBoxes Step 1
				$sBoxCom = "Unit" & $i & " " & $aBoxList[$i - 1] & "_com" & $i + $iComStart - 1

				Local $hSearch = FileFindFirstFile($sLogDir & "Box" & $i & "_ver*.log")
				If $hSearch = -1 Then
					_ArrayAdd($aFlashList, $sBoxCom & "|" & "Not Flashed")
				Else
					Local $sFileName = "", $iResult = 0, $sRead = "", $sFlashVersion = ""

					$sFileName = FileFindNextFile($hSearch)  ; Get the filename
					If @error Then
						ConsoleWrite("No log file for Box" & $i & @CRLF)
					Else
						Local $sLogFile = $sLogDir & $sFileName
						ConsoleWrite("Filename is " & $sLogFile & @CRLF)

						$sRead = FileRead($sLogFile)
						If @error Then
							ConsoleWrite("FileRead error " & @error & $sRead & @CRLF)
						Else
							$position = StringInStr($sRead, "sprint")
							$sFlashVersion = StringMid($sRead, $position - 7, 21)
						EndIf
					EndIf

					_ArrayAdd($aFlashList, $sBoxCom & "|" & $sFlashVersion)
					ConsoleWrite($sBoxCom & "  flashed" & @CRLF)

					FileClose($hSearch)
				EndIf
			Next
			Local $n = _ArrayDisplay($aFlashList, "Flash Results per Box", "", 64)

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd



Func MakeComboBoxList()
	For $i = 1 To $iNumBoxes Step 1
		$sBoxList = $sBoxList & "|Unit" & $i & " " & $aBoxList[$i - 1] & " Com" & $i + $iComStart - 1
	Next
	GUICtrlSetData($idComboBox, $sBoxList)
EndFunc   ;==>MakeComboBoxList
