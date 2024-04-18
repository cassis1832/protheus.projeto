User Function AXZZH()
     Local aArea        := GetArea()
     Local cAliasForm          := ALIAS_FORM0
     Local cIDModelForm          := ID_MODEL_FORM0
     Local cIDModelGrid          := ID_MODEL_GRID0
     Local oBrowse
     Local cModelo      := MODELO
     Local cTitulo      := TITULO_MODEL
     
     oBrowse := FWMBrowse():New()
     oBrowse:SetAlias(cAliasForm)
     oBrowse:SetDescription(cTitulo)
     oBrowse:Activate()

     RestArea(aArea)
Return Nil
/*---------------------------------------------------------------------*/
Static Function MenuDef()
     Local aRot := {}

     ADD OPTION aRot TITLE ‘Visualizar‘ ACTION ‘VIEWDEF.aXZZH‘ OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
     ADD OPTION aRot TITLE ‘Incluir‘    ACTION ‘VIEWDEF.aXZZH‘ OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
     ADD OPTION aRot TITLE ‘Alterar‘    ACTION ‘VIEWDEF.aXZZH‘ OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
     ADD OPTION aRot TITLE ‘Excluir‘    ACTION ‘VIEWDEF.aXZZH‘ OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
     ADD OPTION aRot TITLE ‘Copiar‘     ACTION ‘VIEWDEF.aXZZH‘ OPERATION 9                      ACCESS 0
     
Return aRot

