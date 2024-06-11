#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

//------------------------------------------------------------------------------
//	Altera SB1
//	Atualiza indicador de MRP
//------------------------------------------------------------------------------
User Function zAssisB()
	Local aArea     := FWGetArea()

	If ! FWAlertNoYes("Atualização do SB1 - MRP e Validade do lote ", "Continuar?")
		Return
	EndIf

	SetFunName("zUPDSB1a")

	dbSelectArea("SB1")
	SB1->(DBSetOrder(1))
	SB1->(DBGoTop())

	While SB1->( !Eof() )

		RecLock("SB1", .F.)

		if Len(AllTrim(B1_COD)) < 8
			SB1->B1_MRP := "N"
		else
			if SubString(B1_COD, 1, 1) == "1" .Or. ;
					SubString(B1_COD, 1, 1) == "2" .Or. ;
					SubString(B1_COD, 1, 1) == "3" .Or. ;
					SubString(B1_COD, 1, 1) == "4"
				SB1->B1_MRP := "S"
				SB1->B1_PRVALID := 365
			else
				SB1->B1_MRP := "N"
			endif
		endif

		SB1->(MsUnlock())

		SB1->( dbSkip() )
	EndDo

	MessageBox("ATUALIZAÇÂO EFETUADA COM SUCESSO!","",0)

	FWRestArea(aArea)
Return

