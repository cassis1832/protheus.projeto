#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} PL050
Função: Ordens de Produção por Linha
@author Assis
@since 07/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL050()
/*/

Static cTitulo := "Ordens de Producao Estamparia"

User Function PL050()
	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SC2")
	oBrowse:SetOnlyFields({'C2_NUM','C2_ITEM', 'C2_SEQUEN', 'C2_PRODUTO', 'C2_QUANT', 'C2_DATPRI', 'C2_DATPRF', 'C2_PRIOR', 'C2_STATUS'})
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

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL050' OPERATION 2   					  ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL050' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSC2 := FWFormStruct(1, "SC2")

	oStSC2:SetProperty('C2_NUM',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL050M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMSC2",/*cOwner*/,oStSC2)
	oModel:SetPrimaryKey({'SC2_FILIAL','SC2_NUM','SC2_ITEM','SC2_SEQUEN'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSC2"):SetDescription("Produção "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  	:= Nil
    Local oModel   	:= FWLoadModel("PL050")      
    Local oStSC2 	:= FWFormStruct(2, "SC2")    

	oStSC2:RemoveField("C2_LOCAL")

    oView:= FWFormView():New()      
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC2", oStSC2, "FORMSC2")
    oView:CreateHorizontalBox("TELA",100)
    oView:SetOwnerView("VIEW_SC2","TELA")
    oView:EnableTitleView('VIEW_SC2', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})

Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()

	Local lOk	:= .T.
 	Local nOperation :=	oModel:GetOperation()

	RestArea(aArea)
Return lOk
