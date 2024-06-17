#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'

//------------------------------------------------------------------------------
/*/{Protheus.doc} PL020E
   Função que carrega a Estrutura do Produto no Pedido de Venda
/*/
//------------------------------------------------------------------------------
User Function PL020E(aItens)
	Local aBOM      := {}

	Local nPProduto := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_PRODUTO"})
	Local nPQtdVen  := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_QTDVEN"})
	Local nPItem    := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ITEM"})
	Local nPData    := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ENTREG"})
	Local cItem     := ""
	Local nX        := 0
	Local nQtde		:= 0
	Local nValor	:= 0

	// Explodir a última linha da tabela
	Estrutura(@aBom, aItens[Len(aItens)][nPProduto][2],	aItens[Len(aItens)][nPQtdVen][2])

	//------------------------------------------------------------------------------
	// Adiciona os componentes no aItens
	//------------------------------------------------------------------------------
	For nX := 1 To Len(aBOM)

		if aBOM[nX][3] == "1" // permite agregar custo
			cItem := aItens[Len(aItens)][nPItem][2]    // ultimo item da lista
			cItem := Soma1(cItem)

			nQtde := aBOM[nX][2]
			nValor := nQtde * 1

			aLinha := {}
			aadd(aLinha,{"C6_ITEM", StrZero(cItem, 2), Nil})
			aadd(aLinha,{"C6_PRODUTO", aBOM[nX][1], Nil})
			aadd(aLinha,{"C6_TES", "888", Nil})
			aadd(aLinha,{"C6_ENTREG", aItens[Len(aItens)][nPData][2], Nil})
			aadd(aLinha,{"C6_QTDVEN", nQtde, Nil})
			aadd(aLinha,{"C6_PEDCLI", "", Nil})
			aadd(aLinha,{"C6_XCODPED", "", Nil})
			aadd(aLinha,{"C6_PRCVEN", 1, Nil})
			aadd(aLinha,{"C6_PRUNIT", 1, Nil})
			aadd(aItens, aLinha)
		endif
	Next nX
Return(.T.)


Static Function	Estrutura(aBom, cProduto, nQtPai)
	Local cSql := ""
	Local nQtFilho := 0

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM, B1_AGREGCU "
	cSql += " FROM " + RetSQLName("SG1") + " SG1 "
	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON G1_COMP = B1_COD "
	cSql += "WHERE SG1.D_E_L_E_T_ = ' ' "
	cSql += "  AND SB1.D_E_L_E_T_ = ' ' "
	cSql += "  AND G1_FILIAL = '" + xFilial("SG1") + "' "
	cSql += "  AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cSql += "  AND G1_COD = '" + cProduto + "' "
	cSql += " ORDER BY G1_TRT, G1_COMP "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nQtFilho := nQtPai * (cAlias)->G1_QUANT

		aadd(aBOM, {(cAlias)->G1_COMP, nQtFilho, (cAlias)->B1_AGREGCU})

		Estrutura(@aBOM, (cAlias)->G1_COMP, nQtFilho)

		(cAlias)->(DbSkip())
	EndDo
return
