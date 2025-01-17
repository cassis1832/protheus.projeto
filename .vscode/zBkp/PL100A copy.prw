#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'

//------------------------------------------------------------------------------
/*/{Protheus.doc} PL100A
   Função que carrega a Estrutura do Produto para o Pedido de Venda
/*/
//------------------------------------------------------------------------------
User Function PL100A(aItensFat)
	Local nX        	:= 0
	Local aItensRet		:= {}
	Local nIndProduto 	:= aScan(aItensFat[Len(aItensFat)],{|x| AllTrim(x[1]) == "C6_PRODUTO"})
	Local nIndQtVen  	:= aScan(aItensFat[Len(aItensFat)],{|x| AllTrim(x[1]) == "C6_QTDVEN"})

	For nX := 1 To Len(aItensFat)
		Estrutura(@aItensRet, nX, ;
			aItensFat[nX][nIndProduto][2], ;
			aItensFat[nX][nIndQtVen][2])
	next nX

	//------------------------------------------------------------------------------
	// Remove os componentes que não são de terceiros
	//------------------------------------------------------------------------------
	For nX := 1 To Len(aItensRet)
		if aItensRet[nX][3] <> "1" // permite agregar custo
			aDel(aItensRet, nX)
		endif
	Next nX
Return(aItensRet)


Static Function	Estrutura(aItensRet, nX, cProduto, nQtPai)
	Local cSql := ""
	Local nQtFilho := 0
	Local cAliasSG1

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
		aadd(aItensRet, {nX, (cAliasSG1)->G1_COMP, nQtFilho, (cAliasSG1)->B1_AGREGCU})
		Estrutura(@aItensRet, nX, (cAliasSG1)->G1_COMP, nQtFilho)
		(cAliasSG1)->(DbSkip())
	EndDo
return
