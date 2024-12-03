#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL060
Função: Consulta de planejamento por item
@author Assis
@since 11/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL030()
/*/

Static cTitulo := "Planejamento por Item"

User Function PL060()

	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SB1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()

Return Nil


/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()

	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar'  ACTION 'U_PL060Consulta()' OPERATION 1 ACCESS 0 
	
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
    Local oStSB1   := FWFormStruct(1, "SB1")
 
	oStSB1:SetProperty('B1_COD'    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_DESC'   ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_TIPO'   ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_XCLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_XITEM'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_AGRECU' ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSB1:SetProperty('B1_MRP'    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL060PE",bPre, bPos,bCommit,bCancel) 
	oModel:AddFields("FORMSB1",/*cOwner*/,oStSB1)
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSB1"):SetDescription("Cliente "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()

    Local oView  := Nil
    Local oModel := FWLoadModel("PL060")      
    Local oStSB1 := FWFormStruct(2, "SB1")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SB1", oStSB1, "FORMSB1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SB1', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SB1","TELA")

Return oView


User Function PL060Consulta()
    bRes = U_PL060A(B1_COD)
return
