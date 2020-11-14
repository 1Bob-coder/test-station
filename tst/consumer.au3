; Purpose:  To run the Consumer Sanity tests.

#include-once
#include <RegTstUtil.au3>


Func RunConsumerTest($hTestSummary, $hConsumerSanity_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hConsumerSanity_pf)
	GUICtrlSetData($hTestSummary, "Consumer Sanity Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "Consumer Sanity Test Done")
	PF_Box("Done", $COLOR_BLUE, $hConsumerSanity_pf)
EndFunc   ;==>RunConsumerTest

