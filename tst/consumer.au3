; Purpose:  To run the Consumer Sanity tests.

#include-once
#include <RegTstUtil.au3>


Func RunConsumerTest($hTestSummary, $hConsumerSanity_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hConsumerSanity_pf)
	GUICtrlSetData($hTestSummary, "==> Consumer Sanity Test Started")


	GUICtrlSetData($hTestSummary, "<== Consumer Sanity Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hConsumerSanity_pf)
EndFunc   ;==>RunConsumerTest

