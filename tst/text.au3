; Purpose:  To run the Text Messaging tests.

#include-once
#include <RegTstUtil.au3>


Func RunTextMessagingTest($hTestSummary, $hTextMessaging_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTextMessaging_pf)
	DisplayLineOfText($hTestSummary, "==> Text Messaging Test Started")


	DisplayLineOfText($hTestSummary, "<== Text Messaging Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hTextMessaging_pf)
EndFunc   ;==>RunTextMessagingTest

