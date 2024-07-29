#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

//------------------------------------------------------------------------------
//	Altera SA7
//	Atualiza xDiaSem
//------------------------------------------------------------------------------
User Function zUPDSA7()
	Local aArea     := FWGetArea()

	If ! FWAlertNoYes("Atualização do SA7 - XDIASEM 29/07/2024", "Continuar?")
		Return
	EndIf

	SetFunName("zUPDSA7")

	dbSelectArea("SA7")

	While SA7->( !Eof() )
		dbSelectArea("SB1")
		SB1->(DBSetOrder(1))

		If SB1->(MsSeek(xFilial("SB1") + SA7->A7_PRODUTO))
			if SB1->B1_XDIASEM <> ""
				RecLock("SA7", .F.)
				SA7->A7_XDIASEM := SB1->B1_XDIASEM
				SA7->(MsUnlock())
			endif
		EndIf

		SA7->( dbSkip() )
	EndDo

	MessageBox("ATUALIZAÇÂO EFETUADA COM SUCESSO!","",0)

	FWRestArea(aArea)
Return

