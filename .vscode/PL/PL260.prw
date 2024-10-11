#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL260
Função: Follow-up de materia prima e componentes
@author Assis
@since 08/10/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL260()
/*/

Static cTitulo := "Follow-up de materia prima e componentes"

User Function PL260()
	Local oBrowse
	Private cFiltro := ""

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SC7")
	oBrowse:SetDescription(cTitulo)

	cFiltro	:= " C7_QUJE < C7_QUANT .AND. C7_PRODUTO >= '1' .AND. C7_PRODUTO < '5' .AND. LEN(alltrim(C7_PRODUTO)) >= 7 "

	oBrowse:SetFilterDefault( cFiltro )

	// oBrowse:AddLegend("SC7->SC7_STATUS == '0'", "GREEN", "Ativo")
	// oBrowse:AddLegend("SC7->SC7_STATUS == '1'", "YELLOW", "Com erro")
	// oBrowse:AddLegend("SC7->SC7_STATUS == '9'", "RED", "Inativo")
	oBrowse:Activate()
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL260' OPERATION 2   					  ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSC7   := FWFormStruct(1, "SC7")
 
	// oStSC7:SetProperty('SC7_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL260M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMSC7",/*cOwner*/,oStSC7)
	oModel:SetPrimaryKey({'SC7_FILIAL','SC7_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSC7"):SetDescription("Formulario do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL260")      
    Local oStSC7 := FWFormStruct(2, "SC7")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC7", oStSC7, "FORMSC7")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SC7', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SC7","TELA")

Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL260Legenda()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return
