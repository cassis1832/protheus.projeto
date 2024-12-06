#Include "PROTHEUS.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} FT030A
    MATA410 - EXECAUTO
    FT030A - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
		06/09/2024 - Gravar nItemPed e xPed
	Params: aItens = Itens a faturar	
	{ZA0_CODPED[1], ZA0_CLIENT[2], ZA0_LOJA[3], ZA0_PRODUT[4], ZA0_DTENTR[5], ZA0_HRENTR[6], ZA0_QTDE[7], A7_XNATUR[8], A7_XGRUPV[9]}
/*/
User Function FT030A(aPedidos)
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()
	Local oSay 			:= NIL

	Private nPedidos    := 0
	Private aMensagens	:= {}
	Private aItens		:= aPedidos

	if Len(aItens) == 0
		return
	endif

	If SA1->(! MsSeek(xFilial("SA1") + aItens[1][2] + aItens[1][3]))
		MessageBox("Cliente nao cadastrado!","",0)
	else
		FwMsgRun(NIL, {|oSay| CriarPedidos(oSay)}, "Preparando pedidos", "Criando pedidos de vendas...")
	endif

	if len(aMensagens) > 0
		MostraMensagens(aMensagens)
	endif

	if nPedidos == 0
		FWAlertSuccess("NAO FOI CRIADO NENHUM PEDIDO DE VENDA!", "Geracao de Pedidos de Vendas")
	EndIf

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


Static Function CriarPedidos(oSay)
	Local nInd			:= 0
	Local cData       	:= ''
	Local cHrEntr     	:= ''
	Local cGrupoPV    	:= ''

	Private cNatureza  	:= ''

	// Tabelas
	Private aItensFat  	:= {}	// Itens a faturar		(produto[1], qtde[2], data[3], pedido[4], acao[5])
	Private aItensRet   := {}	// Itens a retornar 	(nIndFat[1], produto[2], qtde[3], agrega[4])
	Private aSaldoTerc  := {}	// Saldos de terceiros	(produto[1], docto[2], serie[3], emissao[4], saldo[5], preco[6], usada[7], work[8])

	// ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_HRENTR, A7_XGRUPV, ZA0_PRODUT
	aSort(aItens,,, {|x, y| x[5]+x[8]+x[6]+x[9]+x[4] < y[5]+y[8]+y[6]+y[9]+y[4]})

	For nInd := 1 To Len(aItens) Step 1

		if aItens[nInd][5] != cData .or. aItens[nInd][6] != cHrEntr .or. aItens[nInd][8] != cNatureza	.or. aItens[nInd][9]  != cGrupoPV
			GeraPedido()
			cData       := aItens[nInd][5]
			cHrEntr     := aItens[nInd][6]
			cNatureza   := aItens[nInd][8]
			cGrupoPV    := aItens[nInd][9]
			aItensFat 	:= {}
		endif

		AAdd(aItensFat, {aItens[nInd][4], aItens[nInd][7],aItens[nInd][5],aItens[nInd][1], .T.})
	next

	GeraPedido()
return


Static Function GeraPedido()

	if len(aItensFat) = 0
		return
	endif

	// Explosão para carregar tabela de itens a retornar
	aItensRet := u_FT030B(@aItensFat)

	if Len(aItensRet) > 0
		TrataSaldoTerc()
	endif

	GravaPedido()
return

/*------------------------------------------------------------------------------
	Tratamento dos itens que devem ser retornados de terceiros
	Saldos de terceiros	(produto, docto, serie, emissao, preco, saldo, usada, work)
/*-----------------------------------------------------------------------------*/
Static Function	TrataSaldoTerc()
	Local nIndFat	:= 0
	Local nIndRet	:= 0
	Local nIndTerc	:= 0

	aSaldoTerc := U_FT030C(aItensRet)

	// Percorre os itens a faturar e verifica se existe saldo suficiente para os retornos
	For nIndFat := 1 To Len(aItensFat)	
		// Percorre os retornos necessarios do item
		For nIndRet := 1 To Len(aItensRet)
			if nIndFat == aItensRet[nIndRet][1] .And. aItensRet[nIndRet][4] == "1" 
				BuscaSaldoDisp(aItensRet[nIndRet])
			endif
		Next nIndRet

		// Atualiza saldo disponivel em terceiro
		For nIndTerc := 1 To Len(aSaldoTerc)
			if 	aItensFat[nIndFat][5] == .T.			// Tem saldo para retornar, atualiza qtde usada
				aSaldoTerc[nIndTerc][7] := aSaldoTerc[nIndTerc][7] + aSaldoTerc[nIndTerc][8]   
			endif
			aSaldoTerc[nIndTerc][8] = 0					// Zera work
		Next nIndTerc
	Next nIndFat
