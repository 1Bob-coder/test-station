; Purpose:  To run the Text Messaging tests.

#include-once
#include <RegTstUtil.au3>


Func RunTextMessagingTest($hTestSummary, $hTextMessaging_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTextMessaging_pf)
	GUICtrlSetData($hTestSummary, "Text Messaging Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "Text Messaging Test Done")
	PF_Box("Done", $COLOR_BLUE, $hTextMessaging_pf)
EndFunc   ;==>RunTextMessagingTest

