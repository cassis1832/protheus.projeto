#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020A
Função 
   Importação do arquivo texto contendo pedidos EDI
   Gravar tabela ZA0 - movimentos EDI importados 
   Esse programa chamado a partir do PL020 (manutenção do ZA0)
 
@author Assis
@since 08/04/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL030()
/*/

User Function PL020A()
	Local aArea   := GetArea()
	Local cFunBkp := FunName()

	Private cArquivo := ''
	Private cCliente := ''
	Private cLoja	 := ''
	Private dDtEntr  := Date()
	Private aLinhas  := {}
	Private aLinha

	Private dtProcesso := Date()
	Private hrProcesso := Time()

	SetFunName("PL020A")
	cArquivo := selArquivo()

	if cArquivo != ''
		oFile := FWFileReader():New(cArquivo)

		If (oFile:Open())
			If ! (oFile:EoF())
				aLinhas := oFile:GetAllLines()
				TrataLinhas()
			EndIf

			oFile:Close()

			LimpaDados()
		EndIf
	EndIf

	FWAlertSuccess("IMPORTACAO EFETUADA COM SUCESSO! " + cCliente, "Importacao EDI")

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
	Trata todas as linhas que estão na variavel aLinhas
 *---------------------------------------------------------------------*/
Static Function TrataLinhas()

  	Local lErro, nLin 	   		
	Local nTotLinhas := Len(aLinhas)

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
        For nlin := 1 To nTotLinhas
            aLinha := strTokArr(aLinhas [nLin], ';')
            GravaDados()
        next	
    EndIf
 
return

/*---------------------------------------------------------------------*
	Grava tabela ZA0
 *---------------------------------------------------------------------*/
Static Function GravaDados()
    Local lErro     := .T.
    Local cProduto  := ""

    cCodCli  := AvKey(aLinha[3], "A7_CODCLI")
	dDtEntr  := ctod(aLinha[4])
    cHrEntr  := aLinha[5]
	cQtde 	 := aLinha[6]
    cTipoPe  := "F"

	// Consistir o codigo do cliente e item do cliente
	SA7->(DBSetOrder(3))  // Filial/cliente/loja/codcli

    cProduto := ""

	If SA7->(MsSeek(xFilial("SA7") + cCliente + cLoja + cCodCli))
        cProduto := SA7->A7_PRODUTO
        lErro = .F.
    EndIf

	dbSelectArea("ZA0")
    DBSetOrder(2)  // Filial/cliente/loja/item/data

    if (MsSeek(xFilial("ZA0") + cCliente + cLoja + cProduto + dtos(dDtEntr))) 
        RecLock("ZA0", .F.)
        ZA0->ZA0_ARQUIV   := cArquivo
        ZA0->ZA0_DTCRIA   := dtProcesso
        ZA0->ZA0_HRCRIA   := hrProcesso
        ZA0->ZA0_TIPOPE   := cTipoPe

        if ZA0->ZA0_STATUS == "0" .or. ZA0->ZA0_STATUS == "1" 
            ZA0->ZA0_QTDE := Val(StrTran(cQtde,",","."))
        else
            if ZA0->ZA0_QTDE < Val(StrTran(cQtde,",","."))
                ZA0->ZA0_QTDE := Val(StrTran(cQtde,",","."))
            Endif
        Endif
    else
		// Inclusão
		RecLock("ZA0", .T.)	
		ZA0->ZA0_FILIAL	:= xFilial("ZA0")	
		ZA0->ZA0_CODPED := GETSXENUM("ZA0", "ZA0_CODPED", 1)                                                                                                  
		ZA0->ZA0_CLIENT := cCliente
		ZA0->ZA0_LOJA 	:= cLoja
		ZA0->ZA0_PRODUT := cProduto
		ZA0->ZA0_ITCLI 	:= cCodCli
		ZA0->ZA0_TIPOPE := cTipoPe
		ZA0->ZA0_QTDE 	:= Val(StrTran(cQtde,",","."))
		ZA0->ZA0_DTENTR := dDtEntr
		ZA0->ZA0_HRENTR := cHrEntr
		ZA0->ZA0_ARQUIV := cArquivo
		ZA0->ZA0_ORIGEM := "PL020A"
		ZA0->ZA0_DTCRIA := dtProcesso
		ZA0->ZA0_HRCRIA := hrProcesso
		if (lErro)
			ZA0->ZA0_STATUS := "1"
		else
			ZA0->ZA0_STATUS := "0"
		EndIf
		ConfirmSx8()
	endif
	
	MsUnLock() 
Return

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
return


/*---------------------------------------------------------------------*
  Deleta da tabela ZA0 todos os registros que não foram atualizados
 *---------------------------------------------------------------------*/
Static Function LimpaDados()

   	dbSelectArea("ZA0")
   	ZA0->(DBSetOrder(3))  
   
   	DBSeek(xFilial("ZA0") + cCliente + cLoja)
	
	Do While ! Eof() 

	if ZA0->ZA0_CLIENT == cCliente
		if ZA0_STATUS <> "9"
			if ZA0->ZA0_DTCRIA <> dtProcesso .or. ;
				ZA0->ZA0_HRCRIA <> hrProcesso

				RecLock("ZA0", .F.)
				DbDelete()
				ZA0->(MsUnlock())
			endif
		endif
	endif

	DbSkip()
	
   EndDo
return
