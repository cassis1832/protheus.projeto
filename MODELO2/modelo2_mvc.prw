#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

Static cTitulo := "Cadastro cliente Portal cliente"

User Function FAETHC06()
	Local aArea   := GetArea()
	Local oBrowse

	SetFunName("FAETHC06")
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("PZ4")
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()

	RestArea(aArea)
Return Nil

Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.FAETHC06' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.FAETHC06' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.FAETHC06' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.FAETHC06' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
Return aRot

Static Function ModelDef()
	Local oModel   := Nil
	Local oStTmp   := FWFormModelStruct():New()
	Local oStFilho := FWFormStruct(1, 'PZ4')
	Local aPZ4Rel  := {}

	//Adiciona a tabela na estrutura tempor?ria
	oStTmp:AddTable('PZ4', {'PZ4_EMAIL','PZ4_PASS','PZ4_NOME'}, "Cabecalho PZ4")

	//Adiciona o campo de Descriç?o
	oStTmp:AddField(;
		"Email",;                                                                 // [01]  C   Titulo do campo
	"Email",;                                                                 // [02]  C   ToolTip do campo
	"PZ4_EMAIL",;                                                                 // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("PZ4_EMAIL")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,PZ4->PZ4_EMAIL,'')" ),;   // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual

	oStTmp:AddField(;
		"Senha",;                                                                 // [01]  C   Titulo do campo
	"Senha",;                                                                 // [02]  C   ToolTip do campo
	"PZ4_PASS",;                                                                 // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("PZ4_PASS")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.F.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,PZ4->PZ4_PASS,'')" ),;   // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual


	oStTmp:AddField(;
		"Nome cli",;                                                                 // [01]  C   Titulo do campo
	"Nome cli",;                                                                 // [02]  C   ToolTip do campo
	"PZ4_NOME",;                                                                 // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("PZ4_NOME")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.F.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,PZ4->PZ4_NOME,'')" ),;   // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual

	//Setando as propriedades na grid, o inicializador da Filial e Tabela, para n?o dar mensagem de coluna vazia
	oStTmp:SetProperty('PZ4_EMAIL', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"*"'))
	oStFilho:SetProperty('PZ4_PASS', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"***"'))


	//Criando o FormModel, adicionando o Cabeçalho e Grid
	oModel := MPFormModel():New("PZ40001M", , {|omodel| FAETHC06Ok(oModel)},{|oModel| CommitPZ4(oModel)})
	oModel:AddFields("FORMCAB",/*cOwner*/,oStTmp)
	oModel:AddGrid('PZ4DETAIL'	,'FORMCAB'	,oStFilho, , , , ,{|oModel|CargaPZ4(oModel)})

	//Adiciona o relacionamento de Filho, Pai
	aAdd(aPZ4Rel, {'PZ4_FILIAL', 'PZ4_FILIAL'} )
	aAdd(aPZ4Rel, {'PZ4_EMAIL' , 'PZ4_EMAIL'} )

	//Criando o relacionamento
	oModel:SetRelation('PZ4DETAIL', aPZ4Rel, PZ4->(IndexKey(1)))

	//Setando o campo ?nico da grid para n?o ter repetiç?o
//	oModel:GetModel('PZ4DETAIL'):SetUniqueLine({"PZ4_EMAIL","PZ4_FILCLI","PZ4_CODIGO","PZ4_LOJA"})


	//Setando outras informaç?es do Modelo de Dados
	oModel:SetDescription(cTitulo)
	oModel:SetPrimaryKey({})
	oModel:GetModel("FORMCAB"):SetDescription("Formul?rio do Cadastro "+cTitulo)


Return oModel

Static Function ViewDef()
	Local oModel     := FWLoadModel("FAETHC06")
	Local oStTmp     := FWFormViewStruct():New()
	Local oStFilho   := FWFormStruct(2, 'PZ4')
	Local oView      := Nil

	oStTmp:AddField(;
		"PZ4_EMAIL",;                // [01]  C   Nome do Campo
	"01",;                      // [02]  C   Ordem
	"Email",;                  // [03]  C   Titulo do campo
	X3Descric('PZ4_EMAIL'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("PZ4_EMAIL"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	Iif(INCLUI, .T., .F.),;     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
		"PZ4_PASS",;               // [01]  C   Nome do Campo
	"02",;                      // [02]  C   Ordem
	"Senha",;               // [03]  C   Titulo do campo
	X3Descric('PZ4_PASS'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("PZ4_PASS"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;//{'2=NAO','1=SIM'},;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
		"PZ4_NOME",;               // [01]  C   Nome do Campo
	"03",;                      // [02]  C   Ordem
	"Nome Cli",;               // [03]  C   Titulo do campo
	X3Descric('PZ4_NOME'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("PZ4_NOME"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;//{'2=NAO','1=SIM'},;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	//Criando a view que ser? o retorno da funç?o e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_CAB", oStTmp, "FORMCAB")
	oView:AddGrid('VIEW_PZ4',oStFilho,'PZ4DETAIL')

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',30)
	oView:CreateHorizontalBox('GRID',70)

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_CAB','CABEC')
	oView:SetOwnerView('VIEW_PZ4','GRID')

	//Habilitando t?tulo
	oView:EnableTitleView('VIEW_CAB','Cabeçalho - Clientes Portal')
	oView:EnableTitleView('VIEW_PZ4','Itens - Clientes Portal')

	//Tratativa padr?o para fechar a tela
	oView:SetCloseOnOk({||.T.})

	//Remove os campos de Filial e Tabela da Grid
	oStFilho:RemoveField('PZ4_FILIAL')
	oStFilho:RemoveField('PZ4_EMAIL')
	oStFilho:RemoveField('PZ4_PASS')
	oStFilho:RemoveField("PZ4_NOME")


Return oView

Static Function  CommitPZ4(oModel)
	Local oModelDad  	:= FWModelActive()
	Local nOpc       	:= oModelDad:GetOperation()
	Local oModelGrid 	:= oModelDad:GetModel('PZ4DETAIL')
	Local oModelCabec 	:= oModelDad:GetModel('FORMCAB')
	Local cQuery 		:= ""

	fwformcommit(oModel)
	cQuery 		:= "UPDATE " +RETSQLNAME('PZ4')+ " SET PZ4_PASS = '"+oModelCabec:GetValue("PZ4_PASS")+"', PZ4_NOME = '"+oModelCabec:GetValue("PZ4_NOME")+"' WHERE PZ4_PASS ='***' AND PZ4_NOME = ''"
	TCSqlExec(cQuery)

	If MSGYESNO( "Enviar e-mail", "envio de e-mail" )
		alert("TESTE 01")
		u_Mailportal(PZ4->PZ4_EMAIL,PZ4->PZ4_NOME, PZ4->PZ4_PASS)
	endif

Return .t.

Static Function FAETHC06Ok(oModel)
	Local aArea      := GetArea()
	Local lRet       := .T.
	Local oModelDad  := FWModelActive()
	Local nOpc       := oModelDad:GetOperation()
	Local oModelGrid := oModelDad:GetModel('PZ4DETAIL')


	RestArea(aArea)
Return lRet

Static Function CargaPZ4(oModel)
	Local aResult		:= {}
	Local cAliasPZ4	:= GetNextAlias()

	PZ4Query(@cAliasPZ4)//gera a query para a View

	//transformo o retorno da query em um array com a estrutura do modelo  Field/Grid
	aResult := FwLoadByAlias(oModel,cAliasPZ4)
Return aResult


Static Function PZ4Query(cAliasPZ4)
	Local cQuery := ''

	cQuery += " SELECT * "
	cQuery += " FROM " + RETSQLNAME("PZ4") + " PZ4 "
	cQuery += " WHERE D_E_L_E_T_ = '' "
	cQuery += " AND PZ4_EMAIL = '" +PZ4->PZ4_EMAIL + "'"


	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasPZ4,.T.,.T.)
Return
