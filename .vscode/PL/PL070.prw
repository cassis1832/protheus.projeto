#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"

/*/{Protheus.doc}	PL070
	Extrair dados de uso de maquina em arquivo txt delimitado
@author Carlos Assis
@since 22/07/2024
@version 1.0   
/*/

User Function PL070()
	Local oSay 		:= NIL
	Local aPergs	:= {}
	Local aResps	:= {}

	Private dDtIni  := ""
	Private dDtFim  := ""

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})

	If ParamBox(aPergs, "Extracao de Uso Planejado de Maquina", @aResps,,,,,,,, .T., .T.)
		dDtIni 	:= aResps[1]
		dDtFim 	:= aResps[2]
	Else
		return
	endif

	FwMsgRun(NIL, {|oSay| Processa(oSay)}, "Processando ordens de producao", "Extraindo dados...")

	FWAlertSuccess("GERACAO EFETUADA COM SUCESSO!", "Extracao de Dados de OP")
return


Static Function Processa(oSay)
	Local cArquivo    	:= "c:\temp\PL070.csv"
	Local cLinha	  	:= ""
	Local nQuant		:= 0
	Local nTotal		:= 0
	Local nSetup		:= 0
	Local cQuery 		:= ""
	Local cAlias 		:= ""

	cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "
	cQuery += "	 	  C2_QUANT, C2_DATPRI, C2_DATPRF, C2_TPOP, "
	cQuery += "	  	  B1_COD, B1_DESC, B1_UM, B1_XCLIENT, "
	cQuery += "	      G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, "
	cQuery += "	  	  G2_TEMPAD, G2_LOTEPAD, "
	cQuery += "	  	  H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP "
	cQuery += "  FROM " + RetSQLName("SC2") + " SC2 "

	cQuery += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cQuery += "	   ON B1_COD 		 =  C2_PRODUTO"
	cQuery += "   AND B1_FILIAL 	 = '" + xFilial("SB1") + "' "
	cQuery += "	  AND SB1.D_E_L_E_T_ = ' ' "

	cQuery += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cQuery += "    ON G2_PRODUTO = C2_PRODUTO"
	cQuery += "   AND G2_FILIAL 	 = '" + xFilial("SG2") + "' "
	cQuery += "   AND SG2.D_E_L_E_T_ = ''

	cQuery += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cQuery += "    ON H1_CODIGO = G2_RECURSO"
	cQuery += "   AND H1_FILIAL 	 = '" + xFilial("SH1") + "' "
	cQuery += "   AND SH1.D_E_L_E_T_ = ''

	cQuery += " WHERE C2_DATPRF >= '" + dtos(dDtIni) + "'"
	cQuery += "   AND C2_DATPRF <= '" + dtos(dDtFim) + "'"
	cQuery += "   AND C2_FILIAL 	 = '" + xFilial("SC2") + "' "
	cQuery += "	  AND SC2.D_E_L_E_T_ = ' ' "
	cQuery += "	ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cQuery)

	oFile := FWFileWriter():New(cArquivo, .T.)

	If oFile:Exists()
		oFile:Erase()
	EndIf

	If (oFile:Create())
		cLinha := "Numero Ordem;Tipo;Produto;Descricao;Cliente;Operacao;Maquina;Operadores;Tempo Padrao;Lote Padrao;Dt.Inicio;Dt.Fim;"
		cLinha += "Quantidade;UM;Setup;Qtde.Horas;Horas Totais;Linha;Local;Tipo"
		oFile:Write(cLinha + CRLF)

		While (cAlias)->(! EOF())
			nQuant := (cAlias)->C2_QUANT / (cAlias)->G2_LOTEPAD

			if (cAlias)->G2_SETUP > 0
				nSetup	:= (cAlias)->G2_SETUP
			else
				if (cAlias)->H1_XSETUP > 0
					nSetup	:= (cAlias)->H1_XSETUP
				else
					nSetup	:= 0.5
				endif
			endif

			nTotal := nSetup + nQuant

			cLinha := Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN) + ";"
			cLinha += AllTrim((cAlias)->C2_TPOP) + ";"
			cLinha += AllTrim((cAlias)->C2_PRODUTO) + ";"
			cLinha += AllTrim((cAlias)->B1_DESC) + ";"
			cLinha += AllTrim((cAlias)->B1_XCLIENT) + ";"
			cLinha += AllTrim((cAlias)->G2_OPERAC) + ";"
			cLinha += AllTrim((cAlias)->G2_RECURSO) + ";"
			cLinha += AllTrim(cValToChar((cAlias)->G2_MAOOBRA)) + ";"
			cLinha += TRANSFORM((cAlias)->G2_TEMPAD, "@E 999999.99") + ";"
			cLinha += TRANSFORM((cAlias)->G2_LOTEPAD, "@E 999999.99") + ";"
			cLinha += dtoc(stod((cAlias)->C2_DATPRI)) + ";"
			cLinha += dtoc(stod((cAlias)->C2_DATPRF)) + ";"
			cLinha += TRANSFORM((cAlias)->C2_QUANT, "@E 999999") + ";"
			cLinha += AllTrim((cAlias)->B1_UM) + ";"
			cLinha += TRANSFORM(nSetup, "@E 999999.99") + ";"
			cLinha += TRANSFORM(nQuant, "@E 999999.99") + ";"
			cLinha += TRANSFORM(nTotal, "@E 999999.99") + ";"
			cLinha += AllTrim((cAlias)->H1_XLIN) + ";"
			cLinha += AllTrim((cAlias)->H1_XLOCLIN) + ";"
			cLinha += AllTrim((cAlias)->H1_XTIPO) + ";"
			oFile:Write(cLinha + CRLF)

			(cAlias)->(DbSkip())
		enddo

		oFile:Close()
	Endif

	(cAlias)->(DBCLOSEAREA())
return

