#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL030
Função Leitura do arquivo texto contendo pedidos EDI
    Gravar tabela ZA0
@author Assis
@since 08/04/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL030()
/*/

User Function PL030()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	//----------------------------------------------
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase
	//----------------------------------------------

	Private cArquivo	:= ''
	Private cCliente	:= ''
	Private cLoja		:= ''
	Private aLinhas

	SetFunName("PL030")

	cArquivo := selArquivo()

	oFile := FWFileReader():New(cArquivo)

	If (oFile:Open())
		If ! (oFile:EoF())
			aLinhas := oFile:GetAllLines()
			TrataLinhas()
		EndIf
	EndIf

	oFile:Close()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


/*---------------------------------------------------------------------*
  Func:  TrataLinhas
  Autor: Carlos Assis
  Desc:  Trata todas as linhas que estão na variavel aLinhas
 *---------------------------------------------------------------------*/
Static Function TrataLinhas()
   Local nLin 	   		
	Local aLinha
	Local nTotLinhas := Len(aLinhas)

	Alert(nTotLinhas)

	// Salva o cliente/loja da primeira linha (que deve ser o mesmo das demais linhas)
   aLinha   := strTokArr(aLinhas [1], ';')
	cCliente := aLinha[1]
	cLoja		:= aLinha[2]
	LimpaDados()

   For nlin := 1 To nTotLinhas
    	aLinha := strTokArr(aLinhas [nLin], ';')
		MessageBox(aLinha,"",0)
		GravaDados()
	next	
return


Static Function LimpaDados()

   dbSelectArea("ZA0")
   ZA0->(DBSetOrder(2))  // Filial/cliente/loja
   
   DBSeek(xFilial("ZA0")+cCliente+cLoja)

   Do While ! Eof() .And. ZA0_FILIAL == xFilial("ZA0") .And. ZA0_CLIENT == cCliente .And. ZA0_LOJA == cLoja

      RecLock("ZA0", .F.)
      DbDelete()
      ZA0->(MsUnlock())

      DbSkip()
   EndDo

return


Static Function GravaDados(aLinha)
	Local lErro := false

	cCliente := aLinha[1]
	cLoja 	:= aLinha[2]
	cNumPed 	:= aLinha[3]
	cCodCli 	:= aLinha[4]
	cDtEntr 	:= aLinha[6]
	cQtde 	:= aLinha[7]
	cTipo		:= aLinha[8]
	cEmbal 	:= aLinha[9]
	cQtEmb	:= aLinha[10]

	// Consistir o código do cliente e item do cliente
	dbSelectArea("SA7")
	SA7->(DBSetOrder(3))  // Filial/cliente/loja/codcli

 	DBSeek(xFilial("SA7")+cCliente+cLoja+cCodCli)

   if ! Eof()
      IF A7_FILIAL == xFilial("SA7") .And. A7_CLIENTE == cCliente .And. A7_LOJA == cLoja .And. A7_CODCLI == cCodCli
         MsgInfo("O cliente/item foi localizado!", "Função DBSeek")
      Else
         MsgInfo("O cliente/item não foi localizado!", "Função DBSeek")
		   lErro = true
      EndIf
   EndIf

	// Inclusão
	DbSelectArea("ZA0")
	RecLock("ZA0", .T.)	
	ZA0->ZA0_FILIAL := xFilial("ZA0")	
	ZA0->ZA0_CODPED := ""	
	ZA0->ZA0_CLIENT := cCliente
	ZA0->ZA0_LOJA 	:= cLoja
	ZA0->ZA0_NUMPED := cNumped
	ZA0->ZA0_PRODUT := cProduto
	ZA0->ZA0_ITCLI 	:= cCodCli
	ZA0->ZA0_TIPOPE := cTipo
	ZA0->ZA0_QTDE 	:= cQtde
	ZA0->ZA0_DTENTR := cDtEntr
	ZA0->ZA0_EMBAL 	:= cEmbal
	ZA0->ZA0_QTEMB 	:= cQtEmb"
	ZA0->ZA0_ARQUIV := cArquivo
	ZA0->ZA0_ORIGEM := "PL030"
	ZA0->ZA0_DTCRIA := Date()
	ZA0->ZA0_HRCRIA := Time()
	if (lErro)
		ZA0->ZA0_STATUS := "1"
	else
		ZA0->ZA0_STATUS := "2"
	EndIf

	MsUnLock() 
Return

Static Function selArquivo()
	Local cDirIni := GetTempPath()
	Local cTipArq := "Todas extensões (*.*) | Arquivos texto (*.txt) | Arquivos com separações (*.csv)"
	Local cTitulo := "Seleção de Arquivos para Processamento"
	Local lSalvar := .F.
	Local cArqSel := ""

	cArqSel := tFileDialog(;
		cTipArq,;  // Filtragem de tipos de arquivos que serão selecionados
	cTitulo,;  // Título da Janela para seleção dos arquivos
	,;         // Compatibilidade
	cDirIni,;  // Diretório inicial da busca de arquivos
	lSalvar,;  // Se for .T., será uma Save Dialog, senão será Open Dialog
	;          // Se não passar parâmetro, irá pegar apenas 1 arquivo; Se for informado GETF_MULTISELECT será possível pegar mais de 1 arquivo; Se for informado GETF_RETDIRECTORY será possível selecionar o diretório
	)

	If ! Empty(cArqSel)
		MsgInfo("O arquivo selecionado foi: " + cArqSel, "Atenção")
		Return cArqSel
	EndIf
return
