#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL170
Função: Paradas de máquinas
@author Assis
@since 26/08/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL170()
/*/

Static cTitulo := "Paradas de Maquinas"

User Function PL170()
	Local oBrowse

	chkFile("ZA1")
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZA1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:AddLegend("ZA1->ZA1_STATUS == '0'", "GREEN", "Ativo")
	oBrowse:AddLegend("ZA1->ZA1_STATUS == '9'", "RED", "Encerrado")
	oBrowse:Activate()
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL170' OPERATION 2   					  ACCESS 0 
	ADD OPTION aRot TITLE 'Incluir'    	  ACTION 'VIEWDEF.PL170' OPERATION MODEL_OPERATION_INSERT ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL170' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    	  ACTION 'VIEWDEF.PL170' OPERATION MODEL_OPERATION_DELETE ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_PL170Leg' 	 OPERATION 8     				  Access 0       
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStZA1   := FWFormStruct(1, "ZA1")
 
	oStZA1:SetProperty('ZA1_DTCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Date()'))
	oStZA1:SetProperty('ZA1_HRCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Time()'))

	oModel:=MPFormModel():New("PL170M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMZA1",/*cOwner*/,oStZA1)
	oModel:SetPrimaryKey({'ZA1_FILIAL','ZA1_COD'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMZA1"):SetDescription("Formulario do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL170")      
    Local oStZA1 := FWFormStruct(2, "ZA1")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZA1", oStZA1, "FORMZA1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_ZA1', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_ZA1","TELA")

Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk	:= .T.
	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL170Leg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_VERMELHO","Encerrado"})
    BrwLegenda("Registros", "Status", aLegenda)
return
