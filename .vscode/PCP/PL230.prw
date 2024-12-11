#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL230
	Plano de producao MR - Baseado nas OPs - Real
@author Carlos Assis
@since 22/07/2024
@version 1.0   
/*/
User Function PL230()
	Local aArea 	:= FWGetArea()

	Private oMark	:= Nil
	Private cMarca 	:= GetMark()
	Private cTitulo	:= "Plano de Producao - MR"
	Private cFiltro	:= ""

	Private dDtIni 	:= DaySub(Date(), 30)
	Private dDtFim 	:= DaySum(Date(), 07)

	SetKey( VK_F12,  {|| u_PL230F12()} )

	ZA2->(DBSetOrder(1))
	If ! ZA2->(MsSeek(xFilial("ZA2") + "1"))
		u_PL230A("Calculo", dDtIni, dDtFim)
	else
		u_PL230A("Atualiza", dDtIni, dDtFim)
	endif

	//Criando o browse da temporária
	oMark := FWMarkBrowse():New()
	oMark:SetDescription(cTitulo)
	oMark:SetAlias('ZA2')
	oMark:DisableDetails()
	oMark:SetFieldMark( 'ZA2_OK' )
	oMark:SetMark(cMarca, "ZA2", "ZA2_OK")
	oMark:SetAllMark( { || oMark:AllMark() } )

	oMark:AddLegend("ZA2->ZA2_STAT == 'C' .AND. ZA2->ZA2_SITSLD == 'S'"	, "GREEN"	, "Ordem Confirmada"			, "1")
	oMark:AddLegend("ZA2->ZA2_STAT == 'C' .AND. ZA2->ZA2_SITSLD == 'N'"	, "RED"		, "Ordem Confirmada sem saldo"	, "1")
	oMark:AddLegend("ZA2->ZA2_STAT == 'P' .AND. ZA2->ZA2_SITSLD == 'S'"	, "YELLOW"	, "Ordem Planejada"				, "1")
	oMark:AddLegend("ZA2->ZA2_STAT == 'P' .AND. ZA2->ZA2_SITSLD == 'N'"	, "PINK"	, "Ordem Planejada sem saldo"	, "1")

//	LerParametros()

	oMark:Activate()

	FWRestArea(aArea)
return


Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar' 	  	ACTION 'VIEWDEF.PL230'  	OPERATION 2 ACCESS 0
	ADD OPTION aRot TITLE 'Alterar'    	  	ACTION 'VIEWDEF.PL230'  	OPERATION 4 ACCESS 0
	ADD OPTION aRot TITLE 'Liberar'			ACTION 'u_PL230Mark("L")'	OPERATION 5 ACCESS 0
	ADD OPTION aRot TITLE 'Calcular'   	  	ACTION 'u_PL230Calculo' 	OPERATION 9 ACCESS 0
	ADD OPTION aRot TITLE 'Imprimir Ordem'	ACTION 'u_PL230Mark("P")'	OPERATION 7 ACCESS 0
	ADD OPTION aRot TITLE 'Imprimir Plano'	ACTION 'u_PL230Plano' 		OPERATION 6 ACCESS 0
	ADD OPTION aRot TITLE 'Legenda'    	  	ACTION 'u_PL230Legenda' 	OPERATION 8 ACCESS 0
Return aRot


Static Function ModelDef()
	Local oModel := Nil
	Local oStZA2 := FWFormStruct(1,"ZA2")

	oStZA2:SetProperty('ZA2_OP',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_DATPRI',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_DATPRF',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_PROD',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_PRIOR',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_TPOP',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_DTUPD',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_LINPRD',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_HRUPD',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_ITCLI',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_LE',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_OPER',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_QUANT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_QUJE',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New  ("PL230M", Nil, Nil, Nil, Nil)

	oModel:AddFields("FORMZA2",/*cOwner*/,oStZA2)
	oModel:SetPrimaryKey({'ZA2_TIPO', 'ZA2_RECURS', 'ZA2_DTINIP', 'ZA2_PROD', 'ZA2_OPER'})
	oModel:SetDescription("Dados da Ordem de Producao ")
	oModel:GetModel("FORMZA2"):SetDescription("Ordem de Produção ")