/*---------------------------------------------------------------------*/
Static Function ModelDef()
     Local oModel   := Nil
     Local aZZ3Rel := {}
     Local cAliasForm                := ALIAS_FORM0
     Local cAliasGrid                := ALIAS_GRID0
     Local cPrefForm                    := PREFIXO_ALIAS_FORM0
     Local cPrefGrid                    := PREFIXO_ALIAS_GRID0

     Local cCpoFormFilial          := cPrefForm+"_FILIAL"
     Local cCpoFormCampanha        := cPrefForm+"_NUM"

     Local cCpoGridFilial          := cPrefGrid+"_FILIAL"
     Local cCpoGridCampanha      := cPrefGrid+"_CAMPAN"
     Local cCpoGridItem               := cPrefGrid+"_ITEM"
     Local cCpoGriFilOri        := cPrefGrid+"_FILORI"

     Local oStPai     := FWFormStruct( 1, cAliasForm )
     Local oStFilho      := FWFormStruct( 1, cAliasGrid )

     Local oModel                     := Nil
     Local bActivate                    := {|oModel| activeForm(oModel) }
     Local bCommit                    := {|oModel| saveForm(oModel)}
     Local bCancel                  := {|oModel| cancForm(oModel)}
     Local bpreValidacao               := {|oModel| preValid(oModel)}
     Local bposValidacao               := {|oModel| posValid(oModel)}


     //Definições dos campos
     //oStPai:SetProperty(‘ZZH_NUM‘,    MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    ‘.F.‘))                                 //Modo de Edição
     oStPai:SetProperty(‘ZZH_NUM‘,    MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD, ‘GetSXENum("ZZH", "ZZH_NUM")‘))       //Ini Padrão
     oStFilho:SetProperty(cCpoGridCampanha , MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    ‘.F.‘))                                 //Modo de Edição
     oStFilho:SetProperty(cCpoGridCampanha , MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
     oStFilho:SetProperty(cCpoGridItem, MODEL_FIELD_OBRIGAT, .T. )                                                                          //Campo Obrigatório
     oStFilho:SetProperty(cCpoGridItem, MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD, /*‘u_zIniMus()‘*/))                         //Ini Padrão

     //Criando o modelo e os relacionamentos
     oModel     := MPFormModel():New(‘aXZZHM‘,/*bpreValidacao*/,/*bposValidacao*/,/*bCommit*/,/*bCancel*/)
     oModel:AddFields(‘ZZ2MASTER‘,/*cOwner*/,oStPai)
     oModel:AddGrid(‘ZZ3DETAIL‘,‘ZZ2MASTER‘,oStFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/) //cOwner é para quem pertence

     //Fazendo o relacionamento entre o Pai e Filho
     aAdd(aZZ3Rel, {cCpoGridFilial,cCpoFormFilial} )
     aAdd(aZZ3Rel, {cCpoGridCampanha,cCpoFormCampanha})

     oModel:SetRelation(‘ZZ3DETAIL‘, aZZ3Rel, ZZI->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado
     oModel:GetModel(‘ZZ3DETAIL‘):SetUniqueLine({cCpoGriFilOri})     //Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
     oModel:SetPrimaryKey({})

     //Setando as descrições
     oModel:SetDescription("Grupo de Produtos - Mod. 3")
     oModel:GetModel(‘ZZ2MASTER‘):SetDescription(‘Cadastro‘)
     oModel:GetModel(‘ZZ3DETAIL‘):SetDescription(‘CDs‘)
Return oModel
/*---------------------------------------------------------------------*/
Static Function ViewDef()
     Local oView        := Nil
     Local oModel       := FWLoadModel( ‘aXZZH‘ )
     Local oStPai       := FWFormStruct(2, ‘ZZH‘ )
     Local oStFilho     := FWFormStruct(2, ‘ZZI‘ )
     Local cPrefGrid    := PREFIXO_ALIAS_GRID0
     Local cCpoGridItem := cPrefGrid+"_ITEM"
     //Criando a View
     oView := FWFormView():New()
     oView:SetModel(oModel)
     
     //Adicionando os campos do cabeçalho e o grid dos filhos
     oView:AddField(‘VIEW_ZZH‘,oStPai,‘ZZ2MASTER‘)
     oView:AddGrid(‘VIEW_ZZI‘,oStFilho,‘ZZ3DETAIL‘)
     
     //Setando o dimensionamento de tamanho
     oView:CreateHorizontalBox(‘CABEC‘,50)
     oView:CreateHorizontalBox(‘GRID‘,50)
     
     //Amarrando a view com as box
     oView:SetOwnerView(‘VIEW_ZZH‘,‘CABEC‘)
     oView:SetOwnerView(‘VIEW_ZZI‘,‘GRID‘)
     
     //Habilitando título
     oView:EnableTitleView(‘VIEW_ZZH‘,‘Dados da Campanha‘)
     oView:EnableTitleView(‘VIEW_ZZI‘,‘Definicao de Metas e Volumes‘)
     
     oView:AddIncrementField( ‘VIEW_ZZI‘, cCpoGridItem )
     //Força o fechamento da janela na confirmação
     oView:SetCloseOnOk({||.T.})
     
     //Remove os campos de Código do Artista e CD
     //oStFilho:RemoveField(‘ZZ3_CODART‘)
     //oStFilho:RemoveField(‘ZZ3_CODCD‘)
Return oView

/*---------------------------------------------------------------------*/
Static Function preValid(oModel)
     Local nOperation     := oModel:GetOperation()
     Local cAliasForm                := ALIAS_FORM0
     Local cAliasGrid                := ALIAS_GRID0
     Local cPrefForm                    := PREFIXO_ALIAS_FORM0
     Local cPrefGrid                    := PREFIXO_ALIAS_GRID0
     Local cIDModelGrid     := ID_MODEL_GRID0
     Local oModelGrid     := oModel:GetModel(cIDModelGrid)

     Local lRet               := .T.
     Alert(‘Valida a cada campo digitado...‘)

Return lRet

/*
     Função para Validar os Dados Após Confirmação da Tela de Cadastro - Verifica se pode incluir
*/
Static Function posValid(oModel)
     Local cAliasForm               := ALIAS_FORM0
     Local cIDModelForm               := ID_MODEL
     Local cIDModelGrid               := ID_MODEL_GRID0
     Local nOperation               := oModel:GetOperation()
     Local cPrefForm                    := PREFIXO_ALIAS_FORM0
     Local cPrefGrid                    := PREFIXO_ALIAS_GRID0

     Local cCpoFormFilial          := cPrefForm+"_FILIAL"
     Local cCpoFormCampanha        := cPrefForm+"_NUM"

     Local cFil                         := xFilial(cAliasForm)
     Local cSeqLanc                    := oModel:GetValue(‘aXZZHM‘,cCpoFormCampanha)
     Local lRet                         := .T.

     If ( nOperation == MODEL_OPERATION_INSERT )
          dbSelectArea(cAliasForm)
          (cAliasForm)->(dbSetOrder(1))
          If (cAliasForm)->(dbSeek(cFil+cCpoFormCampanha))
               Help(,,"HELP",,"Atenção! A Campanha informada ‘" + AllTrim(cReferencia) + "‘ não pode ser utilizada pois já existe na base de dados para esta filial.",1,0)
               lRet := .F.
          Endif
     Endif

     If ( nOperation == MODEL_OPERATION_UPDATE )
          If cOldStatus $ STATUS_SUCESSO
               dbSelectArea("ZZH")
               ZZH->(dbSetOrder(2)) //ZZH_FILIAL+ZZH_NUM
               If ( ZZH->(dbSeek(cFil+cSeqLanc)) )
                    Help(,,"HELP",,"Atenção! A Campanha informada ‘" + AllTrim(cReferencia) + "‘ não pode ser alterada verifique. ",1,0)
                    lRet := .F.
               Endif
          Endif
     Endif

     If ( nOperation == MODEL_OPERATION_DELETE )
          dbSelectArea("ZZH")
          ZZH->(dbSetOrder(2)) //ZZH_FILIAL+ZZH_NUM
          If ( ZZH->(dbSeek(cFil+cSeqLanc)) )
               Help(,,"HELP",,"Atenção! A referência informada ‘" + AllTrim(cReferencia) + "‘ não pode ser excluídapois a Nota Fiscal já foi processada com sucesso no Protheus. Para alterar/estornar exclua a NF de Saída pela Rotina Padrão antes de realizar essa ação.",1,0)
               lRet := .F.
          Else
               lRet := .T.
          Endif

     Endif

Return lRet
