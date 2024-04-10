#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL020
Fun��o Manuten��o de pedido EDI do cliente - Modelo 2
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Fun��o n�o tem retorno
	@example
	u_PL020()
/*/

Static cTitulo := "EDI - Pedidos de Clientes"

User Function PL020()
	Local aArea   := GetArea()
	Local cFunBkp := FunName()
	Local oBrowse

	SetFunName("PL020")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetDescription(cTitulo)

	oBrowse:AddLegend("ZA0->ZA0_Status == '0'", "GREEN", "Ativo")
	oBrowse:AddLegend("ZA0->ZA0_Status == '1'", "YELLOW", "Com erro")
	oBrowse:AddLegend("ZA0->ZA0_Status == '9'", "RED", "Inativo")

	oBrowse:Activate()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return Nil

/*---------------------------------------------------------------------*
  Func:  MenuDef
  Autor: Carlos Assis
  Data:  05/01/2024
  Desc:  Cria��o do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}
	
	//Adicionando op��es
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_INSERT ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_DELETE ACCESS 0 
	ADD OPTION aRot TITLE 'Importar'   ACTION 'U_PL030()'     OPERATION 5 					   ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    ACTION 'u_ProLeg' 	  OPERATION 6     				   Access 0       

Return aRot

/*---------------------------------------------------------------------*
  Func:  ModelDef
  Autor: Carlos Assis
  Data:  05/01/2024
  Desc:  Cria��o do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()

	Local oModel := Nil
	Local oStZA0 := FWFormStruct(1, "ZA0")
	Local bCommit := {|| FazCommit()}

	oStZA0:SetProperty('ZA0_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_LOJA'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ARQUIV',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ORIGEM',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Date()'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Time()'))
	oStZA0:SetProperty('ZA0_STATUS',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_INIPAD,'0'))

	oModel := MPFormModel():New("PL020M",/*bPre*/, /*bPos*/,bCommit,/*bCancel*/) 
	oModel:AddFields("FORMZA0",/*cOwner*/,oStZA0)
	oModel:SetPrimaryKey({'ZA0_FILIAL','ZA0_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMZA0"):SetDescription("Formul�rio do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
  Func:  ViewDef
  Autor: Carlos Assis
  Data:  05/01/2024
  Desc:  Cria��o da vis�o MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL020")
	Local oStZA0 := FWFormStruct(2, "ZA0")  //pode se usar um terceiro par�metro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZA0_NOME|SZA0_DTAFAL|'}
	
	//Criando a view que ser� o retorno da fun��o e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	
	//Atribuindo formul�rios para interface
	oView:AddField("VIEW_ZA0", oStZA0, "FORMZA0")
	
	//Criando um container com nome tela com 100%
	oView:CreateHorizontalBox("TELA",100)
	
	//Colocando t�tulo do formul�rio
	oView:EnableTitleView('VIEW_ZA0', 'Dados - '+cTitulo )  
	
	//For�a o fechamento da janela na confirma��o
	oView:SetCloseOnOk({||.T.})
	
	//O formul�rio da interface ser� colocado dentro do container
	oView:SetOwnerView("VIEW_ZA0","TELA")

Return oView

Static Function FazCommit()
    Local aArea  := FWGetArea()
    Local oModel := FWModelActive()
    Local lRet   := .T.
 
    //Aqui voc� pode fazer as opera��es antes de gravar
	lOK:= oModel:LoadValue("FORMZA0","ZA0_STATUS","0")

	//Aciona o commit dos dados preenchidos no formul�rio
	FWFormCommit(oModel)

	//Aqui voc� pode fazer as opera��es ap�s gravar

	FWRestArea(aArea)
Return lRet


/*---------------------------------------------------------------------*
  Func:  ProLeg
  Autor: Carlos Assis
  Data:  05/01/2024
  Desc:  Legendas
 *---------------------------------------------------------------------*/

User Function ProLeg()

    Local aLegenda := {}

    AAdd(aLegenda,{"BR_VERDE","Ativo"})
	AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
	AAdd(aLegenda,{"BR_VERMELHO","Inativo"})

    BrwLegenda("Registros", "Status", aLegenda)
return
