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
	
	Local aArea := GetArea()
	Local oBrowse
	
	oBrowse:=FWMBrowse():New()
	oBrowse:SetAlias("ZA0")
	oBrowse:SetMenuDef("PL020")
	oBrowse:SetDescription(cTitulo)
	
	oBrowse:AddLegend("ZA0->ZA0_Status == '1'", "GREEN", "Ativo")
   	oBrowse:AddLegend("ZA0->ZA0_Status == '2'", "RED", "Inativo")
	
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
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_INSERT ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.PL020' OPERATION MODEL_OPERATION_DELETE ACCESS 0 

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
	
	oStPai:SetProperty('ZA0_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStPai:SetProperty('ZA0_CLIENT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	oStPai:SetProperty('ZA0_DTCRIA',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	
	oStFilho:SetProperty('ZA1_CODPED',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))
	//oStFilho:SetProperty('ZA1_PRODUT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'INCLUI'))

	oStPai:SetProperty('ZA0_DTCRIA',MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()'))
	
	//Criando o modelo
	oModel := MPFormModel():New('PL020M')
	oModel:AddFields('ZA0MASTER',, oStPai)
	oModel:AddGrid('ZA1DETAIL','ZA0MASTER',oStFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence
	
	//Fazendo o relacionamento entre o Pai e Filho
	aAdd(aZA1Rel, {'ZA1_FILIAL','xFilial("ZA0")'})
	aAdd(aZA1Rel, {'ZA1_CODPED','ZA0_CODPED'})
	
	oModel:SetRelation('ZA1DETAIL', aZA1Rel, ZA1->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado
	oModel:GetModel('ZA1DETAIL'):SetUniqueLine({"ZA1_PRODUT", "ZA1_DTENTR"})	//Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
	oModel:SetPrimaryKey({})

	//Setando as descrições
	oModel:SetDescription("Grupo de Produtos - Mod. 3")
	oModel:GetModel('ZA0MASTER'):SetDescription('Pedido')
	oModel:GetModel('ZA1DETAIL'):SetDescription('Linhas')
	
Return oModel

/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Carlos Assis                                                 |
 | Data:  05/01/2024                                                   |
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
	
	//oStFilho:SetProperty('ZA1_DESC',MVC_VIEW_INIBROW,FwBuildFeature(STRUCT_FEATURE_INIPAD, 'GETADVFVAL("SB1",{"B1_DESC"},XFILIAL("SB1")+ZA1->ZA1_PRODUT,1,{"",""}))'))

	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_ZA0',oStPai,'ZA0MASTER')
	oView:AddGrid('VIEW_ZA1',oStFilho,'ZA1DETAIL')
	
	oView:AddIncrementField( 'VIEW_ZA1', 'ZA1_SEQ' )

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',30)
	oView:CreateHorizontalBox('GRID',70)
	
	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_ZA0','CABEC')
	oView:SetOwnerView('VIEW_ZA1','GRID')
	
	//Habilitando título
	oView:EnableTitleView('VIEW_ZA0','Cabeçalho - Pedido')
	oView:EnableTitleView('VIEW_ZA1','Grid - Linhas')
	
	//Remove os campos
	oStFilho:RemoveField('ZA1_CODPED')

	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})

Return oView

/*---------------------------------------------------------------------*
 | Func:  zSeq                                                         |
 | Autor: Carlos Assis                                                 |
 | Data:  05/01/2024                                                   |
 | Desc:  Sequencia das linhas do pedido                               |
 *---------------------------------------------------------------------*/

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


/*---------------------------------------------------------------------*
 | Func:  ProLeg                                                       |
 | Autor: Carlos Assis                                                 |
 | Data:  05/01/2024                                                   |
 | Desc:  Legendas  						                           |
 *---------------------------------------------------------------------*/

User Function ProLeg()

    Local aLegenda := {}

    AAdd(aLegenda,{"BR_VERDE", "Ativo"})
    AAdd(aLegenda,{"BR_VERMELHO", "Inativo"})

    BrwLegenda("Registros", "Ativos/Inativos", aLegenda)
return

