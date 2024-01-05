#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'

/*
        https://www.youtube.com/watch?v=t_9OHpCNb2A&list=PLxc8RRHPfc_fVYT4CTRyhRXbm9UYpghuZ
*/

User Function CADPRO()

    Local aArea := GetNextAlias()
    Local oBrowse

    oBrowse := FwMBrowse():New()
    oBrowse : SetAlias("SZ9")
    oBrowse : SetDescription("Tabela SZ9")
    oBrowse : AddLegend("SZ9->Z9_Status == '1'", "GREEN", "Ativo")
    oBrowse : AddLegend("SZ9->Z9_Status == '2'", "RED", "Inativo")
    oBrowse : Activate()

    RestArea(aArea)

Return


Static Function MenuDef()
    
    Local aRotina := {}

    Add Option aRotina Title 'Pesquisar'    Action ''               Operation 1 Access 0
    Add Option aRotina Title 'Visualizar'   Action 'ViewDef.CadPro' Operation 2 Access 0
    Add Option aRotina Title 'Incluir'      Action 'ViewDef.CadPro' Operation 3 Access 0
    Add Option aRotina Title 'Alterar'      Action 'ViewDef.CadPro' Operation 4 Access 0
    Add Option aRotina Title 'Excluir'      Action 'ViewDef.CadPro' Operation 5 Access 0
    Add Option aRotina Title 'Legenda'      Action 'u_ProLeg'       Operation 6 Access 0
    Add Option aRotina Title 'Copiar'       Action ''               Operation 7 Access 0

Return aRotina

// Definição do modelo de dados
Static Function ModelDef()

    Local oModel := NIL

    Local OStructSZ9 := FwFormStruct(1, "SZ9")

    oModel := MPFormModel():New("CADPROM", /*bPre*/, /*bPos*/, /*bCommit*/,/*bCancel*/)
    oModel : AddFields("FormSz9",,oStructSZ9)                               // Permitir editar somente 1 registro por vez
    oModel : SetPrimaryKey({'Z9_filial', 'z9_codigo'})
    oModel : SetDescription('Modelo de dados da Z9')
    oModel : GetModel("FormSz9"):SetDescription("Formulario do SZ9")

Return oModel


Static Function ViewDef(param_name)
    
    Local oView := NIL
    Local oModel := FwLoadModel("CadPro")
    Local OStructSZ9 := FwFormStruct(2, "SZ9")

    oView := FwFormView():New()
    oView : SetModel(oModel)
    oView : AddFields("View_SZ9",oStructSZ9, "FormSZ9")
    oView : CreateHorizontalBox("Tela", 100)
    oView : EnableTitleView("View_SZ9", "Dados do SZ9")
    oView : SetCloseOnOk({||.T.})
    oView : SetOwnerView("View_SZ9", "Tela")

Return oView


User Function ProLeg()

    Local aLegenda := {}

    AAdd(aLegenda,{"BR_VERDE", "Ativo"})
    AAdd(aLegenda,{"BR_VERMELHO", "Inativo"})

    BrwLegenda("Registros", "Ativos/Inativos", aLegenda)
return