Return oModel


Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL230")
	Local oStZA2 := FWFormStruct(2, "ZA2")

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZA2", oStZA2, "FORMZA2")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_ZA2', 'Ordem de Producao')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_ZA2","TELA")
Return oView


/*---------------------------------------------------------------------*
  Calcula o sequenciamento
 *---------------------------------------------------------------------*/
User Function PL230Calculo()
	u_PL230A("Calculo", dDtIni, dDtFim)
	oMark:Refresh()
return


/*---------------------------------------------------------------------*
  Emite Programa de Produca
 *---------------------------------------------------------------------*/
User Function PL230Plano()
	u_PL250()
return

/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL230Legenda()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE"	,"Ordem confirmada"})
    AAdd(aLegenda,{"BR_VERMELHO","Ordem confirmada - sem saldo de componente ou MP"})
    AAdd(aLegenda,{"BR_AMARELO"	,"Ordem Planejada"})
    AAdd(aLegenda,{"BR_PINK"	,"Ordem Planejada - sem saldo de componete ou MP"})
    BrwLegenda("Legenda", "Tipo", aLegenda)
return


/*---------------------------------------------------------------------*
  Firmar as OPs selecionadas
 *---------------------------------------------------------------------*/
User Function PL230Mark(cAcao)
	Local aArea    	:= GetArea()
	Local cMarca   	:= oMark:Mark()

	ZA2->(DbGoTop())

	While !ZA2->(EoF())
		If oMark:IsMark(cMarca)
			RecLock('ZA2', .F.)
			ZA2_OK := ''

			// Libera a ordem
			if cAcao == "L"
				if ZA2->ZA2_STAT == 'C'
					ZA2->ZA2_STAT := 'P'
				else
					ZA2->ZA2_STAT := 'C'
				endif
			endif

			ZA2->(MsUnlock())

			// Imprimir a ordem
			if cAcao == "P" .AND. ZA2->ZA2_PRTOP <> 'S'
				u_PL010A(ZA2->ZA2_OP, .F., .F.)
				Sleep(1000)
			endif
		EndIf

		ZA2->(DbSkip())
	EndDo

	RestArea(aArea)
Return NIL


User Function PL230F12()
	LerParametros()
return

/*---------------------------------------------------------------------*
  Ler os parametros do usuario
 *---------------------------------------------------------------------*/
Static Function LerParametros()
	Local cSql 		:= ""
	Local cAlias 	:= ''
	Local xInd		:= 0

	Local aPergs	:= {}
	Local aResps	:= {}

	Local aTipos	:= {}
	Local cLinha	:= ""

	Local cRecurso 	:= Nil

	cSql := "SELECT DISTINCT H1_XLIN "
	cSql += "  FROM " + RetSQLName("SH1") + " SH1 "
	cSql += " WHERE H1_FILIAL         = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_    <> '*' "
	cSql += " ORDER BY H1_XLIN "
	cAlias := MPSysOpenQuery(cSql)

	Aadd(aTipos, "")

	While (cAlias)->(!EOF())
		xInd++
		Aadd(aTipos, AllTrim((cAlias)->H1_XLIN))
		(cAlias)->(DbSkip())
	EndDo

	(cAlias)->(DBCLOSEAREA())
	
	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .T.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .T.})
	AAdd(aPergs, {1, "Recurso"					, CriaVar("H1_CODIGO",.F.),,,"SH1",, 70, .F.})
	AAdd(aPergs, {2, "Linha"					, cLinha, aTipos, 70, ".T.", .F.})

	cFiltro := "ZA2_TIPO == '1'"

	If ParamBox(aPergs, "PL230 - PLANO DE PRODUCAO - MR", @aResps,,,,,,,, .T., .T.)
		dDtIni 		:= aResps[1]
		dDtFim 		:= aResps[2]
		cRecurso	:= aResps[3]
		cLinha		:= aResps[4]
		if cRecurso <> Nil .and. AllTrim(cRecurso) <> ""
			cFiltro	+= " .and. ZA2_RECURS == '" + cRecurso + "'"
		Endif
		if cLinha <> Nil .and. AllTrim(cLinha) <> ""
			cFiltro	+= " .and. ZA2_TIPLIN == '" + cLinha + "'"
		Endif
	Else
		return
	endif
	
	oMark:CleanFilter()
	oMark:SetFilterDefault(cFiltro)
	oMark:Refresh()
return
