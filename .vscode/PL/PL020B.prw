#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020B
Função 
   Importação do arquivo texto contendo pedidos EDI
   Gravar tabela ZA0 - movimentos EDI importados 
   Esse programa chamado a partir do PL020 (manutenção do ZA0)
	cCliente	:= aLinha[1]
	cLoja 	    := aLinha[2]
	cNumPed 	:= aLinha[3]
	cCodCli 	:= aLinha[4]
	cDtEntr 	:= aLinha[6]
	cQtde 	    := aLinha[7]
	cTipo		:= aLinha[8]
	cEmbal 	    := aLinha[9]
	cQtEmb	    := aLinha[10]

@author Assis
@since 08/04/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL030()
/*/

User Function PL020B()
	Local aArea   := GetArea()
	Local cFunBkp := FunName()

	Private cArquivo := ''
	Private cCliente := ''
	Private cLoja	 := ''
	Private aLinhas
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
		EndIf
	EndIf

	MostraErro()

	MessageBox("IMPORTAÇÃO EFETUADA COM SUCESSO!","",0)

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
	Trata todas as linhas que estão na variavel aLinhas
 *---------------------------------------------------------------------*/
Static Function TrataLinhas()

  	Local lErro 
	Local nLin 	   		
	Local nTotLinhas := Len(aLinhas)

	// Salva o cliente/loja da primeira linha (que deve ser o mesmo das demais linhas)
  	aLinha   := strTokArr(aLinhas [1], ';')
	cCliente := aLinha[1]
	cLoja	 := aLinha[2]

   // Ver se o cliente está cadastrado
	dbSelectArea("SA1")
	SA1->(DBSetOrder(1))  // Filial/codigo/loja

 	DBSeek(xFilial("SA1")+cCliente+cLoja)

	if ! Eof()
		IF A1_FILIAL == xFilial("SA1") .And. A1_COD == cCliente .And. A1_LOJA == cLoja 
			lErro := .F.
		Else
            FWAlertError("Cliente não cadastrado: " + cCliente,"Cadastro de clientes")
		    lErro := .T.
		EndIf
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
    Local lErro := .T.
    Local cProduto

	cCliente := aLinha[1]
	cLoja 	 := aLinha[2]
	cNumPed  := aLinha[3]
	cCodCli  := aLinha[4]
	cDtEntr  := aLinha[5]
	cQtde 	 := aLinha[6]
	cTipo	 := aLinha[7]
	cEmbal 	 := aLinha[8]
	cQtEmb	 := aLinha[9]

	// Consistir o codigo do cliente e item do cliente
	dbSelectArea("SA7")
	SA7->(DBSetOrder(3))  // Filial/cliente/loja/codcli

 	DBSeek(xFilial("SA7")+cCliente+cLoja+cCodCli)

    if ! Eof()
        IF A7_FILIAL == xFilial("SA7") .And. A7_CLIENTE == cCliente .And. A7_LOJA == cLoja .And. A7_CODCLI == cCodCli
            cProduto := A7_PRODUTO
            lErro = .F.
        Else
            cProduto := ''
        EndIf
    EndIf

    dbSelectArea("ZA0")
    ZA0->(DBSetOrder(2))  // Filial/cliente/loja/item/data
   
    MsSeek(xFilial("ZA0")+cCliente+cLoja+cProduto+cDtEntr)

    if ! Eof() .And. ;
        ZA0_FILIAL == xFilial("ZA0") .And. ;
        ZA0_CLIENT == cCliente .And. ;
        ZA0_LOJA   == cLoja .And. ;
        ZA0_PRODUT == cProduto .And. ;
        ZA0_DTENTR == cDtEntr

		RecLock("ZA0", .F.)
        ZA0->ZA0_TIPOPE   := cTipo
		ZA0->ZA0_EMBAL 	  := cEmbal
		ZA0->ZA0_QTEMB 	  := Val(StrTran(cQtEmb,",","."))
		ZA0->ZA0_ARQUIV   := cArquivo
		ZA0->ZA0_DTCRIA   := dtProcesso
		ZA0->ZA0_HRCRIA   := hrProcesso

		if ZA0_STATUS == "0" .or. ZA0_STATUS == "1" 
            ZA0->ZA0_QTDE := Val(StrTran(cQtde,",","."))
        else
            if ZA0->ZA0_QTDE < Val(StrTran(cQtde,",","."))
	            ZA0->ZA0_QTDE := Val(StrTran(cQtde,",","."))
			else
                ConOut("Quantidade divergente do pedido " + cProduto + " " + cDtEntr + " " + cQtde)
            Endif
        Endif
	else
		// Inclusão
		DbSelectArea("ZA0")
		RecLock("ZA0", .T.)	
		ZA0->ZA0_FILIAL	:= xFilial("ZA0")	
		ZA0->ZA0_CODPED := GETSXENUM("ZA0", "ZA0_CODPED")                                                                                                  
		ZA0->ZA0_CLIENT := cCliente
		ZA0->ZA0_LOJA 	:= cLoja
		ZA0->ZA0_NUMPED := cNumped
		ZA0->ZA0_PRODUT := cProduto
		ZA0->ZA0_ITCLI 	:= cCodCli
		ZA0->ZA0_TIPOPE := cTipo
		ZA0->ZA0_QTDE 	:= Val(StrTran(cQtde,",","."))
		ZA0->ZA0_DTENTR := CTOD(cDtEntr)
		ZA0->ZA0_EMBAL 	:= cEmbal
		ZA0->ZA0_QTEMB 	:= Val(StrTran(cQtEmb,",","."))
		ZA0->ZA0_ARQUIV := cArquivo
		ZA0->ZA0_ORIGEM := "PL030"
		ZA0->ZA0_DTCRIA := dtProcesso
		ZA0->ZA0_HRCRIA := hrProcesso
		if (lErro)
			ZA0->ZA0_STATUS := "1"
		else
			ZA0->ZA0_STATUS := "0"
		EndIf
	endif
	
	MsUnLock() 
