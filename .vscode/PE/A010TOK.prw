#Include "Protheus.ch"

User Function A010TOK()
	Local lRet := .T.

	if M->B1_MSBLQL == "2" .AND. (M->B1_XLIBFIS == " " .OR. M->B1_XLIBFIS == "N")
		SB1->B1_MSBLQL := "1"
	EndIf

return lRet
