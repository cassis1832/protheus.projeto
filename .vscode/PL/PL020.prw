#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL020
Função Manutenção de pedido EDI do cliente
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL020()
/*/

Static cTitulo := "EDI - Pedidos de Clientes"

User Function PL020()
	Local oBrowse

	chkFile("ZA0")
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetDescription(cTitulo)

	oBrowse:AddLegend("ZA0->ZA0_Status == '0'", "GREEN", "Ativo")
	oBrowse:AddLegend("ZA0->ZA0_Status == '1'", "YELLOW", "Com erro")
	oBrowse:AddLegend("ZA0->ZA0_Status == '9'", "RED", "Inativo")

	oBrowse:Activate()

Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()

	Local aRot := {}
	
	//Adicionando opções
	ADD OPTION aRot TITLE 'Visualizar' 		ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_VIEW    ACCESS 0 
	ADD OPTION aRot TITLE 'Incluir'    		ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_INSERT  ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    		ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_UPDATE  ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    		ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_DELETE  ACCESS 0 
	ADD OPTION aRot TITLE 'Importar EDI' 	ACTION 'U_PL020B()'    OPERATION 5 					   	   ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Demanda'	ACTION 'U_PL020C()'    OPERATION 6 					   	   ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Pedidos'	ACTION 'U_PL020D()'    OPERATION 7 					      	ACCESS 0 
	ADD OPTION aRot TITLE 'Legenda'    		ACTION 'u_ProLeg' 	  OPERATION 8     				   	Access 0       

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
	Local oStZA0   := FWFormStruct(1, "ZA0")

	oStZA0:SetProperty('ZA0_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_LOJA'  ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStZA0:SetProperty('ZA0_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ARQUIV',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ORIGEM',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('ZA0_ITCLI' ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oStZA0:SetProperty('ZA0_DTCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Date()'))
	oStZA0:SetProperty('ZA0_HRCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,'Time()'))
	oStZA0:SetProperty('ZA0_STATUS',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_INIPAD,'0'))

	oModel:=MPFormModel():New("PL020PE",bPre, bPos,bCommit,bCancel) 

	oModel:AddFields("FORMZA0",/*cOwner*/,oStZA0)
	oModel:SetPrimaryKey({'ZA0_FILIAL','ZA0_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMZA0"):SetDescription("Formulario do Cadastro "+cTitulo)

Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL020")      // Busca o Model do ZA0
	oView := FWFormView():New()               // Instancia o objeto
	   
   Local oStZA0 := FWFormStruct(2, "ZA0")    // Faz a carga dos campos do ZA0 do dicionário - pode se usar um terceiro parametro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZA0_NOME|SZA0_DTAFAL|'}
	
	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView:SetModel(oModel)
	
	//Atribuindo formularios para interface
	oView:AddField("VIEW_ZA0", oStZA0, "FORMZA0")
	
	//Criando um container com nome tela com 100%
	oView:CreateHorizontalBox("TELA",100)
	
	//Colocando titulo do formulario
	oView:EnableTitleView('VIEW_ZA0', 'Dados - '+cTitulo )  
	
	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})
	
	//O formul�rio da interface ser� colocado dentro do container
	oView:SetOwnerView("VIEW_ZA0","TELA")

Return oView



/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function ProLeg()
   
   Local aLegenda := {}
   
   AAdd(aLegenda,{"BR_VERDE","Ativo"})
	AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
	AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
   
   BrwLegenda("Registros", "Status", aLegenda)

return