Return


/*------------------------------------------------------------------------------
	Busca o item a retornar na tabela de saldos de terceiros
 	Se não tiver saldo suficiente dá mensagem e marca que não pode faturar o item
	Se tiver saldo soma a quant. necessária no campo work
	aSaldoTerc  Saldos de terceiros	(produto, docto, serie, emissao, preco, saldo, usada, work)
/*-----------------------------------------------------------------------------*/
Static Function BuscaSaldoDisp(aItemRet)
	Local nIndTerc		:= 0
	Local nIndFat		:= 0
	Local nSaldoDisp	:= 0
	Local nQtdeNec		:= 0
	Local nQtdeUsar		:= 0
	Local cInfor		:= ""
	Local cMens			:= ""

	nQtdeNec := aItemRet[3]

	For nIndTerc := 1 To Len(aSaldoTerc)
		if nQtdeNec <= 0
			Exit
		endif

		if aSaldoTerc[nIndTerc][1] == aItemRet[2]	// produto
			nSaldoDisp := aSaldoTerc[nIndTerc][6] - aSaldoTerc[nIndTerc][7] - aSaldoTerc[nIndTerc][8] 

			if nSaldoDisp > 0
				if nSaldoDisp >= nQtdeNec
					aSaldoTerc[nIndTerc][8] := aSaldoTerc[nIndTerc][8] + nQtdeNec
					nQtdeNec := 0
				else
					nQtdeUsar := aSaldoTerc[nIndTerc][6] - aSaldoTerc[nIndTerc][7] - aSaldoTerc[nIndTerc][8]
					aSaldoTerc[nIndTerc][8] := aSaldoTerc[nIndTerc][8] + nQtdeUsar
					nQtdeNec := nQtdeNec - nQtdeUsar
				endif
			endif
		endif
	Next nIndTerc


	if nQtdeNec > 0 		// Saldo insuficiente
		nIndFat := aItemRet[1]
		aItensFat[nIndFat][5] := .F. 

		cInfor := "Item a faturar = " + aItensFat[aItemRet[1]][1]
		cMens  := "Falta saldo de terceiros para retornar o item = " + cValToChar(aItemRet[2])
		aadd(aMensagens, {cInfor, cMens})
	endif
Return

