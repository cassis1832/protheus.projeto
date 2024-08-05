#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL040
Função: Consulta de eventos do MRP
@author Assis
@since 07/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL040()
/*/

Static cTitulo := "Eventos do MRP"

User Function PL040()

	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("HWM")
	oBrowse:SetDescription(cTitulo)
	oBrowse:ForceQuitButton()
	oBrowse:Activate()

Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()

	Local aRot := {}
	ADD OPTION aRot TITLE 'Excluir' ACTION 'VIEWDEF.PL040' OPERATION MODEL_OPERATION_DELETE ACCESS 0 

Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()

    Local oModel   := Nil
    Local oStHWM   := FWFormStruct(1, "HWM")
	oModel:=MPFormModel():New("PL040M")
	oModel:AddFields("FORMHWM",/*cOwner*/,oStHWM)
	oModel:SetPrimaryKey({'HWM_FILIAL','HWM_TICKET','HWM_EVENTO','HWM_PRODUT','HWM_DOC','HWM_ITEM'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMHWM"):SetDescription("Evento do MRP "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()

    Local oView  := Nil
    Local oModel := FWLoadModel("PL040")      
    Local oStHWM := FWFormStruct(2, "HWM")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_HWM", oStHWM, "FORMHWM")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_HWM', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_HWM","TELA")

Return oView
