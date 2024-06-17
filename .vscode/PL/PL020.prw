#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL020
Função: Manutenção de pedido EDI do cliente
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL020()
/*/

Static cTitulo := "EDI - Pedidos de Clientes"

User Function PL020()
	Local oBrowse

	chkFile("ZA0")
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetDescription(cTitulo)
	oBrowse:AddLegend("ZA0->ZA0_STATUS == '0'", "GREEN", "Ativo")
	oBrowse:AddLegend("ZA0->ZA0_STATUS == '1'", "YELLOW", "Com erro")
	oBrowse:AddLegend("ZA0->ZA0_STATUS == '9'", "RED", "Inativo")
	oBrowse:Activate()
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 
	ADD OPTION aRot TITLE 'Incluir'    	  ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_INSERT ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    	  ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_DELETE ACCESS 0 
	ADD OPTION aRot TITLE 'Importar EDI'  ACTION 'U_PL020B()'    OPERATION 5 					  ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Demanda' ACTION 'U_PL020C()'    OPERATION 6 					  ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Pedidos' ACTION 'U_PL020D()'    OPERATION 7 					  ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStZA0   := FWFormStruct(1, "ZA0")
 
	oStZA0:SetProperty('ZA0_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_LOJA'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ARQUIV',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ORIGEM',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ITCLI' ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Date()'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Time()'))

	oModel:=MPFormModel():New("PL020M",  {|oModel| MVCMODELPRE(oModel)}, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMZA0",/*cOwner*/,oStZA0)
	oModel:SetPrimaryKey({'ZA0_FILIAL','ZA0_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMZA0"):SetDescription("Formulario do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL020")      
    Local oStZA0 := FWFormStruct(2, "ZA0")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZA0", oStZA0, "FORMZA0")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_ZA0', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_ZA0","TELA")

Return oView


Static Function MVCMODELPRE(oModel)
    Local xRet  := .T.
 	Local nOperation :=	oModel:GetOperation()

    If nOperation == MODEL_OPERATION_UPDATE
		If M->ZA0_STATUS == "9"
			FWAlertError("PEDIDO JA FOI GERADO E NAO PODE SER ALTERADO!", "Pedido EDI")
			xRet  := .F.
		EndIf
    EndIf
Return xRet


Static Function MVCMODELPOS(oModel)
	Local lOk	:= .T.

	SA1->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SA7->(dbSetOrder(1))    // Filial,Cliente,Loja,Produto
	DA1->(dbSetOrder(1))    // Filial,Tabela,Produto,xxxxxxxxxxx

	If SA1->(! MsSeek(xFilial("SA1") + M->ZA0_CLIENT + M->ZA0_LOJA))
		FWAlertError("CLIENTE NAO CADASTRADO!", "Cadastro de clientes")
     	lOk  := .F.
	else
		If SB1->(! MsSeek(xFilial("SB1") + M->ZA0_PRODUT))
			FWAlertError("ITEM NAO CADASTRADO!", "Cadastro de itens")
	     	lOk  := .F.
		else
			// Verificar a relacao Item X Cliente
			If SA7->(! MsSeek(xFilial("SA7") + M->ZA0_CLIENT + M->ZA0_LOJA + M->ZA0_PRODUT))
				FWAlertError("PRODUTO CLIENTE NAO CADASTRADO", "Cadastro Produto/Cliente")
    		 	lOk  := .F.
			else
				// Verificar a tabela de precos do cliente
			  	If DA1->(! MsSeek(xFilial("DA1") + SA1->A1_TABELA + M->ZA0_PRODUT, .T.))
					if DA1->DA1_CODPRO == M->ZA0_PRODUT .AND. DA1->DA1_CODTAB == SA1->A1_TABELA
					else
						Help('',1,'Tabela de precos',,'TABELA DE PRECO NAO ENCONTRADA',1,0,,,,,,{"Cadastre a tabela de preco para o item"}) 
     					lOk  := .F.
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	oField := oModel:GetModel("FORMZA0")

	if lOk == .F.
		xRet := oField:LoadValue("ZA0_STATUS","1")
	else
		xRet := oField:LoadValue("ZA0_STATUS","0")
	EndIf
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function ProLeg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return