/*--------------------------------------------------------------------------
   	Grava o pedido no sistema
	aItensFat - Itens a faturar	(produto, qtde, ts, data, pedido, preco, acao)
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()
	Local nOpcX 	:= 3            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Local nIndFat	:= 0
	Local nIndRet	:= 0
	Local aLinha  	:= {}
	Local aCabec    := {}			// Cabecalho do pedido - MATA410
	Local cDoc		:= ""
	Local dDtEntr	:= Date()

	Private nLinha 			:= 0
	Private aLinhas			:= {}	// Linhas do pedido - MATA410
	Private lMsErroAuto 	:= .F.
	Private lAutoErrNoFile 	:= .F.

	For nIndFat := 1 To Len(aItensFat)	
		if aItensFat[nIndFat][5] == .T.

			SB1->(dbSetOrder(1))
			DA1->(dbSetOrder(1))    // Filial,Tabela,Produto,xxxxxxxxxxx

			If SB1->(! MsSeek(xFilial("SB1") + aItensFat[nIndFat][1]))
				Help('',1,'Cadastro de Produtos',,'PRODUTO NAO CADASTRADO',1,0,,,,,,{"Cadastre o produto ou altere o codigo do produto"}) 
				lOk  := .F.
			EndIf

    		// Verificar a tabela de precos do cliente
			If DA1->(MsSeek(xFilial("DA1") + SA1->A1_TABELA + SB1->B1_COD, .T.))
				aLinha := {}
				nLinha := nLinha + 1
				
				dDtEntr  := stod(aItensFat[nIndFat][3])

				aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2)		, Nil})
				aadd(aLinha,{"C6_PRODUTO"   , SB1->B1_COD			, Nil})
				aadd(aLinha,{"C6_QTDVEN"    , aItensFat[nIndFat][2]	, Nil})
				aadd(aLinha,{"C6_TES"       , SB1->B1_TS			, Nil})
				aadd(aLinha,{"C6_ENTREG"    , dDtEntr				, Nil})
				aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][4]	, Nil})
				aadd(aLinha,{"C6_PRCVEN"    , DA1->DA1_PRCVEN		, Nil})
				aadd(aLinha,{"C6_PRUNIT"    , DA1->DA1_PRCVEN		, Nil})
				aadd(aLinha,{"C6_NUMPCO"    , SB1->B1_XPED			, Nil})
				aadd(aLinha,{"C6_ITEMPC"    , SB1->B1_XNITEM		, Nil})
				aadd(aLinhas, aLinha)

				For nIndRet := 1 To Len(aItensRet)	
					if nIndFat == aItensRet[nIndRet][1] .And. aItensRet[nIndRet][4] == "1" 
						VerRemessa(aItensRet[nIndRet])
					endif
				next nIndRet

			else
				MessageBox("Tabela de precos nao encontrada para o item" + SB1->B1_COD,"",0)
				lOk     := .F.
			EndIf
		endif
	next nIndFat

	if Len(aLinhas) > 0
		cDoc := GetSxeNum("SC5", "C5_NUM")
		RollBAckSx8()

		aCabec := {}
		aadd(aCabec, {"C5_NUM"    , cDoc			, Nil})
		aadd(aCabec, {"C5_TIPO"	  , "N"				, Nil})
		aadd(aCabec, {"C5_CLIENTE", cCliente		, Nil})
		aadd(aCabec, {"C5_LOJACLI", cLoja			, Nil})
		aadd(aCabec, {"C5_LOJAENT", cLoja			, Nil})
		aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND	, Nil})
		aadd(aCabec, {"C5_NATUREZ", cNatureza		, Nil})
		aadd(aCabec, {"C5_FECENT" , dDtEntr			, Nil})
		aadd(aCabec, {"C5_REDESP" , SA1->A1_TRANSP	, Nil})

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aLinhas, nOpcX, .F.)

		If !lMsErroAuto
			AtualizaGravados(cDoc)
			aGravados := {}
		Else
			ConOut("Erro na inclusao!")
			MOSTRAERRO()
		EndIf
	endif
return

///	aSaldoTerc  Saldos de terceiros		(produto, docto, serie, emissao,  preco, saldo, usada, work)
Static Function VerRemessa(aItemRet)
	Local nQtdeVen	:= 0
	Local nIndTerc 	:= 0
	Local dDtEntr  	:= Date()
	Local nIndFat	:= aItemRet[1]
	Local nQtdeNec	:= aItemRet[3]
	Local aLinha  	:= {}

	For nIndTerc := 1 To Len(aSaldoTerc)	
		if nQtdeNec <= 0 
			Exit
		endif

		if aItemRet[2] == aSaldoTerc[nIndTerc][1]		// produto

			nSaldoDisp := aSaldoTerc[nIndTerc][6]

			if nSaldoDisp > 0
				if nSaldoDisp >= nQtdeNec
					nQtdeVen := nQtdeNec
					aSaldoTerc[nIndTerc][6] := aSaldoTerc[nIndTerc][6] - nQtdeNec
					nQtdeNec := 0
				else
					nQtdeVen := aSaldoTerc[nIndTerc][6] 
					aSaldoTerc[nIndTerc][6] := 0
					nQtdeNec := nQtdeNec - nQtdeVen
				endif

				dDtEntr  := stod(aItensFat[nIndFat][3])

				aLinha := {}
				nLinha := nLinha + 1
				aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2)			, Nil})
				aadd(aLinha,{"C6_PRODUTO"   , aSaldoTerc[nIndTerc][1]	, Nil})
				aadd(aLinha,{"C6_QTDVEN"    , nQtdeVen					, Nil})
				aadd(aLinha,{"C6_PRCVEN"    , aSaldoTerc[nIndTerc][5] 	, Nil})
				aadd(aLinha,{"C6_PRUNIT"    , aSaldoTerc[nIndTerc][5] 	, Nil})
				aadd(aLinha,{"C6_TES"       , "685"						, Nil})
				aadd(aLinha,{"C6_ENTREG"    , dDtEntr					, Nil}) 
				aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][1]		, Nil}) 
				aadd(aLinha,{"C6_NFORI"    	, aSaldoTerc[nIndTerc][2]	, Nil})
				aadd(aLinha,{"C6_SERIORI"   , aSaldoTerc[nIndTerc][3]	, Nil})
				aadd(aLinha,{"C6_ITEMORI"  	, aSaldoTerc[nIndTerc][10]	, Nil})
				aadd(aLinha,{"C6_IDENTB6"  	, aSaldoTerc[nIndTerc][9]	, Nil})
				aadd(aLinhas, aLinha)
			endif
		endif

	next nIndTerc
return

/*--------------------------------------------------------------------------
   Atualiza o status no arquivo ZA0 para os pedidos criados
/*-------------------------------------------------------------------------*/
Static Function AtualizaGravados(cDoc)
	Local nInd :=0

	aadd(aMensagens, { cValToChar(cDoc),"Pedido gravado com sucesso"})

	ZA0->(dbSetOrder(1))


	For nInd := 1 to Len(aItensFat) Step 1
		if aItensFat[nInd][5] == .T.
			If ZA0->(MsSeek(xFilial("ZA0") + aItensFat[nInd][4]))
				RecLock("ZA0", .F.)
				
				if ZA0->ZA0_NUM == ""
					ZA0->ZA0_NUM :=  cDoc 
				else
					ZA0->ZA0_NUM := ZA0->ZA0_NUM + '/' + cDoc 
				endif
				
				ZA0->ZA0_QTCONF  := ZA0->ZA0_QTCONF + aItensFat[nInd][2]

				if ZA0->ZA0_QTCONF >= ZA0->ZA0_QTDE
					ZA0->ZA0_STATUS  := '9'
				endif
				
				ZA0->(MsUnlock())
			endif
		endif
	Next

	nPedidos := nPedidos + 1
