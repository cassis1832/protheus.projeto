#Include "PROTHEUS.CH"
#Include "TBICONN.CH"

/*/{Protheus.doc}	PL010
	Impressao da Ordem de Producao Modelo MR V01
	29/07/2024 - não imprimir OP prevista
@author Carlos Assis
@since 04/11/2023
@version 1.0   
/*/

User Function PL010()
	Local aPergs	    := {}
	Local aResps	    := {}

	Local lOp 	    	:= .T.  		   	// Deseja imprimir a ordem de produção
	Local lReimp    	:= .F.  		   	// Reimpressao de ordem
	Local lEtiq 	    := .T.  		   	// Deseja imprimir etiquetas
	Local cQuery 	    := ""

	Local cOrdemIni   	:= ""
	Local cOrdemFim   	:= ""
	Local cOp		    := ""

	Local lOper 	    := .T.  		   	// Todas as operacões juntas
	Local cAliasOrd 	:= ""			   	// Dados da OP

	AAdd(aPergs, {1, "Numero da Ordem Inicial"		, Space(11),,,"SC2",, 60, .T.})
	AAdd(aPergs, {1, "Numero da Ordem Final"		, Space(11),,,"SC2",, 60, .T.})
	AAdd(aPergs, {4, "Imprimir Ordem de Producao"	,.T.,"Deseja imprimir a OP" ,90,"",.F.})
	AAdd(aPergs, {4, "Reimpressao"					,.T.,"Imprime novamente" ,90,"",.F.})
	AAdd(aPergs ,{4, "Operacoes"   					,.T.,"Todas as operacoes juntas" ,90,"",.F.})
	AAdd(aPergs ,{4, "Imprimir Etiquetas"			,.T.,"Deseja imprimir etiquetas" ,90,"",.F.})

	If ParamBox(aPergs, "EMISSAO DE ORDEM DE PRODUCAO", @aResps,,,,,,,, .T., .T.)
		cOrdemIni  	:= aResps[1]
		cOrdemFim  	:= aResps[2]
		lOP			:= aResps[3]
		lReimp		:= aResps[4]
		lOper		:= aResps[5]
		lEtiq		:= aResps[6]
	Else
		return
	endif

	if lOp == .F. .AND. lEtiq == .F.
		return
	endif

	if lReimp == .T.
		// Assis/Camila/Elisangela/Teste
		if RetCodUsr() != "000001" .and. RetCodUsr() !="000019" .and. RetCodUsr() !="000037" .and. RetCodUsr() !="000040"
			FWAlertError("Usuario nao autorizado para reimprimir ordem","Impressao de ordem")
			Return
		endif
	endif

	if len(allTrim(cOrdemIni)) == 6
		cOrdemIni := allTrim(cOrdemIni) + "01001"
	endif
	if len(allTrim(cOrdemFim)) == 6
		cOrdemFim := allTrim(cOrdemFim) + "01001"
	endif

	if lOp == .T.
		// LER OPS E ITEM
		cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN "
		cQuery += "  FROM " + RetSQLName("SC2") + " SC2 "

		cQuery += " WHERE C2_NUM + C2_ITEM + C2_SEQUEN >='" + cOrdemIni + "'"
		cQuery += "   AND C2_NUM + C2_ITEM + C2_SEQUEN <='" + cOrdemFim + "'"
		cQuery += "   AND C2_TPOP 	 	 <> 'P'"
		cQuery += "   AND C2_FILIAL 	 =  '" + xFilial("SC2") + "' "
		cQuery += "	  AND SC2.D_E_L_E_T_ =  ' ' "

		if lReimp == .T.
			cQuery += "   AND C2_XPRTOP	 =  'S'"
		Else
			cQuery += "   AND C2_XPRTOP	 <>  'S'"
		Endif

		cQuery += "	ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN "
		cAliasOrd := MPSysOpenQuery(cQuery)

		if (cAliasOrd)->(EOF())
			FWAlertError("NENHUMA ORDEM DE PRODUCAO FOI ENCONTRADA!", "ERRO")
			return
		endif

		While (cAliasOrd)->(! EOF())
			cOp := (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN
			u_PL010A(cOp, lOper, lReimp)
			(cAliasOrd)->(DbSkip())
		enddo

		(cAliasOrd)->(DBCLOSEAREA())
	Endif

	// Impressao das etiquetas de processo
	if lEtiq == .T.
		u_PL110(cOrdem)
	endif
return
