; Purpose:  To run the Networking tests.

#include-once
#include <RegTstUtil.au3>


Func RunNetworkingTest($hTestSummary, $hNetworking_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hNetworking_pf)
	GUICtrlSetData($hTestSummary, "==> Networking Test Started")


	GUICtrlSetData($hTestSummary, "<== Networking Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hNetworking_pf)
EndFunc   ;==>RunNetworkingTest

