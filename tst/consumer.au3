; Purpose:  To run the Consumer Sanity tests.

#include-once
#include <RegTstUtil.au3>


Func RunConsumerTest($hTestSummary, $hConsumerSanity_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hConsumerSanity_pf)
	DisplayLineOfText($hTestSummary, "==> Consumer Sanity Test Started")


	DisplayLineOfText($hTestSummary, "<== Consumer Sanity Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hConsumerSanity_pf)
EndFunc   ;==>RunConsumerTest

