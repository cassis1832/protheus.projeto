#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020A
Função 
   	Importação do arquivo texto contendo pedidos EDI
   	Gravar tabela ZA0 - movimentos EDI importados 
   	Esse programa chamado a partir do PL020 (manutenção do ZA0)
	19/07/2024 - Gerar previsão mensal
	02/08/2024 - Desprezar previsao no passado
	02/09/2024 - Não gravar pedidos no passado
@author Assis
@since 08/04/2024
@version 1.0
	@return Nil, Função não tem retorno


/*/
User Function PL020A()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()
	Local aLinhas  		:= {}

	Private cCliente 	:= ''
	Private cLoja	 	:= ''
	Private cArquivo 	:= ''
	Private cProduto  	:= ""
	Private cCodCli  	:= ""

	Private dtProcesso 	:= GetdDataBase()
	Private hrProcesso 	:= Time()

	SetFunName("PL020A")
	cArquivo := selArquivo()

	if cArquivo != Nil .And. cArquivo != ''
		oFile := FWFileReader():New(cArquivo)

		If (oFile:Open())
			If ! (oFile:EoF())
				aLinhas := oFile:GetAllLines()
				FwMsgRun(NIL, {|oSay| TrataLinhas(oSay, aLinhas)}, "Importanto pedidos", "Importando pedidos EDI...")
			EndIf

			oFile:Close()

			FwMsgRun(NIL, {|oSay| LimpaDados(oSay)}, "Excluindo pedidos antigos", "Excluindo pedidos antigos...")

			FWAlertSuccess("IMPORTACAO EFETUADA COM SUCESSO! " + cCliente, "Importacao EDI")
		EndIf
	EndIf

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
	Trata todas as linhas que estao na variavel aLinhas
 *---------------------------------------------------------------------*/
Static Function TrataLinhas(oSay, aLinhas)
	Local nLin 	   		:= 0
	Local aLinha		:= {}

  	Private lErro		:= .F.

	if Len(aLinhas) == 0
		return
	endif
	
	// Salva o cliente/loja da primeira linha (que deve ser o mesmo das demais linhas)
  	aLinha   := strTokArr(aLinhas [1], ';')
	cCliente := AvKey(aLinha[1], "A1_COD")
	cLoja	 := AvKey(aLinha[2], "A1_LOJA")

   // Ver se o cliente está cadastrado
	dbSelectArea("SA1")
	SA1->(DBSetOrder(1))  // Filial/codigo/loja

	If SA1->(MsSeek(xFilial("SA1") + cCliente + cLoja))
        lErro := .F.
    Else
        FWAlertError("Cliente nao cadastrado: " + cCliente,"Cadastro de clientes")
        lErro := .T.
	EndIf

    if ! lErro
		dbSelectArea("ZA0")
	    DBSetOrder(2)  // Filial/cliente/loja/item/data

        For nlin := 1 To Len(aLinhas) Step 1
            aLinha 	:= strTokArr(aLinhas [nLin], ';')
			cCodCli := Upper(AvKey(aLinha[3], "A7_CODCLI"))

			// Consistir o codigo do cliente e item do cliente
			SA7->(DBSetOrder(3))  // Filial/cliente/loja/codcli

			If SA7->(MsSeek(xFilial("SA7") + cCliente + cLoja + cCodCli))
				cProduto := SA7->A7_PRODUTO
				lErro = .F.

				if aLinha[7] == 'V'
					CriaPrevisao(aLinha)
				else
					// Gestamp rateia quantidade mensal
					if (cCliente >= '000004' .and. cCliente <= '000007')
						RateiaMensal(aLinha)
					else
						GravaRegistro(aLinha)
					endif
				endif
			EndIf
        next	
    EndIf
return


/*---------------------------------------------------------------------*
	Cria 4 linhas de pedidos a cada 7 dias para o mes da previsão
 *---------------------------------------------------------------------*/
Static Function CriaPrevisao(aLinha)
	Local aLin		:= aLinha
	Local dData		:= firstDate(ctod(aLinha[4]))
	Local nQtde		:= Val(StrTran(aLinha[6],",","."))

	aLin[6] := Str(Ceiling(nQtde / 4))		// 4 semanas

	dData := AjustaFDS(dData)
	aLin[4] := dtoc(dData)
	GravaRegistro(aLin)

	dData := daySum(dData, 7)
	dData := AjustaFDS(dData)
	aLin[4] := dtoc(dData)
	GravaRegistro(aLin)

	dData := daySum(dData, 7)
	dData := AjustaFDS(dData)
	aLin[4] := dtoc(dData)
	GravaRegistro(aLin)

	dData := daySum(dData, 7)
	dData := AjustaFDS(dData)
	aLin[4] := dtoc(dData)
	GravaRegistro(aLin)
return


/*---------------------------------------------------------------------*
  Rateia a quantidade mensal nos dias uteis que faltam ate o fim do mes
 *---------------------------------------------------------------------*/
