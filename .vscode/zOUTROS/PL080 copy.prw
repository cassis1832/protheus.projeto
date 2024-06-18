#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL080
Função: Consulta de planejamento geraL por item
@author Assis
@since 18/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL080()
/*/

Static cTitulo := "Plano Geral Por Item"

User Function PL080()

	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SA1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()

Return Nil


/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar'  ACTION 'U_PL080Consulta()' OPERATION MODEL_OPERATION_VIEW ACCESS 0 
Return aRot


/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSA1   := FWFormStruct(1, "SA1")
 
	oModel:=MPFormModel():New("PL080PE",,,,) 
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
    Local oModel := FWLoadModel("PL080")      
    Local oStSA1 := FWFormStruct(2, "SA1")    

	oStSA1:RemoveField('A1_NOME')

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SA1", oStSA1, "FORMSA1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SA1', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
	oView:RemoveField('A1_NOME')
    oView:SetOwnerView("VIEW_SA1","TELA")
Return oView


User Function PL080Consulta()
    U_PL080A(A1_XGRCLI)    
return
