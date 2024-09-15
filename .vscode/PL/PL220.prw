#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL220
Função: Carga maquina SH8
@author Assis
@since 09/09/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL220()
/*/

Static cTitulo := "Carga Maquina"

User Function PL220()
	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SH8")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetOnlyFields({'H8_XPROD','H8_OP'})

	// oBrowse:AddLegend("SH8->SH8_STATUS == '0'", "GREEN", "Ativo")
	// oBrowse:AddLegend("SH8->SH8_STATUS == '1'", "YELLOW", "Com erro")
	// oBrowse:AddLegend("SH8->SH8_STATUS == '9'", "RED", "Inativo")
	oBrowse:Activate()
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL220' OPERATION 2   					  ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL220' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSH8   := FWFormStruct(1, "SH8")
 
	// oStSH8:SetProperty('SH8_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	// oStSH8:SetProperty('SH8_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL220M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMSH8",/*cOwner*/,oStSH8)
	oModel:SetPrimaryKey({'SH8_FILIAL','SH8_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSH8"):SetDescription("Formulario do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL220")      
    Local oStSH8 := FWFormStruct(2, "SH8")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SH8", oStSH8, "FORMSH8")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SH8', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SH8","TELA")

Return oView


Static Function MVCMODELPOS(oModel)
	Local lOk	:= .T.
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL220ProLeg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return