Return

/*---------------------------------------------------------------------*
	Abre box para o usuario selecionar o arquivo que deseja importar
 *---------------------------------------------------------------------*/
Static Function selArquivo()

	Local cDirIni := GetTempPath()
	Local cTipArq := "Arquivos texto (*.txt)"
	Local cTitulo := "Seleção de arquivo para processamento"
	Local lSalvar := .F.
	Local cArqSel := ""

	cArqSel := tFileDialog(;
	   cTipArq,;  // Filtragem de tipos de arquivos que ser�o selecionados
	   cTitulo,;  // Titulo da Janela para seleção dos arquivos
	   ,;         // Compatibilidade
	   cDirIni,;  // Diretorio inicial da busca de arquivos
	   lSalvar,;  // Se for .T., serA uma Save Dialog, senão ser� Open Dialog
	   ;          // Se não passar parAmetro, ir� pegar apenas 1 arquivo; Se for informado GETF_MULTISELECT serA possIvel pegar mais de 1 arquivo; Se for informado GETF_RETDIRECTORY ser� poss�vel selecionar o diret�rio
	)

	If ! Empty(cArqSel)
	   MsgInfo("O arquivo selecionado foi: " + cArqSel, "Atenção")
		Return cArqSel
	EndIf
return


/*---------------------------------------------------------------------*
  Deleta da tabela ZA0 todos os registros que não foram atualizados
 *---------------------------------------------------------------------*/
Static Function LimpaDados()

   	dbSelectArea("ZA0")
   	ZA0->(DBSetOrder(2))  // Filial/cliente/loja
   
   	DBSeek(xFilial("ZA0")+cCliente+cLoja)

	Do While ! Eof() .And. ;
		ZA0_FILIAL == xFilial("ZA0") .And. ;
		ZA0_CLIENT == cCliente .And. ;
		ZA0_LOJA == cLoja

		if ZA0_STATUS <> "9"
			if ZA0->ZA0_DTCRIA <> dtProcesso .or. ;
				ZA0->ZA0_HRCRIA <> hrProcesso

				RecLock("ZA0", .F.)
				DbDelete()
				ZA0->(MsUnlock())
			endif
		endif

		DbSkip()
   EndDo
return
