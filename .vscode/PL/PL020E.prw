#include 'totvs.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} PL020E
   Explosão dos itens do pedido para encontrar material para devolução ao cliente
   @source PL020E.prw
   @author Carlos Assis
   @since 19/04/2024
   @return  Array, Array com os itens a serem incluídos no pedido
/*/
//--------------------------------------------------------------------
User Function PL020D()

	Local aButton	:= {}

	aAdd(aButton, {"PENDENTE", {|| u_fGeraEstr(aHeader,aCols,n) }, "[F9] Estr.Prod."})
	SetKey(VK_F9, {|| u_fGeraEstr(aHeader,aCols,n) })

Return aButton

//------------------------------------------------------------------------------
/*/{Protheus.doc} fGeraEstr
   Função que carrega a Estrutura do Produto no Pedido de Venda

	@sample	   fGeraEstr(aHeader,aCols,nX)
   @param		aHeader , Array     , Array do Cabeçalho
	@param		aCols   , Array	    , Array dos Itens
	@param		nX      , Numérico 	, Número da linha posicionada
	@return		.T.		, Lógico
/*/
//------------------------------------------------------------------------------
User Function fGeraEstr(aHeader,aCols,nX)

	Local aArea     := GetArea()
	Local aBOM      := {}
	Local nPProduto := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local nPTES     := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local nPQtdVen  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local nPItem    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local nPTotal   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	Local nY        := 0
	Local cItem     := ""

	Private N 	    := nX
	Private nEstru  := 0

	//Localiza todos os componentes do primeiro nível da estrutura.
	Explosao(aCols[nX][nPProduto],aCols[nX][nPQtdVen],@aBOM)

	//------------------------------------------------------------------------------
	// Adiciona os produtos no aCols
	//------------------------------------------------------------------------------

	For nX := 1 To Len(aBOM)

		cItem := aCols[Len(aCols)][nPItem]

		aAdd(aCOLS,Array(Len(aHeader)+1))

		For nY	:= 1 To Len(aHeader)

			If ( AllTrim(aHeader[nY][2]) == "C6_ITEM" )
				aCols[Len(aCols)][nY] := Soma1(cItem)
			Else
				If (aHeader[nY,2] <> "C6_REC_WT") .And. (aHeader[nY,2] <> "C6_ALI_WT")
					aCols[Len(aCols)][nY] := CriaVar(aHeader[nY][2])
				EndIf
			EndIf

		Next nY

		N := Len(aCols)
		aCOLS[N][Len(aHeader)+1] := .F.
		A410Produto(aBom[nX][1],.F.)
		aCols[N][nPProduto] := aBom[nX][1]
		A410MultT("M->C6_PRODUTO",aBom[nX][1])

		If ExistTrigger("C6_PRODUTO")
			RunTrigger(2,N,Nil,,"C6_PRODUTO")
		EndIf

		A410SegUm(.T.)
		A410MultT("M->C6_QTDVEN",aBom[nX][2])

		If ExistTrigger("C6_QTDVEN ")
			RunTrigger(2,N,Nil,,"C6_QTDVEN ")
		EndIf

		If Empty(aCols[N][nPTotal]) .Or. Empty(aCols[N][nPTES])
			aCOLS[N][Len(aHeader)+1] := .T.
		EndIf

	Next nX

	RestArea(aArea)
Return(.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} Explosao
   Função recursiva para localizar todos os componentes do primeiro nível
	da estrutura.

   @sample	   Explosao(cProduto,nQuant,aNewStruct
	@param		cProduto   , Caractere 	, Código do Produto Pai
	@param		nQuant     , Numérico  	, Quantidade do Produto Pai
   @param		aNewStruct , Array     	, Array de retorno
	@return		Nil
/*/
//------------------------------------------------------------------------------
Static Function Explosao(cProduto,nQuant,aNewStruct)

	Local aAreaAnt	   := GetArea()
	Local nX		      := 0
	Local aArrayAux   := {}

	//Variável private declarada na função fGeraEstr()
	nEstru := 0

	//Faz a explosão do item a partir do SG1
	aArrayAux := Estrut(cProduto,nQuant,.T.)

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
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC})
				endif

				Explosao(aArrayAux[nx,3],aArrayAux[nx,4],aNewStruct) 	//Componente+Qtde
			else
				if SB1->B1_AGREGCU == '1'
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC})
				endif
			endif

		endif

	Next nX

	RestArea(aAreaAnt)
Return Nil
