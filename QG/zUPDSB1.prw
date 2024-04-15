#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

//------------------------------------------------------------------------------
//	Altera SB1
//	Atualiza indicador de MRP
//------------------------------------------------------------------------------
User Function zQGASSIS()
	Local aArea     := FWGetArea()

	/*----------------------------------------------
	Local lPar01 := ""
	Local cPar02 := ""
	Local dPar03 := CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase
	//----------------------------------------------*/

	MessageBox("ATUALIZAÇÃO INICIADA!","",0)

	SetFunName("zUPDSB1")

	dbSelectArea("SB1")
	SB1->(DBSetOrder(1))
	SB1->(DBGoTop())

	While SB1->( !Eof() )

		RecLock("SB1", .F.)

		if SubString(B1_COD, 1, 1) == "1" .Or. ;
				SubString(B1_COD, 1, 1) == "2" .Or. ;
				SubString(B1_COD, 1, 1) == "3" .Or. ;
				SubString(B1_COD, 1, 1) == "4"

			SB1->B1_MRP := "S"
		else
			SB1->B1_MRP := "N"
		endif

		SB1->(MsUnlock())

		SB1->( dbSkip() )
	EndDo

	MessageBox("ATUALIZAÇÃO EFETUADA COM SUCESSO!","",0)

	FWRestArea(aArea)
Return

