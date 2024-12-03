#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} FT020
Função: Geração de pedido de venda 
		Com base no pedido EDI 	- FT030
		Com base no estoque 	- FT040 (Gestamp)
@author Assis
@since 08/09/2024	
@version 1.0
	@return Nil, Fução não tem retorno
/*/
Static cTitulo := "Geracao de Pedido de Venda"

User Function FT020()
	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SA1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetMenuDef('FT020')
	oBrowse:Activate()
Return Nil


/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Gerar Pedidos'  ACTION 'U_FT020Gerar()' OPERATION MODEL_OPERATION_VIEW ACCESS 0 
Return aRot


/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSA1   := FWFormStruct(1, "SA1")
 
	oModel:=MPFormModel():New("FT020PE",,,,) 
	oModel:AddFields("FORMSA1",/*cOwner*/,oStSA1)
	oModel:SetPrimaryKey({'A1_FILIAL','A1_COD','A1_LOJA'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSA1"):SetDescription("Cliente "+cTitulo)
Return oModel


/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("FT020")      
    Local oStSA1 := FWFormStruct(2, "SA1")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SA1", oStSA1, "FORMSA1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SA1', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
	oView:RemoveField('A1_NOME')
    oView:SetOwnerView("VIEW_SA1","TELA")
Return oView


/*---------------------------------------------------------------------*
	Geracao dos pedidos de vendas do cliente selecionado
 *---------------------------------------------------------------------*/
User Function FT020Gerar()
	// Gestamp
	if SA1->A1_COD == '000004' .or. ;
		SA1->A1_COD == '000005' .or. ;
		SA1->A1_COD == '000006' .or. ;
		SA1->A1_COD == '000007'
		u_PL210(SA1->A1_COD, SA1->A1_LOJA)
	else
		u_PL180(SA1->A1_COD, SA1->A1_LOJA)
	endif
return
