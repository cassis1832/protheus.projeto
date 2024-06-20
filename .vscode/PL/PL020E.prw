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
	Local nPData    := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ENTREG"})
	Local nItem     := aScan(aItens[Len(aItens)],{|x| AllTrim(x[1]) == "C6_ITEM"})
	Local nX        := 0
	Local nQtde		:= 0

	Local cItem 	:= val(aItens[Len(aItens)][nItem][2])

	// Explodir a última linha da tabela
	Estrutura(@aBom, aItens[Len(aItens)][nPProduto][2],	aItens[Len(aItens)][nPQtdVen][2])

	//------------------------------------------------------------------------------
	// Adiciona os componentes no aItens
	//------------------------------------------------------------------------------
	For nX := 1 To Len(aBOM)

		if aBOM[nX][3] == "1" // permite agregar custo
			cItem := cItem + 1

			nQtde := aBOM[nX][2]

			aLinha := {}
			aadd(aLinha,{"C6_ITEM"		, StrZero(cItem, 2), Nil})
			aadd(aLinha,{"C6_PRODUTO"	, aBOM[nX][1], Nil})
			aadd(aLinha,{"C6_QTDVEN"	, nQtde, Nil})
			aadd(aLinha,{"C6_PRCVEN"	, 1, Nil})
			aadd(aLinha,{"C6_PRUNIT"	, 1, Nil})
			aadd(aLinha,{"C6_TES"		, "888", Nil})
			aadd(aLinha,{"C6_ENTREG"	, aItens[Len(aItens)][nPData][2], Nil})
			aadd(aLinha,{"C6_PEDCLI"	, "", Nil})
			aadd(aLinha,{"C6_XCODPED", "", Nil})
			aadd(aItens, aLinha)
		endif
	Next nX
Return(.T.)


Static Function	Estrutura(aBom, cProduto, nQtPai)
	Local cAliasSG1
	Local cSql := ""
	Local nQtFilho := 0

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM, B1_AGREGCU "
	cSql += " FROM " + RetSQLName("SG1") + " SG1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON G1_COMP 		= B1_COD "
	cSql += "  AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "  AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += "WHERE SG1.D_E_L_E_T_ = ' ' "
	cSql += "  AND G1_FILIAL = '" + xFilial("SG1") + "' "
	cSql += "  AND G1_COD = '" + cProduto + "' "
	cSql += " ORDER BY G1_TRT, G1_COMP "

	cAliasSG1 := MPSysOpenQuery(cSql)

	While (cAliasSG1)->(!EOF())
		nQtFilho := nQtPai * (cAliasSG1)->G1_QUANT

		aadd(aBOM, {(cAliasSG1)->G1_COMP, nQtFilho, (cAliasSG1)->B1_AGREGCU})

		Estrutura(@aBOM, (cAliasSG1)->G1_COMP, nQtFilho)

		(cAliasSG1)->(DbSkip())
	EndDo
return
