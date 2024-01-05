#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//Variáveis Estáticas
Static cTitulo := "EDI - Pedidos de Clientes"

/*/{Protheus.doc} PL020
Função Manutenção de pedido EDI do cliente
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL020()
/*/

User Function PL020()
	
	Local aArea := GetNextAlias()
	Local oBrowse
	
	oBrowse:=FWMBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetMenuDef("PL020")
	oBrowse:SetDescription(cTitulo)
	/*
	oBrowse:AddLegend("SZ9->Z9_Status == '1'", "GREEN", "Ativo")
   	oBrowse:AddLegend("SZ9->Z9_Status == '2'", "RED", "Inativo")
	*/
	oBrowse:Activate()
	
	RestArea(aArea)

Return Nil

/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Carlos Assis                                                 |
 | Data:  05/01/2024                                                   |
 | Desc:  Criação do menu MVC                                          |
 *---------------------------------------------------------------------*/

Static Function MenuDef()

	Local aRot := {}
	
	//Adicionando opções
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5


Return aRot

/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Carlos Assis                                                 |
 | Data:  05/01/2024                                                   |
 | Desc:  Criação do modelo de dados MVC                               |
 *---------------------------------------------------------------------*/

Static Function ModelDef()

	Local oModel 	:= Nil
	Local oStPai 	:= FWFormStruct(1, 'ZA0')
	Local oStFilho 	:= FWFormStruct(1, 'ZA1')
	Local aZA1Rel	:= {}
	
	//Definições dos campos
	oStPai : SetProperty('ZA0_NUMPED',   	MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))                                 //Modo de Edição
	oStPai : SetProperty('ZA0_NUMPED',   	MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'GetSXENum("ZA0", "ZA0_NUMPED")'))      //Ini Padrão
	oStPai : SetProperty('ZA0_CLIENT',   	MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   'ExistCpo("SA1", M->ZA0_CLIENT)'))      //Validação de Campo

	oStFilho : SetProperty('ZA1_NUMPED', 	MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))                                 //Modo de Edição
	oStFilho : SetProperty('ZA1_NUMPED', 	MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
	oStFilho : SetProperty('ZA1_PRODUT', 	MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
	oStfILHO : SetProperty('ZA0_PRODUT', 	MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   'ExistCpo("SB1", M->ZA1_PRODUT)'))      //Validação de Campo
	oStFilho : SetProperty('ZA1_DTENTR', 	MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
	oStFilho : SetProperty('ZA1_QUANTI', 	MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
	oStFilho : SetProperty('ZA1_SEQ', 		MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'u_zSeq()'))                         	//Ini Padrão
	
	//Criando o modelo e os relacionamentos
	oModel := MPFormModel():New('PL020M')
	oModel : AddFields('ZA0MASTER',, oStPai)
	oModel : AddGrid('ZA1DETAIL','ZA0MASTER',oStFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence
	
	//Fazendo o relacionamento entre o Pai e Filho
	aAdd(aZA1Rel, {'ZA1_FILIAL','ZA0_FILIAL'})
	aAdd(aZA1Rel, {'ZA1_NUMPED','ZA0_NUMPED'})
	
	oModel : SetRelation('ZA1DETAIL', aZA1Rel, ZA1->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado
	oModel : GetModel('ZA1DETAIL') : SetUniqueLine({"ZA1_DESC"})	//Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
	oModel : SetPrimaryKey({})
	
	//Setando as descrições
	oModel : SetDescription("Grupo de Produtos - Mod. 3")
	oModel : GetModel('ZA0MASTER'):SetDescription('Pedido')
	oModel : GetModel('ZA1DETAIL'):SetDescription('Linhas')
	
Return oModel

/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Carlos Assis                                                 |
 | Data:  03/09/2016                                                   |
 | Desc:  Criação da visão MVC                                         |
 *---------------------------------------------------------------------*/

Static Function ViewDef()
	Local oView		:= Nil
	Local oModel	:= FWLoadModel('PL020')
	Local oStPai	:= FWFormStruct(2, 'ZA0')
	Local oStFilho	:= FWFormStruct(2, 'ZA1')
	
	//Criando a View
	oView := FWFormView():New()
	oView:SetModel(oModel)
	
	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_ZA0',oStPai,'ZA0MASTER')
	oView:AddGrid('VIEW_ZA1',oStFilho,'ZA1DETAIL')
	
	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',30)
	oView:CreateHorizontalBox('GRID',70)
	
	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_ZA0','CABEC')
	oView:SetOwnerView('VIEW_ZA1','GRID')
	
	//Habilitando título
	oView:EnableTitleView('VIEW_ZA0','Cabeçalho - Pedido')
	oView:EnableTitleView('VIEW_ZA1','Grid - Linhas')
	
	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})
	
	//Remove os campos de Código do Artista e CD
	//oStFilho:RemoveField('ZA1_CODART')
	//oStFilho:RemoveField('ZA1_NUMPED')
Return oView

/*/{Protheus.doc} zIniMus
Função que inicia o código sequencial da grid
@type function
@author Assis
@since 03/09/2016
@version 1.0
/*/

User Function zSeq()
	Local aArea 		:= GetArea()
	Local cCod  		:= StrTran(Space(TamSX3('ZA1_SEQ')[1]), ' ', '0')
	Local oModelPad  	:= FWModelActive()
	Local oModelGrid 	:= oModelPad:GetModel('ZA1DETAIL')
	Local nOperacao  	:= oModelPad:nOperation
	Local nLinAtu    	:= oModelGrid:nLine
	Local nPosCod    	:= aScan(oModelGrid:aHeader, {|x| AllTrim(x[2]) == AllTrim("ZA1_SEQ")})
	
	//Se for a primeira linha
	If nLinAtu < 1
		cCod := Soma1(cCod)
	
	//Senão, pega o valor da última linha
	Else
		cCod := oModelGrid:aCols[nLinAtu][nPosCod]
		cCod := Soma1(cCod)
	EndIf
	
	RestArea(aArea)
Return cCod


User Function ProLeg()

    Local aLegenda := {}

    AAdd(aLegenda,{"BR_VERDE", "Ativo"})
    AAdd(aLegenda,{"BR_VERMELHO", "Inativo"})

    BrwLegenda("Registros", "Ativos/Inativos", aLegenda)
return