return



Static Function MostraMensagens(aMensagens)
	Local nX			:=0

	Private oDlg       	:= Nil
	Private oFwBrowse  	:= Nil
	Private aColumns   	:= {}

	oDlg:= FwDialogModal():New()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('Mensagens da Geracao de Pedidos de Vendas')

	oDlg:SetPos(000, 000)
	oDlg:SetSize(300, 500)

	oDlg:CreateDialog()
	oDlg:AddCloseButton(Nil, 'Fechar')

	oPnl:=oDlg:GetPanelMain()

	oFwBrowse := FWBrowse():New()
	oFwBrowse:SetDataArrayoBrowse()  
	oFwBrowse:SetArray(aMensagens)

	aAdd(aColumns, {"Informação",	{|oBrw| aMensagens[oBrw:At(), 1] }, "C", "@!", 1, 30, 0, .F.})
	aAdd(aColumns, {"Mensagem",		{|oBrw| aMensagens[oBrw:At(), 2] }, "C", "@!", 1, 60, 0, .F.})

	//Cria as colunas do array
	For nX := 1 To Len(aColumns)
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oPnl)
	oFwBrowse:SetDoubleClick( {|| fDupClique() } )
	oFwBrowse:SetDescription( "Mensagens da Geracao de Pedidos de Vendas" )

	oFwBrowse:Activate()
	oDlg:Activate()
return
