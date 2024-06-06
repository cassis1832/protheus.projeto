#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL030
Função: Consulta de planejamento por cliente
@author Assis
@since 23/05/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL030()
/*/

Static cTitulo := "Planejamento por cliente"

User Function PL030()

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
	ADD OPTION aRot TITLE 'Consultar'  ACTION 'U_PL030Consulta()' OPERATION 5 ACCESS 0 
	
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()

    Local oModel   := Nil
    Local bPre     := Nil
    Local bPos     := Nil
    Local bCommit  := Nil
    Local bCancel  := Nil
    Local oStSA1   := FWFormStruct(1, "SA1")
 
	oStSA1:SetProperty('A1_COD'   ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSA1:SetProperty('A1_LOJA'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSA1:SetProperty('A1_NOME'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSA1:SetProperty('A1_NREDUZ',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL030PE",bPre, bPos,bCommit,bCancel) 
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
    Local oModel := FWLoadModel("PL030")      
    Local oStSA1 := FWFormStruct(2, "SA1")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SA1", oStSA1, "FORMSA1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SA1', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SA1","TELA")

Return oView


User Function PL030Consulta()
    U_PL030A(A1_COD, A1_LOJA)    
return
