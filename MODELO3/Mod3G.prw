

Static Function ModelDef()

    // Cria as estruturas a serem usadas no Modelo de Dados
    Local oStruZA1 := FWFormStruct( 1, 'ZA1' )
    Local oStruZA2 := FWFormStruct( 1, 'ZA2' )
    Local oModel // Modelo de dados construído

    // Cria o objeto do Modelo de Dados
    oModel := MPFormModel():New( 'COMP021M' )

    // Adiciona ao modelo um componente de formulário
    oModel:AddFields( 'ZA1MASTER', /*cOwner*/, oStruZA1 )

    // Adiciona ao modelo uma componente de grid
    oModel:AddGrid( 'ZA2DETAIL', 'ZA1MASTER', oStruZA2 )

    // Faz relacionamento entre os componentes do model
    oModel:SetRelation( 'ZA2DETAIL', { { 'ZA2_FILIAL', 'xFilial( "ZA2" )' }, {'ZA2_MUSICA', 'ZA1_MUSICA' } }, ZA2->( IndexKey( 1 ) ) )

    // Adiciona a descrição do Modelo de Dados
    oModel:SetDescription( 'Modelo de Musicas' )
    
    // Adiciona a descrição dos Componentes do Modelo de Dados
    oModel:GetModel( 'ZA1MASTER' ):SetDescription( 'Dados da Musica' )
    oModel:GetModel( 'ZA2DETAIL' ):SetDescription( 'Dados do Autor Da Musica' )
    
Return oModel 


Static Function ViewDef()

    // Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
    Local oModel := FWLoadModel( 'COMP021_MVC' )

    // Cria as estruturas a serem usadas na View
    Local oStruZA1 := FWFormStruct( 2, 'ZA1' )
    Local oStruZA2 := FWFormStruct( 2, 'ZA2' )

    // Interface de visualização construída
    Local oView

    // Cria o objeto de View
    oView := FWFormView():New()

    // Define qual Modelo de dados será utilizado
    oView:SetModel( oModel )

    // Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
    oView:AddField( 'VIEW_ZA1', oStruZA1, 'ZA1MASTER' )

    //Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
    oView:AddGrid( 'VIEW_ZA2', oStruZA2, 'ZA2DETAIL' )

    // Cria um "box" horizontal para receber cada elemento da view
    oView:CreateHorizontalBox( 'SUPERIOR', 15 )
    oView:CreateHorizontalBox( 'INFERIOR', 85 )

    // Relaciona o identificador (ID) da View com o "box" para exibição
    oView:SetOwnerView( 'VIEW_ZA1', 'SUPERIOR' )
    oView:SetOwnerView( 'VIEW_ZA2', 'INFERIOR' )

Return oView 
