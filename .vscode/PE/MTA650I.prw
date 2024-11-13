#Include 'Protheus.ch'

/*/{Protheus.doc} MTA650I
Gravacao da ordem de producao
	12/11/2024 - Se o item for externo a OP deve ser externa
@type function
@version 1.0
@author Carlos Assis
@since 12/11/2024
/*/

User Function MTA650I()

	if allTrim(SB1->B1_XTPPR) != ""
		RecLock('SC2', .F.)
		SC2->C2_TPPR := SB1->B1_XTPPR
		SC2->(MsUnlock())
	endif

	lRet := .F.

Return lRet

