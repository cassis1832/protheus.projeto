#Include "PROTHEUS.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL100A
    PL100A - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
    MATA410 - EXECAUTO
	23/08/2024 - Gravar a transportadora do cliente no pedido
	
	Params: aItensFat
		aItensFat - Itens a faturar	(produto, qtde, ts, data, pedido, preco, acao)
	@since 05/06/2024
/*/
User Function PL100A(aItens)
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	// Tabelas
	Private aItensFat  	:= {}	// Itens a faturar		(produto, qtde, ts, data, pedido, preco, acao)
	Private aItensRet   := {}	// Itens a retornar 	(nIndFat, produto, qtde, agrega)
	Private aSaldoTerc  := {}	// Saldos de terceiros	(produto, docto, serie, emissao, saldo, preco, usada, work)

	if Len(aItens) == 0
		return
	endif

	aItensFat := aItens

	// Explosão para carregar tabela de itens a retornar
	aItensRet := u_PL100B(@aItensFat)

	if Len(aItensRet) > 0
		TrataSaldoTerc()
	endif

	GravaPedido()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


/*------------------------------------------------------------------------------
	Tratamento dos itens que devem ser retornados de terceiros
	Saldos de terceiros	(produto, docto, serie, emissao, preco, saldo, usada, work)
/*-----------------------------------------------------------------------------*/
Static Function	TrataSaldoTerc()
	Local nIndFat	:= 0
	Local nIndRet	:= 0
	Local nIndTerc	:= 0

	aSaldoTerc := U_PL100C(aItensRet)

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
			if 	aItensFat[nIndFat][7] == .T.			// Tem saldo para retornar, atualiza qtde usada
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
		aItensFat[nIndFat][7] := .F.

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
	Local dDtEntr	:= ""

	Private nLinha 			:= 0
	Private aLinhas			:= {}	// Linhas do pedido - MATA410
	Private lMsErroAuto 	:= .F.
	Private lAutoErrNoFile 	:= .F.

	For nIndFat := 1 To Len(aItensFat)	
		if aItensFat[nIndFat][7] == .T.
			aLinha := {}
			nLinha := nLinha + 1
			aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
			aadd(aLinha,{"C6_PRODUTO"   , aItensFat[nIndFat][1], Nil})
			aadd(aLinha,{"C6_QTDVEN"    , aItensFat[nIndFat][2], Nil})
			aadd(aLinha,{"C6_TES"       , aItensFat[nIndFat][3], Nil})
			aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][4], Nil})
			aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][5], Nil})
			aadd(aLinha,{"C6_PRCVEN"    , aItensFat[nIndFat][6], Nil})
			aadd(aLinha,{"C6_PRUNIT"    , aItensFat[nIndFat][6], Nil})
			aadd(aLinhas, aLinha)

			For nIndRet := 1 To Len(aItensRet)	
				if nIndFat == aItensRet[nIndRet][1] .And. aItensRet[nIndRet][4] == "1" 
					VerRemessa(aItensRet[nIndRet])
				endif
			next nIndRet

			dDtEntr  := aItensFat[nIndFat][4]
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

				aLinha := {}
				nLinha := nLinha + 1
				aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
				aadd(aLinha,{"C6_PRODUTO"   , aSaldoTerc[nIndTerc][1], Nil})
				aadd(aLinha,{"C6_QTDVEN"    , nQtdeVen, Nil})
				aadd(aLinha,{"C6_PRCVEN"    , aSaldoTerc[nIndTerc][5] , Nil})
				aadd(aLinha,{"C6_PRUNIT"    , aSaldoTerc[nIndTerc][5] , Nil})
				aadd(aLinha,{"C6_TES"       , "685", Nil})
				aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][4], Nil})
				aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][5], Nil})
				aadd(aLinha,{"C6_NFORI"    	, aSaldoTerc[nIndTerc][2], Nil})
				aadd(aLinha,{"C6_SERIORI"   , aSaldoTerc[nIndTerc][3], Nil})
				aadd(aLinha,{"C6_ITEMORI"  	, aSaldoTerc[nIndTerc][10], Nil})
				aadd(aLinha,{"C6_IDENTB6"  	, aSaldoTerc[nIndTerc][9], Nil})
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

	For nInd := 1 to Len(aItensFat) Step 1
		if aItensFat[nInd][7] == .T.
			ZA0->(DbGoTo(aItensFat[nInd][8]))
			RecLock("ZA0", .F.)
			ZA0->ZA0_QTCONF  := ZA0->ZA0_QTDE
			ZA0->ZA0_STATUS  := '9'
			ZA0->ZA0_NUM     := cDoc
			ZA0->(MsUnlock())
		endif
	Next

	nPedidos := nPedidos + 1
return
