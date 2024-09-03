#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL180
Função: Geração de pedido de venda com base no pedido EDI - V02
@author Assis
@since 27/08/2024	
@version 1.0
	@return Nil, Fução não tem retorno
/*/

Static cTitulo := "Geracao de Pedidos de Vendas"

User Function PL180()
	Local cCondicao		:= ''

	Private oBrowse
	Private cCliente    := ''
	Private cLoja       := ''
	Private dLimite     := Date()
	Private cMarca 		:= GetMark()

	u_PL180F12()

	oBrowse := FWMarkBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetDescription(cTitulo)

	oBrowse:SetOnlyFields({'ZA0_CLIENT','ZA0_LOJA', 'ZA0_PRODUT', 'ZA0_DESCR', 'ZA0_ITCLI', 'ZA0_DTENTR', 'ZA0_HRENTR', 'ZA0_QTDE', 'ZA0_QTSEL', 'ZA0_SLDEST', 'ZA0_QTCONF'})

	//oBrowse:SetSemaphore(.T.) - não pode usar
	oBrowse:SetFieldMark( 'ZA0_OK' )
	oBrowse:SetMark(cMarca, "ZA0", "ZA0_OK")
	oBrowse:SetAllMark( { || oBrowse:AllMark() } )

	cCondicao := "ZA0_STATUS=='0' "
	cCondicao += ".and. ZA0_CLIENT == '" + cCliente + "' "
	cCondicao += ".and. ZA0_LOJA   == '" + cLoja + "' "
	cCondicao += ".and. ZA0_DTENTR <= '" + dtos(dLimite) + "'"
	cCondicao += ".and. ZA0_TIPOPE == 'F'"
	oBrowse:SetFilterDefault( cCondicao )

	//Setando Legenda
	oBrowse:AddLegend( "ZA0->ZA0_SLDEST <=  0"								, "RED"		,"Item sem saldo" )
	oBrowse:AddLegend( "ZA0->ZA0_SLDEST >= ZA0->ZA0_QTDE - ZA0->ZA0_QTCONF"	, "GREEN"	,"Saldo suficiente" )
	oBrowse:AddLegend( "ZA0->ZA0_SLDEST <  ZA0->ZA0_QTDE - ZA0->ZA0_QTCONF"	, "YELLOW"	,"Saldo insuficiente" )

	oBrowse:Activate()

	SetKey( VK_F12,  {|| u_PL180F12()    } )
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL180' 	OPERATION 2 ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL180' 	OPERATION 4 ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    	  ACTION 'VIEWDEF.PL180' 	OPERATION 5 ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Pedidos' ACTION 'u_PL180Mark()'	OPERATION 6 ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_PL180Leg' 	 	OPERATION 8 Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStZA0   := FWFormStruct(1, "ZA0")

	// Proteger de alteracoes
	oStZA0:SetProperty('ZA0_PRODUT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ITCLI'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_DTENTR'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_HRENTR'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_QTDE'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_SLDEST'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_TIPOPE'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_NUMPED'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_NUM'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_STATUS'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_QTCONF'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL180M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)
	oModel:AddFields("FORMZA0",/*cOwner*/,oStZA0)
	oModel:SetPrimaryKey({'ZA0_FILIAL','ZA0_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMZA0"):SetDescription("Formulario do Cadastro "+cTitulo)
	//oModel:GetModel("FORMZA0"):SetLoadFilter(, " ZA0_STATUS == '0' " )
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL180")      

    Local oStZA0 := FWFormStruct(2, "ZA0")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZA0", oStZA0, "FORMZA0")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_ZA0', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_ZA0","TELA")

Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk	:= .T.

	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL180Leg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return


/*---------------------------------------------------------------------*
  Parametros
 *---------------------------------------------------------------------*/
User Function PL180F12()
	Local aPergs        := {}
	Local aResps	    := {}
	Local lRet 			:= .T.

	AAdd(aPergs, {1, "Informe o cliente ", CriaVar("ZA0_CLIENT",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a loja "   , CriaVar("ZA0_LOJA",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite ", CriaVar("ZA0_DTENTR",.F.),,,"ZA0",, 50, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cCliente := aResps[1]
		cLoja    := aResps[2]
		dLimite  := aResps[3]
	Else
		lRet := .F.
		return lRet
	endif

	if dLimite > DaySum(date(),3)
		FWAlertError("EM PERIODO DE HOMOLOGACAO NAO GERAR PEDIDOS PARA MAIS DE 3 DIAS")
		lRet := .f.
	endif

	SA1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA1->(dbSetOrder(1))

	// Verificar o cliente
	if SA1->(! MsSeek(xFilial("SA1") + cCliente + cLoja))
		lRet := .F.
		FWAlertError("Cliente nao cadastrado: " + cCliente,"Cadastro de Clientes")
	else
		// Verificar condição de pagamento do cliente
		If SE4->(! MsSeek(xFilial("SE4") + SA1->A1_COND))
			lRet := .F.
			FWAlertError("Cliente sem condicao de pagamento cadastrada: " + cCliente,"Condicao de Pagamento")
		EndIf

		// Verificar a tabela de precos do cliente
		If SA1->A1_TABELA == ""
			lRet := .F.
			FWAlertError("Tabela de precos do cliente nao encontrada!", "Tabela de precos")
		EndIf
	EndIf

	CalcSaldo()
return lRet


/*---------------------------------------------------------------------*
  Atualiza o saldo de estoque disponivel nos ZA0 filtrados
 *---------------------------------------------------------------------*/
Static Function CalcSaldo()
	Local cSql		:= ""

	cSql := "UPDATE " + RetSQLName("ZA0")
	cSql += "   SET ZA0_QTSEL  = ZA0_QTDE - ZA0_QTCONF, "
	cSql += "       ZA0_SLDEST = ("
	cSql += "		SELECT SUM(B2_QATU) FROM " + RetSQLName("SB2") + " SB2 "
	cSql += " 		 WHERE B2_COD    		=  ZA0_PRODUT "
	cSql += "   	   AND B2_FILIAL 		=  '" + xFilial("SB2") + "'"
	cSql += "   	   AND SB2.D_E_L_E_T_  <> '*' "
	cSql += "   	 GROUP BY B2_COD)"

	cSql += "  FROM " + RetSQLName("ZA0") + " ZA0 "
	cSql += " WHERE ZA0_CLIENT 		 = '" + cCliente + "'"
	cSql += "   AND ZA0_LOJA   		 = '" + cLoja + "'"
	cSql += "   AND ZA0_STATUS       = '0'"
	cSql += "   AND ZA0_DTENTR      <= '" + dtos(dLimite) + "'"
	cSql += "   AND ZA0_FILIAL     	 =  '" + xFilial("ZA0") + "'"
	cSql += "   AND ZA0.D_E_L_E_T_  <> '*' "

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução da query:", "Atenção")
		MsgInfo(TcSqlError(), "Atenção3")
	endif
return


/*---------------------------------------------------------------------*
  Prepara os registros marcados no checkbox
 *---------------------------------------------------------------------*/
User Function PL180Mark()
	Local aArea    	:= GetArea()
	Local cMarca   	:= oBrowse:Mark()
	// Local lInverte := oBrowse:IsInvert()
	Local nCt      	:= 0
	Local aPedidos 	:= {}

	SA7->(dbSetOrder(1))    // Filial,Cliente,Loja,Produto

	ZA0->(DbGoTop())

	While !ZA0->(EoF())
		If oBrowse:IsMark(cMarca)
			nCt++

			If SA7->(MsSeek(xFilial("SA7") + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA + ZA0->ZA0_PRODUT))
				if ZA0_QTSEL <> 0
					aadd(aPedidos,{ZA0->ZA0_CODPED, ZA0->ZA0_CLIENT, ZA0->ZA0_LOJA, ZA0->ZA0_PRODUT, dtos(ZA0->ZA0_DTENTR), ZA0->ZA0_HRENTR, ZA0->ZA0_QTSEL, SA7->A7_XNATUR, SA7->A7_XGRUPV})
				endif
			EndIf

			//Limpando a marca
			RecLock('ZA0', .F.)
			ZA0_OK := ''
			ZA0->(MsUnlock())
		EndIf

		ZA0->(DbSkip())
	EndDo

	//MsgInfo('Foram marcadas <b>' + cValToChar( nCt ) + ' linhas</b>.', "Atenção")

	if len(aPedidos) > 0
		u_PL180A(aPedidos)
	endif

	RestArea(aArea)
Return NIL
