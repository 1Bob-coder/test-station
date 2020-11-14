; Purpose:  To run the Networking tests.

#include-once
#include <RegTstUtil.au3>


Func RunNetworkingTest($hTestSummary, $hNetworking_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hNetworking_pf)
	GUICtrlSetData($hTestSummary, "Networking Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "Networking Test Done")
	PF_Box("Done", $COLOR_BLUE, $hNetworking_pf)
EndFunc   ;==>RunNetworkingTest

