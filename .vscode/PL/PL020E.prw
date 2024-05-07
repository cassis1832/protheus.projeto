#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//------------------------------------------------------------------------------
/*/{Protheus.doc} PL020E
   Função que carrega a Estrutura do Produto no Pedido de Venda
        @sample	   PL020E(aItens, aItens)
        @param		aItens  , Array	    , Array dos Itens
        @return		.T.		, Lógico


    O sistema não permite a inclusão do retorno sem que haja estoque ou NF para retornar
    Então por enquanto essa rotina não funciona
/*/
//------------------------------------------------------------------------------
User Function PL020E(aItens)

	Local aArea     := GetArea()
	Local aBOM      := {}

	Local nPProduto := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_PRODUTO"})
//	Local nPTES     := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_TES"})
	Local nPQtdVen  := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_QTDVEN"})
	Local nPItem    := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ITEM"})
	Local nPData    := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ENTREG"})
	Local cItem     := ""
	Local nX        := 0

	Private nEstru  := 0

	// Explodir a última linha da tabela
	Explosao(aItens[Len(aItens)][nPProduto][2],	aItens[Len(aItens)][nPQtdVen][2], @aBOM)

	//------------------------------------------------------------------------------
	// Adiciona os componentes no aItens
	//------------------------------------------------------------------------------
	For nX := 1 To Len(aBOM)

		cItem := aItens[Len(aItens)][nPItem][2]    // ultimo item da lista
		cItem := Soma1(cItem)

		N := Len(aItens)

		aLinha := {}
		aadd(aLinha,{"C6_ITEM", StrZero(0,2), Nil})
		aadd(aLinha,{"C6_PRODUTO", aBOM[nX][1], Nil})
		aadd(aLinha,{"C6_TES", "685", Nil})
		aadd(aLinha,{"C6_ENTREG", aItens[Len(aItens)][nPData][2], Nil})
		aadd(aLinha,{"C6_QTDVEN", aBOM[nX][2], Nil})
		aadd(aLinha,{"C6_PEDCLI", "", Nil})
		aadd(aLinha,{"C6_XCODPED", "", Nil})
		aadd(aLinha,{"C6_VALOR", 0, Nil})
		aadd(aLinha,{"C6_PRCVEN", 0, Nil})
		aadd(aLinha,{"C6_PRUNIT", 0, Nil})
		aadd(aItens, aLinha)
	Next nX

	RestArea(aArea)
Return(.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} Explosao
   Função recursiva para localizar todos os componentes da estrutura.
    @sample	   Explosao(cProduto,nQuant,aNewStruct
    @param		cProduto   , Caractere 	, Código do Produto Pai
    @param		nQuant     , Numérico  	, Quantidade do Produto Pai
    @param		aNewStruct , Array     	, Array de retorno
    @return		Nil
/*/
//------------------------------------------------------------------------------
Static Function Explosao(cProduto, nQuant, aNewStruct)

	Local aAreaAnt	:= GetArea()
	Local nX	    := 0
	Local aArrayAux := {}

	//Variável private declarada na função fGeraEstr()
	nEstru := 0

	//Faz a explosão do item a partir do SG1
	aArrayAux := Estrut(cProduto, nQuant, .T.)

	//------------------------------------------------------------------------------
	// Processa todos os componentes do produto passado no parametro
	//------------------------------------------------------------------------------
	dbSelectArea("SB1")
	dbSetOrder(1)

	For nX := 1 to Len(aArrayAux)

		// Le o item componente
		If MsSeek(xFilial("SB1")+aArrayAux[nx,3]) 	//Filial+Componente

			// Le a estrutura do componente
			SG1->(dbSetOrder(1)) //G1_FILIAL+G1_COD+G1_COMP+G1_TRT

			if SG1->(MsSeek(fwxfilial('SG1')+SB1->B1_COD))
				if SB1->B1_AGREGCU == '1'
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC,SB1->B1_TS})
				endif

				Explosao(aArrayAux[nx,3],aArrayAux[nx,4],aNewStruct) 	//Componente+Qtde
			else
				if SB1->B1_AGREGCU == '1'
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC,SB1->B1_TS})
				endif
			endif

		endif

	Next nX

	RestArea(aAreaAnt)
Return Nil
