#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'

//------------------------------------------------------------------------------
/*/{Protheus.doc} PL180B	
   Função que carrega a Estrutura do Produto para o Pedido de Venda
 	Itens a faturar		(produto[1], qtde[2], data[3], pedido[4], acao[5])
	07/08/2024 - Tratar item bloqueado
	14/10/2024 - Tratar data de inicio e fim da estrutura
/*/
//------------------------------------------------------------------------------
User Function PL180B(aItensFat)
	Local nX        	:= 0
	Local aItensRet		:= {}

	For nX := 1 To Len(aItensFat)
		Estrutura(@aItensRet, nX, aItensFat[nX][1], aItensFat[nX][2], aItensFat[nX][3])
	next nX

	//------------------------------------------------------------------------------
	// Remove os componentes que não são de terceiros
	//------------------------------------------------------------------------------
	// For nX := 1 To Len(aItensRet)
	// 	if aItensRet[nX][4] <> "1" // permite agregar custo
	// 		aDel(aItensRet, nX)
	// 	endif
	// Next nX
Return(aItensRet)


Static Function	Estrutura(aItensRet, nX, cProduto, nQtPai, dData)
	Local cSql 		:= ""
	Local nQtFilho 	:= 0
	Local cAliasSG1

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM, B1_AGREGCU "
	cSql += "  FROM " + RetSQLName("SG1") + " SG1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON B1_COD			=  G1_COMP "
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += " WHERE G1_COD 			= '" + cProduto + "' "
	cSql += "   AND G1_INI 		   <= '" + dtos(dData) + "' "
	cSql += "   AND G1_FIM 		   >= '" + dtos(dData) + "' "
	cSql += "   AND G1_FILIAL 		= '" + xFilial("SG1") + "' "
	cSql += "   AND SG1.D_E_L_E_T_ 	= ' ' "
	cSql += " ORDER BY G1_TRT, G1_COMP "
	cAliasSG1 := MPSysOpenQuery(cSql)

	While (cAliasSG1)->(!EOF())
		nQtFilho := nQtPai * (cAliasSG1)->G1_QUANT
		aadd(aItensRet, {nX, (cAliasSG1)->G1_COMP, nQtFilho, (cAliasSG1)->B1_AGREGCU})

		Estrutura(@aItensRet, nX, (cAliasSG1)->G1_COMP, nQtFilho, dData)

		(cAliasSG1)->(DbSkip())
	EndDo

	(cAliasSG1)->(DBCLOSEAREA())
return
