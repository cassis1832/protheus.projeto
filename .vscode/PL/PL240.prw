#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL240
	Carga máquina MR Gerencial
@author Carlos Assis
@since 22/07/2024
@version 1.0   
/*/

User Function PL240()
	Local oBrowse
	Local aPergs		:= {}
	Local aResps		:= {}

	Private cTitulo		:= "Carga Maquina MR"

	Private dDtIni  	:= ""
	Private dDtFim  	:= ""
	Private lEstamp 	:= .F.
	Private lSolda  	:= .F.
	Private cRecurso 	:= .F.

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Recurso"					, CriaVar("H1_CODIGO",.F.),,,"SH1",, 70, .F.})
	AAdd(aPergs, {4, "Estamparia"				,.T.,"Estamparia" ,90,"",.F.})
	AAdd(aPergs, {4, "Solda"					,.T.,"Solda" ,90,"",.F.})

	If ParamBox(aPergs, "CARGA MAQUINA MR", @aResps,,,,,,,, .T., .T.)
		dDtIni 		:= aResps[1]
		dDtFim 		:= aResps[2]
		cRecurso	:= aResps[3]
		lEstamp		:= aResps[4]
		lSolda		:= aResps[5]
	Else
		return
	endif

	chkFile("ZA2")

	ZA2->(DBSetOrder(2))

	If ! ZA2->(MsSeek(xFilial("ZA2") + "2"))
		u_PL240Calculo()
	endif

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZA2')
	oBrowse:AddLegend("ZA2->ZA2_TPOP == 'P'", "YELLOW", "Prevista", "1")
	oBrowse:AddLegend("ZA2->ZA2_TPOP == 'F' .and. ZA2->ZA2_SITSLD == 'N'", "RED", "Falta saldo de materia prima", "1")
	oBrowse:AddLegend("ZA2->ZA2_TPOP == 'F' .and. ZA2->ZA2_SITSLD == 'S'", "GREEN", "Em aberto", "1")
	oBrowse:SetDescription(cTitulo)

	cCondicao := "ZA2_TIPO == '2'"

	oBrowse:SetFilterDefault( cCondicao )
	oBrowse:DisableDetails()

	oBrowse:Activate()
return


Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar' 	  	ACTION 'VIEWDEF.PL240'  OPERATION 2 ACCESS 0
	ADD OPTION aRot TITLE 'Alterar'    	  	ACTION 'VIEWDEF.PL240'  OPERATION 4 ACCESS 0
	ADD OPTION aRot TITLE 'Legenda'    	  	ACTION 'u_PL240Legenda' OPERATION 8 ACCESS 0
	ADD OPTION aRot TITLE 'Calcular'   	  	ACTION 'u_PL240Calculo' OPERATION 8 ACCESS 0
	ADD OPTION aRot TITLE 'Imprimir Plano'  ACTION 'u_PL240Print' 	OPERATION 8 ACCESS 0
Return aRot


Static Function ModelDef()
	Local oModel := Nil
	Local oStZA2 := FWFormStruct(1,"ZA2")

	oStZA2:SetProperty('ZA2_OP',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_DATPRI',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_DATPRF',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_PROD',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_ITCLI',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_LE',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_OPER',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_QUANT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA2:SetProperty('ZA2_QUJE',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New  ("PL240M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)

	oModel:AddFields("FORMZA2",/*cOwner*/,oStZA2)
	oModel:SetPrimaryKey({'ZA2_FILIAL', 'ZA2_TIPO', 'ZA2_RECURS', 'ZA2_DTINIP', 'ZA2_PROD', 'ZA2_OPER'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMZA2"):SetDescription("Formulário do Cadastro ")
Return oModel


Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL240")
	Local oStZA2 := FWFormStruct(2, "ZA2")

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZA2", oStZA2, "FORMZA2")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_ZA2', 'DADOS DA ORDEM DE PRODUCAO')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_ZA2","TELA")
Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk			:= .T.
	Local nOperation 	:=	oModel:GetOperation()

	If nOperation == MODEL_OPERATION_UPDATE
	EndIf

	RestArea(aArea)
Return lOk


User Function PL240Calculo()
	u_PL240A(dDtIni, dDtFim)
return


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


User Function PL240Print()
	u_PL250("2")
return


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL240Legenda()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_AMARELO","Ordem ainda prevista - nao deve ser produzida"})
    AAdd(aLegenda,{"BR_VERDE","Em aberto - liberada"})
    AAdd(aLegenda,{"BR_VERMELHO","Falta saldo de materia prima ou componente"})
    BrwLegenda("Registros", "Tipo", aLegenda)
return

