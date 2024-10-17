#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} PL270
Função: Follow-up de compras	
@author Assis
@since 16/10/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL270()
/*/

Static cTitulo := "Follow-up de Compras"

User Function PL270()
	Local oBrowse
	Local cFiltro	:= ''

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SC7")
	//oBrowse:SetOnlyFields({'C2_NUM','C2_ITEM', 'C2_SEQUEN', 'C2_PRODUTO', 'C2_QUANT', 'C2_DATPRI', 'C2_DATPRF', 'C2_PRIOR', 'C2_STATUS'})

	cFiltro := "C7_QUANT > C7_QUJE .AND. C7_PRODUTO > '1' .AND. C7_PRODUTO < '5' .AND. LEN(alltrim(C7_PRODUTO)) > 5"

	oBrowse:SetDescription(cTitulo)
	oBrowse:SetFilterDefault( cFiltro )

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

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL270' OPERATION 2   					  ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL270' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0       
Return aRot


/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSC7 := FWFormStruct(1, "SC7")

//	oStSC7:SetProperty('C2_NUM',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL270M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMSC7",/*cOwner*/,oStSC7)
	oModel:SetPrimaryKey({'C7_FILIAL','C7_NUM','C7_ITEM','C7_SEQUEN'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSC7"):SetDescription(cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  	:= Nil
    Local oModel   	:= FWLoadModel("PL270")      
    Local oStSC7 	:= FWFormStruct(2, "SC7")    

//	oStSC7:RemoveField("C2_LOCAL")

    oView:= FWFormView():New()      
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC7", oStSC7, "FORMSC7")
    oView:CreateHorizontalBox("TELA",100)
    oView:SetOwnerView("VIEW_SC7","TELA")
    oView:EnableTitleView('VIEW_SC7', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})

Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()

	Local lOk	:= .T.
// 	Local nOperation :=	oModel:GetOperation()

	RestArea(aArea)
Return lOk
