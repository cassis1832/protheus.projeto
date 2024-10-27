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

	Private oBrowse
	Private cMarca 	:= GetMark()
	Private cTitulo	:= "Plano de Producao - MR"
	Private cFiltro	:= ""

	Private dDtIni  := Nil
	Private dDtFim  := Nil

	SetKey( VK_F12,  {|| u_PL230F12()} )

	//Criando o browse da temporária
	oBrowse := FWMarkBrowse():New()
	oBrowse:SetAlias('ZA2')
	oBrowse:SetDescription(cTitulo)
	oBrowse:DisableDetails()
	oBrowse:SetFieldMark( 'ZA2_OK' )
	oBrowse:SetMark(cMarca, "ZA2", "ZA2_OK")
	oBrowse:SetAllMark( { || oBrowse:AllMark() } )

	ObterDados()

	oBrowse:SetFilterDefault( cFiltro )

	oBrowse:AddLegend("ZA2->ZA2_STAT == 'C' .AND. ZA2->ZA2_SITSLD == 'S'"	, "GREEN"	, "Ordem Confirmada", "1")
	oBrowse:AddLegend("ZA2->ZA2_STAT == 'C' .AND. ZA2->ZA2_SITSLD == 'N'"	, "RED"		, "Ordem Confirmada - sem saldo", "1")
	oBrowse:AddLegend("ZA2->ZA2_STAT == 'P' .AND. ZA2->ZA2_SITSLD == 'S'"	, "BLUE"	, "Ordem Planejada", "1")
	oBrowse:AddLegend("ZA2->ZA2_STAT == 'P' .AND. ZA2->ZA2_SITSLD == 'N'"	, "PINK"	, "Ordem Planejada - sem saldo", "1")
	oBrowse:Activate()

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

	oModel:=MPFormModel():New  ("PL230M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)

	oModel:AddFields("FORMZA2",/*cOwner*/,oStZA2)
	oModel:SetPrimaryKey({'ZA2_FILIAL', 'ZA2_TIPO', 'ZA2_RECURS', 'ZA2_DTINIP', 'ZA2_PROD', 'ZA2_OPER'})
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
  Verifica se tem saldo dos componentes
 *---------------------------------------------------------------------*/
Static Function SaldoComp()
	Local lTem		:= .F.
	Local lRet		:= .T.
	Local nQtNec	:= 0

	ZA2->(DBSetOrder(2)) // ZA2_FILIAL+ZA2_TIPO+ZA2_PRIOR+ZA2_DATPRI+ZA2_OP+ZA2_OPER
	ZA2->(DbGoTop())
	
	While ("ZA2")->(! EOF()) .and. ZA2->ZA2_TIPO == "1"
		lTem := .T.
		nQtNec 	:= ZA2->ZA2_QUANT - ZA2->ZA2_QUJE

		lRet := Estrutura(ZA2->ZA2_PROD, nQtNec)

		if lRet	== .F.		// falta algum componente
			RecLock("ZA2", .F.)
			ZA2->ZA2_SITSLD := "N"
			ZA2->(MsUnLock())
		endif

		ZA2->(DbSkip())
	enddo

	if lTem == .F.
	 	u_PL230Calculo()
	endif
return

/*---------------------------------------------------------------------*
  Atualiza situacao da OP
 *---------------------------------------------------------------------*/
Static Function SituacaoOP()
	Local cSql		:= ""
	Local cAlias	:= ""

	cSql := "SELECT C2_OP, C2_XPRTOP, C2_XPRTPL "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("ZA2") + " ZA2 "
	csQL += "	 ON ZA2_OP			 =  C2_OP "
	cSql += "   AND ZA2_TIPO 		 = '1'"
	cSql += "   AND (ZA2_PRTOP 		<> C2_XPRTOP OR ZA2_PRTPL <> C2_XPRTPL) "
	cSql += "   AND ZA2_FILIAL 		 = '" + xFilial("ZA2") + "' "
	cSql += "   AND ZA2.D_E_L_E_T_ 	 = ' ' "

	cSql += " WHERE C2_FILIAL 		 = '" + xFilial("SC2") + "' "
	cSql += "   AND SC2.D_E_L_E_T_ 	 = ' ' "
	cAlias := MPSysOpenQuery(cSql)

	ZA2->(DBSetOrder(7)) // Tipo/OP/Operacao

	While (cAlias)->(!EOF())

		If ZA2->(MsSeek(xFilial("ZA2") + "1" + (cAlias)->C2_OP))
			RecLock("ZA2", .F.)
			ZA2->ZA2_PRTOP := (cAlias)->C2_XPRTOP
			ZA2->ZA2_PRTPL := (cAlias)->C2_XPRTPL
			ZA2->(MsUnLock())
		EndIf

		(cAlias)->(DbSkip())
	EndDo

	(cAlias)->(DBCLOSEAREA())
return

/*---------------------------------------------------------------------*
  Atualiza a ordem de producao
 *---------------------------------------------------------------------*/
Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk			:= .T.
	Local nOperation 	:=	oModel:GetOperation()
 
	If nOperation == MODEL_OPERATION_UPDATE
		SC2->(dbSetOrder(1))

		If SC2->(MsSeek(xFilial("SC2") + M->ZA2_OP))
			RecLock("SC2", .F.)
			SC2->C2_XDTINIP := M->ZA2_DTINIP
			SC2->C2_XDTFIMP := M->ZA2_DTFIMP
			SC2->C2_XHRINIP := M->ZA2_HRINIP
			SC2->C2_XHRFIMP := M->ZA2_HRFIMP
			MsUnLock()
		endif
	EndIf

	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Calcula o sequenciamento
 *---------------------------------------------------------------------*/
User Function PL230Calculo()
	u_PL230A(dDtIni, dDtFim)
	SaldoComp()
	SituacaoOP()
return


/*---------------------------------------------------------------------*
  Explode a estrutura para calcular o saldo de materia prima
 *---------------------------------------------------------------------*/
Static Function	Estrutura(cProduto, nQtPai)
	Local lRet		:= .T.
	Local cSql 		:= ""
	Local nQtNec 	:= 0
	Local cAliasSG1
	Local cAliasSB2

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM "
	cSql += "  FROM " + RetSQLName("SG1") + " SG1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON B1_COD			=  G1_COMP "
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += " WHERE G1_COD 			= '" + cProduto + "' "
	cSql += "   AND G1_INI 		   <= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FIM 		   >= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FILIAL 		= '" + xFilial("SG1") + "' "
	cSql += "   AND SG1.D_E_L_E_T_ 	= ' ' "
	cAliasSG1 := MPSysOpenQuery(cSql)

	While (cAliasSG1)->(!EOF())
		nQtNec := nQtPai * (cAliasSG1)->G1_QUANT

		// Ler o saldo do componente
		cSql := "SELECT B2_QATU FROM " + RetSQLName("SB2") + " SB2 "
		cSql += " WHERE B2_COD    		=  '" + (cAliasSG1)->G1_COMP + "'"
		cSql += "   AND B2_FILIAL 		=  '" + xFilial("SB2") + "'"
		cSql += "   AND SB2.D_E_L_E_T_  <> '*' "
		cAliasSB2 := MPSysOpenQuery(cSql)

		if nQtNec > (cAliasSB2)->B2_QATU
			lRet := .F.
		endif

		(cAliasSB2)->(DBCLOSEAREA())
		(cAliasSG1)->(DbSkip())
	EndDo

	(cAliasSG1)->(DBCLOSEAREA())
return lRet


/*---------------------------------------------------------------------*
  Emite Programa de Produca
 *---------------------------------------------------------------------*/
User Function u_PL230Plano()
	u_PL250()
return

/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL230Legenda()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ordem confirmada"})
    AAdd(aLegenda,{"BR_VERMELHO","Ordem confirmada - sem saldo de componente ou MP"})
    AAdd(aLegenda,{"BR_AZUL","Ordem Planejada"})
    AAdd(aLegenda,{"BR_PINK","Ordem Planejada - sem saldo"})
    BrwLegenda("Registros", "Tipo", aLegenda)
return


/*---------------------------------------------------------------------*
  Firmar as OPs selecionadas
 *---------------------------------------------------------------------*/
User Function PL230Mark(cAcao)
	Local aArea    	:= GetArea()
	Local cMarca   	:= oBrowse:Mark()

	ZA2->(DbGoTop())

	While !ZA2->(EoF())
		If oBrowse:IsMark(cMarca)
			RecLock('ZA2', .F.)
			ZA2_OK := ''

			// Libera a ordem
			if cAcao == "L"
				if ZA2->ZA2_STAT == 'C'
					ZA2->ZA2_STAT := 'P'
				else
					ZA2->ZA2_STAT := 'C'
				endif

				SC2->(dbSetOrder(1))

				If SC2->(MsSeek(xFilial("SC2") + AllTrim(ZA2->ZA2_OP)))
					RecLock("SC2", .F.)
					SC2->C2_XCONF := ZA2->ZA2_STAT
					MsUnLock()
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
	ObterDados()

	oBrowse:CleanFilter()
	oBrowse:SetFilterDefault(cFiltro)
	oBrowse:Refresh()
return


Static Function ObterDados
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

	SaldoComp()
	SituacaoOP()
return
