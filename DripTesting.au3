#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>



#Region ### START Koda GUI section ### Form=
$DRIPTestCenter = GUICreate("DRIP Test Center", 563, 532, -1, -1)
$Group_Commands = GUICtrlCreateGroup("Group Commands", 32, 104, 513, 297)
$Box_1 = GUICtrlCreateCheckbox("Box1 DSR830", 40, 152, 89, 17)
$Box_2 = GUICtrlCreateCheckbox("Box2 DSR830", 40, 176, 89, 17)
$Box_3 = GUICtrlCreateCheckbox("Box3 DSR830", 40, 200, 89, 17)
$Box_4 = GUICtrlCreateCheckbox("Box4 DSR800", 40, 224, 89, 17)
$Box_5 = GUICtrlCreateCheckbox("Box5 DSR830", 40, 248, 89, 17)
$Box_6 = GUICtrlCreateCheckbox("Box6 DSR830", 40, 272, 89, 17)
$Box_7 = GUICtrlCreateCheckbox("Box7 DSR800", 40, 296, 89, 17)
$Reboot_DSR = GUICtrlCreateButton("Reboot DSR", 240, 144, 75, 25)
$Close_DRIP = GUICtrlCreateButton("Close DRIP", 160, 144, 75, 25)
$Stop_Test = GUICtrlCreateButton("Stop Test", 152, 256, 163, 25)
$DRIP_Label = GUICtrlCreateLabel("DRIP Commands", 176, 120, 85, 17)
$PVR_Stress = GUICtrlCreateButton("Start PVR Stress Test", 152, 192, 163, 25)
$ChanChange = GUICtrlCreateButton("Start Chan Change Stress Test", 152, 224, 163, 25)
$MobaXterm_label = GUICtrlCreateLabel("MobaXterm Commands", 376, 120, 113, 17)
$Flash_Code = GUICtrlCreateButton("Flash Code", 344, 160, 75, 25)
$Load_Code = GUICtrlCreateButton("Load Code", 424, 160, 75, 25)
$Input_command = GUICtrlCreateInput("", 344, 212, 121, 21)
$Send = GUICtrlCreateButton("Send", 472, 208, 43, 25)
$MobaXtermCommand = GUICtrlCreateLabel("Send a serial command to a box.", 344, 192, 158, 17)
$AllBoxes = GUICtrlCreateCheckbox("All Boxes", 40, 128, 73, 17)
$TeraTerm = GUICtrlCreateLabel("TeraTerm Commands", 376, 256, 105, 17)
$TTFlash = GUICtrlCreateButton("Flash Code", 368, 296, 123, 25)
$FlashnLoad = GUICtrlCreateLabel("Note: Flash and Load at the Debug prompt.", 328, 144, 209, 17)
$MountnFlash = GUICtrlCreateLabel("Note: Flash code while box is running.", 344, 280, 183, 17)
$CloseTTerms = GUICtrlCreateButton("Close Tera Term", 368, 328, 123, 25)
$RunAnalysis = GUICtrlCreateButton("Run Analysis", 368, 368, 123, 25)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Start_MobaXterm = GUICtrlCreateButton("Start MobaXterm", 32, 24, 115, 25)
$HDMI_Switch = GUICtrlCreateGroup("HDMI Switch using MobaXterm", 64, 456, 425, 57)
$RadioBox1 = GUICtrlCreateRadio("Box1", 88, 480, 49, 17)
$RadioBox2 = GUICtrlCreateRadio("Box2", 144, 480, 49, 17)
$RadioBox3 = GUICtrlCreateRadio("Box3", 200, 480, 49, 17)
$RadioBox4 = GUICtrlCreateRadio("Box4", 256, 480, 49, 17)
$RadioBox5 = GUICtrlCreateRadio("Box5", 312, 480, 49, 17)
$RadioBox6 = GUICtrlCreateRadio("Box6", 368, 480, 49, 17)
$RadioBox7 = GUICtrlCreateRadio("Box7", 424, 480, 49, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Box1 = GUICtrlCreateButton("Box1 830", 32, 64, 67, 25)
$Box2 = GUICtrlCreateButton("Box2 830", 104, 64, 67, 25)
$Box3 = GUICtrlCreateButton("Box3 830", 176, 64, 67, 25)
$Box4 = GUICtrlCreateButton("Box4 800", 248, 64, 67, 25)
$Box5 = GUICtrlCreateButton("Box5 830", 320, 64, 67, 25)
$Box6 = GUICtrlCreateButton("Box6 830", 392, 64, 67, 25)
$Box7 = GUICtrlCreateButton("Box7 800", 464, 64, 67, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$Bind_IP = "192.168.1.156"
$DRIP_Client = "C:\Users\dsr\Desktop\Bob\DRIP_client_5.5.exe"
$Stress_Test = " /F C:\Users\dsr\Desktop\Bob\stresstest.txt /L 9999"
$ChanChange_Test = " /F C:\Users\dsr\Desktop\Bob\Test1.drip /L 9999"

Global $isHdmiControlRunning = 0

; Array of Test Boxes 1 - 7
Global $aTestBoxes[7][6] = [ _
		["Box1", "192.168.1.159", $Box_1, "BOX1", "9", "830"], _
		["Box2", "192.168.1.162", $Box_2, "BOX2", "5", "830"], _
		["Box3", "192.168.1.163", $Box_3, "BOX3", "7", "830"], _
		["Box4", "192.168.1.161", $Box_4, "BOX4", "4", "800"], _
		["Box5", "192.168.1.157", $Box_5, "BOX5", "6", "830"], _
		["Box6", "192.168.1.160", $Box_6, "BOX6", "10", "830"], _
		["Box7", "192.168.1.164", $Box_7, "BOX7", "8", "800"]]


AutoItSetOption("MouseCoordMode", 0)
AutoItSetOption("WinTitleMatchMode", 2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase



While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $Start_MobaXterm
			StartMobaXterm()

		Case $Box1
			Run($DRIP_Client & " /I " & $aTestBoxes[0][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[0][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[0][0] & "_out.txt")

		Case $Box2
			Run($DRIP_Client & " /I " & $aTestBoxes[1][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[1][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[1][0] & "_out.txt")

		Case $Box3
			Run($DRIP_Client & " /I " & $aTestBoxes[2][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[2][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[2][0] & "_out.txt")

		Case $Box4
			Run($DRIP_Client & " /I " & $aTestBoxes[3][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[3][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[3][0] & "_out.txt")

		Case $Box5
			Run($DRIP_Client & " /I " & $aTestBoxes[4][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[4][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[4][0] & "_out.txt")

		Case $Box6
			Run($DRIP_Client & " /I " & $aTestBoxes[5][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[5][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[5][0] & "_out.txt")

		Case $Box7
			Run($DRIP_Client & " /I " & $aTestBoxes[6][1] _
					 & " /B " & $Bind_IP & " /T " & $aTestBoxes[6][0] _
					 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[6][0] & "_out.txt")

		Case $AllBoxes
			If _IsChecked($AllBoxes) Then
				GUICtrlSetState($Box_1, $GUI_CHECKED)
				GUICtrlSetState($Box_2, $GUI_CHECKED)
				GUICtrlSetState($Box_3, $GUI_CHECKED)
				GUICtrlSetState($Box_4, $GUI_CHECKED)
				GUICtrlSetState($Box_5, $GUI_CHECKED)
				GUICtrlSetState($Box_6, $GUI_CHECKED)
				GUICtrlSetState($Box_7, $GUI_CHECKED)
			Else
				GUICtrlSetState($Box_1, $GUI_UNCHECKED)
				GUICtrlSetState($Box_2, $GUI_UNCHECKED)
				GUICtrlSetState($Box_3, $GUI_UNCHECKED)
				GUICtrlSetState($Box_4, $GUI_UNCHECKED)
				GUICtrlSetState($Box_5, $GUI_UNCHECKED)
				GUICtrlSetState($Box_6, $GUI_UNCHECKED)
				GUICtrlSetState($Box_7, $GUI_UNCHECKED)
			EndIf




		Case $Close_DRIP
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Close the DRIP window.
					WinClose($aTestBoxes[$i][3])
				EndIf
			Next

		Case $Reboot_DSR
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Click the Reboot button on DRIP
					ControlClick($aTestBoxes[$i][3], "", "[CLASS:Button; TEXT:Reboot]")
				EndIf
			Next

		Case $Stop_Test
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Click the Stop button on DRIP
					ControlClick($aTestBoxes[$i][3], "", "[CLASS:Button; TEXT:Stop]")
				EndIf
			Next

		Case $Flash_Code
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					If FindWindow($aTestBoxes[$i][0]) Then
						; Flash the release code into the box.
						Send("$FLASH_REL" & @CRLF)
					EndIf
				EndIf
			Next

		Case $Load_Code
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					If FindWindow($aTestBoxes[$i][0]) Then
						; Load the Release code
						Send("$LOAD_REL" & @CRLF)
					EndIf
				EndIf
			Next

		Case $PVR_Stress
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Run the DRIP Stress Test
					$DripCommand = $DRIP_Client & " /I " & $aTestBoxes[$i][1] & $Stress_Test _
							 & " /B " & $Bind_IP & " /T " & $aTestBoxes[$i][0] _
							 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[$i][0] & "_out.txt"
					Run($DripCommand)
				EndIf
			Next

		Case $ChanChange
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Run the DRIP Channel Change Test
					$DripCommand = $DRIP_Client & " /I " & $aTestBoxes[$i][1] _
							 & " /B " & $Bind_IP & " /T " & $aTestBoxes[$i][0] & $ChanChange_Test _
							 & " /O C:\Users\dsr\Desktop\Bob\out\" & $aTestBoxes[$i][0] & "_out.txt"
					Run($DripCommand)
				EndIf
			Next

		Case $Send
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					If FindWindow($aTestBoxes[$i][0]) Then
						Send(GUICtrlRead($Input_command) & @CR)
					EndIf
				EndIf
			Next

		Case $TTFlash
			For $i = 0 To 6 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					; Run Tera Term for that com port.
					If $aTestBoxes[$i][5] = "830" Then
						Run("c:\Program Files (x86)\teraterm\ttermpro.exe /C=" & $aTestBoxes[$i][4] & " /W=" & $aTestBoxes[$i][0] & " /M=C:\Users\dsr\Desktop\Bob\TestCenter\flash830.ttl")
					Else
						Run("c:\Program Files (x86)\teraterm\ttermpro.exe /C=" & $aTestBoxes[$i][4] & " /W=" & $aTestBoxes[$i][0] & " /M=C:\Users\dsr\Desktop\Bob\TestCenter\flash800.ttl")
					EndIf
				EndIf
			Next

		Case $CloseTTerms
			For $i = 0 To 7 Step 1
				If _IsChecked($aTestBoxes[$i][2]) Then
					WinClose($aTestBoxes[$i][0])
				EndIf
			Next

		Case $RunAnalysis
				RunWait( @ComSpec & " /k " & 'findstr sprint c:\users\dsr\desktop\bob\testcenter\*_ver_20200811*.log', "", @SW_SHOW)

		Case $RadioBox1
			SwitchHdmiInput("sw i01" & @CRLF)
		Case $RadioBox2
			SwitchHdmiInput("sw i02" & @CRLF)
		Case $RadioBox3
			SwitchHdmiInput("sw i03" & @CRLF)
		Case $RadioBox4
			SwitchHdmiInput("sw i04" & @CRLF)
		Case $RadioBox5
			SwitchHdmiInput("sw i05" & @CRLF)
		Case $RadioBox6
			SwitchHdmiInput("sw i06" & @CRLF)
		Case $RadioBox7
			ConsoleWrite("Calling SwitchHdmiInput" & @CRLF)
			SwitchHdmiInput("sw i07" & @CRLF)

		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch
WEnd




; To start MobaXterm, first issue the "run" command to start the program.
; Then right-click on the folder holding all the sessions, and click Run all sessions.
Func StartMobaXterm()
	If WinActivate("[CLASS:TMobaXtermForm]", "") Then
		; Found a running session, so don't start a new session.
		MsgBox($MB_SYSTEMMODAL, "", "Could not start new session of MobaXterm")
	Else
		Run("C:\Users\dsr\Desktop\MobaXterm_Portable_v10.9\MobaXterm_Personal_10.9.exe")

		; Wait until it's active and running.  (Add a 10 second timeout just in case.)
		WinWaitActive("[CLASS:TMobaXtermForm]", "", 10)
		WinActivate("[CLASS:TMobaXtermForm]", "") ; Give focus to the window

		MouseClick("right", 91, 156, 2)     ; Right-click folder for options.
		MouseClick("primary", 100, 392, 1)  ; Choose option to run all the sessions.

	EndIf
EndFunc   ;==>StartMobaXterm


; This cycles through the various MobaXterm sessions we have open to
; find the appropriate open window, i.e., Box1, Box2, ..., HDMISwitch.
Func FindWindow($Window)
	Local $success = 0

	If WinActivate("[CLASS:TMobaXtermForm]", "") Then
		For $i = 0 To 10 Step 1
			If WinActivate($Window, "") Then
				; Found it!
				$success = 1
				;Send("Hello" & @CRLF)
				ExitLoop
			Else
				; Tab to the next window and try again.
				WinActivate("[CLASS:TMobaXtermForm]", "") ; Give focus to the window
				Send("^{TAB}")
				Sleep(500)
			EndIf
		Next
	EndIf
	Return $success
EndFunc   ;==>FindWindow

Func SwitchHdmiInput($whichHdmiInput)
	If WinActivate("[CLASS:TMobaXtermForm]", "") Then
		If WinActivate("HDMISwitch", "") Then
			Send($whichHdmiInput)
		EndIf
	EndIf
EndFunc   ;==>SwitchHdmiInput



; Returns true if the checkbox is checked.
Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked

