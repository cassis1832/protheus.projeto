#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

//------------------------------------------------------------------------------
//	Altera SB1
//	Atualiza indicador de MRP
//------------------------------------------------------------------------------
User Function zUPDSB1()
	Local aArea     := FWGetArea()
	Local aPergs	    := {}
	Local aResps	    := {}
	Local cCliente

	If ! FWAlertNoYes("Atualizacao do SB1 - MRP ", "Continuar?")
		Return
	EndIf

	SetFunName("zUPDSB1")

	AAdd(aPergs, {1, "Informe o cliente", CriaVar("A1_COD",.F.),,,"SA1",, 6, .F.})

	If ParamBox(aPergs, "Parametros do relatorio", @aResps,,,,,,,, .T., .T.)
		cCliente    := aResps[1]
	Else
		return
	endif

	Atualiza(cCliente)

	MessageBox("ATUALIZACAO EFETUADA COM SUCESSO!","",0)

	FWRestArea(aArea)
Return

Static Function Atualiza(cCliente)
	dbSelectArea("SA7")
	SA7->(DBSetOrder(1))
	SA7->(DBGoTop())

	While SA7->( !Eof() )

		if SA7->A7_CLIENTE == cCliente
			dbSelectArea("SB1")
			SB1->(DBSetOrder(1))

			If SB1->(MsSeek(xFilial("SB1") + SA7->A7_PRODUTO))
				RecLock("SB1", .F.)
				SB1->B1_MRP := "S"
				SB1->(MsUnlock())
				gItem = SB1->B1_COD
				Explode(gItem)
			EndIf
		EndIf

		SA7->( dbSkip() )
	EndDo
Return


Static Function Explode(cItem)
	Local lItem := ""

	lItem = cItem

	cQuery := "SELECT G1_COD, G1_COMP "
	cQuery += " FROM " +	RetSQLName("SG1") + " SG1 "
	cQuery += "WHERE G1_COD = '" + lItem + "' "
	cQuery += "	 AND SG1.D_E_L_E_T_ = ' ' "

	cEstrut := MPSysOpenQuery(cQuery)

	While (cEstrut)->(!EOF())

		dbSelectArea("SB1")
		SB1->(DBSetOrder(1))

		If SB1->(MsSeek(xFilial("SB1") + (cEstrut)->G1_COMP))

			if SB1->B1_AGREGCU == "2"
				RecLock("SB1", .F.)
				SB1->B1_MRP := "S"
				SB1->(MsUnlock())
				Explode((cEstrut)->G1_COMP)
			EndIf
		endif
		(cEstrut)->(DbSkip())
	enddo
Return
