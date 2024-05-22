oBrowse     := Nil
oModal   := Nil
aBrwData    := {}
aBrwModel   := {}
aBrwCol     := {}
aBrwSeek    := {}
aBrwFil     := {}
aCoors      := FwGetDialogSize()

aAdd(aBrwModel, {'Filial'        , '@!'    , 02, 00, 1})
aAdd(aBrwModel, {'Pedido'        , '@!'    , 12, 00, 1})
aAdd(aBrwModel, {'Data e Hora'  , '@!'    , 25, 00, 1})
aAdd(aBrwModel, {'Vendedor'        , '@!'    , 06, 00, 1})
aAdd(aBrwModel, {'Nome'            , '@!'    , 40, 00, 1})
aAdd(aBrwModel, {'Cliente'        , '@!'    , 08, 00, 1})
aAdd(aBrwModel, {'Razão Social'    , '@!'    , 40, 00, 1})
aAdd(aBrwModel, {'Importado'    , '@A'    , 03, 00, 1})

For nI := 1 To Len(aBrwModel)

	aAdd(aBrwFil, {aBrwModel[nI,1], aBrwModel[nI,1], 'C', aBrwModel[nI,3], aBrwModel[nI,4], aBrwModel[nI,2]} )

	aAdd(aBrwCol, FwBrwColumn():New())

	aBrwCol[Len(aBrwCol)]:SetData( &('{ || aBrwData[oBrowse:nAt,' + cValToChar(nI) + ']}') )
	aBrwCol[Len(aBrwCol)]:SetTitle(aBrwModel[nI,1])
	aBrwCol[Len(aBrwCol)]:SetPicture(aBrwModel[nI,2])
	aBrwCol[Len(aBrwCol)]:SetSize(aBrwModel[nI,3])
	aBrwCol[Len(aBrwCol)]:SetDecimal(aBrwModel[nI,4])
	aBrwCol[Len(aBrwCol)]:SetAlign(aBrwModel[nI,5])

Next nI

aAdd(aBrwSeek, {'Pedido', { {'', 'C', 12, 00, 'Pedido', 'Pedido' } }, 1, .T.} )

oModal := FwDialogModal():New()

oModal:SetTitle('Listagem de Pedidos Externos')
oModal:SetEscClose(.F.)
oModal:SetSize(aCoors[3] / 2.7, aCoors[4] / 2.9)
oModal:CreateDialog()

oModal:EnableFormBar(.T.)
oModal:CreateFormBar()

oBrowse := FwBrowse():New()
oBrowse:SetDataArray()
oBrowse:SetArray(aBrwData)
oBrowse:SetColumns(aBrwCol)
oBrowse:SetSeek(, aBrwSeek)
oBrowse:SetUseFilter()
oBrowse:SetFieldFilter(aBrwFil)
oBrowse:SetOwner(oModal:GetPanelMain())
oBrowse:Activate()

oModal:AddButton('Sair'    , { || oModal:DeActivate() }, 'Sair',,.T.,.F.,.T.,)

oModal:Activate()
