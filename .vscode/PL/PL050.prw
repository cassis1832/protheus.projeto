#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL050
Função: Ordens de Produção por Linha
@author Assis
@since 07/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL050()
/*/

Static cTitulo := "Ordens de Producao Por Linha"

User Function PL050()

	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SC2")
	oBrowse:SetDescription(cTitulo)
	oBrowse:ForceQuitButton()
	oBrowse:Activate()

Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()

	Local aRot := {}
	//ADD OPTION aRot TITLE 'Excluir' ACTION 'VIEWDEF.PL050' OPERATION MODEL_OPERATION_DELETE ACCESS 0 

Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()

    Local oModel   := Nil
    Local oStSC2   := FWFormStruct(1, "SC2")
	oModel:=MPFormModel():New("PL050M")
	oModel:AddFields("FORMSC2",/*cOwner*/,oStSC2)
	//oModel:SetPrimaryKey({'SC2_FILIAL','SC2_TICKET','SC2_EVENTO','SC2_PRODUT','SC2_DOC','SC2_ITEM'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSC2"):SetDescription("Produção "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()

    Local oView  := Nil
    Local oModel := FWLoadModel("PL050")      
    Local oStSC2 := FWFormStruct(2, "SC2")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC2", oStSC2, "FORMSC2")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SC2', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SC2","TELA")

Return oView