Static Function RateiaMensal(aLinha)
	Local aLin		:= aLinha
	Local dData		:= firstDate(ctod(aLin[4]))
	Local nQtde		:= Ceiling(Val(StrTran(aLin[6],",",".")))
	Local nQtdeLin	:= 0
	Local nDias		:= 0
	Local nMes		:= 0

	dbSelectArea("SB1")
	SB1->(DBSetOrder(1))  // Filial/codigo

	// Atualiza o consumo mensal e o estoque de seguranca
	if SA7->A7_XCONSME != nQtde
		RecLock("SA7", .F.)	
		SA7->A7_XCONSME := nQtde
		SA7->(MsUnLock())

		// If SB1->(MsSeek(xFilial("SB1") + cProduto))
		// 	RecLock("SB1", .F.)	
		// 	SB1->B1_ESTSEG := Ceiling(nQtde / 20 * 3)
		// 	SB1->(MsUnLock())
		// endIf
	endif

	nMes := Month(dData)

	// Conta os dias uteis do mes
	Do While Month(dData) == nMes
		if (dow(dData) > 1 .and. dow(dData) < 7)
			nDias++
		endif

		dData := daySum(dData, 1)
	EndDo

	nQtdeLin := nQtde / nDias
	nQtdeLin := Ceiling(nQtdeLin / 100) * 100

	aLin[6] := Str(nQtdeLin)
	dData 	:= firstDate(ctod(aLinha[4]))

	// Grava somente os dias uteis futuros
	Do While Month(dData) == nMes
		if (dow(dData) > 1 .and. dow(dData) < 7)
			aLin[4] := dtoc(dData)
			GravaRegistro(aLin)
		endif
		dData := daySum(dData, 1)
	EndDo
Return


Static Function GravaRegistro(aLinha)
	Local dData 	:= ctod(aLinha[4])

	if dData <= GetdDataBase()
		return
	endif

	// Ver o tipo de pedido (P/F/V)
	if aLinha[7] <> "F"
		dData := AjustaFDS(dData)
	endif

	if (MsSeek(xFilial("ZA0") + cCliente + cLoja + cProduto + dtos(dData))) 
			RecLock("ZA0", .F.)
			ZA0->ZA0_ARQUIV   	:= cArquivo
			ZA0->ZA0_DTCRIA   	:= dtProcesso
			ZA0->ZA0_HRCRIA   	:= hrProcesso
			ZA0->ZA0_TIPOPE   	:= aLinha[7]
			ZA0->ZA0_QTDE    	:= Val(StrTran(aLinha[6],",","."))
			ZA0->ZA0_STATUS		:= "0"
		else
			// Inclusão
			RecLock("ZA0", .T.)	
			ZA0->ZA0_FILIAL		:= xFilial("ZA0")	
			ZA0->ZA0_CODPED 	:= GETSXENUM("ZA0", "ZA0_CODPED", 1)                                                                                                  
			ZA0->ZA0_CLIENT 	:= cCliente
			ZA0->ZA0_LOJA 		:= cLoja
			ZA0->ZA0_PRODUT 	:= cProduto
			ZA0->ZA0_ITCLI 		:= cCodCli
			ZA0->ZA0_TIPOPE 	:= aLinha[7]
			ZA0->ZA0_QTDE 		:= Val(StrTran(aLinha[6],",","."))
			ZA0->ZA0_DTENTR 	:= dData
			ZA0->ZA0_HRENTR 	:= aLinha[5]
			ZA0->ZA0_ARQUIV 	:= cArquivo
			ZA0->ZA0_ORIGEM 	:= "PL020A"
			ZA0->ZA0_DTCRIA 	:= dtProcesso
			ZA0->ZA0_HRCRIA 	:= hrProcesso
			if (lErro)
				ZA0->ZA0_STATUS := "1"
			else
				ZA0->ZA0_STATUS := "0"
			EndIf
			ConfirmSx8()
		endif

		MsUnLock() 
Return


Static Function	AjustaFDS(dData)

	if dow(dData) == 1
		return daySum(dData, 1)
	endif

	if dow(dData) == 7
		return daySum(dData, 2)
	endif

Return dData


/*---------------------------------------------------------------------*
	Abre box para o usuario selecionar o arquivo que deseja importar
 *---------------------------------------------------------------------*/
Static Function selArquivo()
	Local cDirIni := GetTempPath()
	Local cTipArq := "Arquivos texto (*.txt)"
	Local cTitulo := "Selecao de arquivo para processamento"
	Local lSalvar := .F.
	Local cArqSel := ""

	cArqSel := tFileDialog(cTipArq, cTitulo,, cDirIni, lSalvar)

	If ! Empty(cArqSel)
    	If FWAlertYesNo("ARQUIVO SELECIONADO = " + cArqSel, "CONFIRMA A ATUALIZACAO?")
    		Return cArqSel
		EndIf
	EndIf
return Nil


/*---------------------------------------------------------------------*
  Deleta da tabela ZA0 todos os registros que não foram atualizados
 *---------------------------------------------------------------------*/
Static Function LimpaDados(oSay)
	Local cSql	:= ''

	cSql := "DELETE FROM "  + RetSQLName("ZA0")
	cSql += " WHERE ZA0_FILIAL  = '" + xFilial("ZA0") + "' "
	cSql += "	AND ZA0_CLIENT  = '" + cCliente + "'"
	cSql += "	AND	ZA0_LOJA    = '" + cLoja + "'"
	cSql += "	AND	ZA0_STATUS <> '9'" 
	cSql += "	AND	ZA0_TIPOPE <> 'M'"
	cSql += "	AND ZA0_DTCRIA <> '" + dtProcesso + "'"
	cSql += "	AND ZA0_HRCRIA <> '" + hrProcesso + "'"

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na delete do ZA0:", "Atenção")
		MsgInfo(TcSqlError(), "Atenção2")
	endif
Return
