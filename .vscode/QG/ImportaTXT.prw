#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020A
Função 
   Importação do arquivo texto 
/*/

User Function ImportaTxt()
	Local cArquivo 		:= ''
	Local cLin			:= ""
	Local nInd			:= 0

	Private aCab		:= {}

	cArquivo := selArquivo()

	if cArquivo == Nil .Or. cArquivo == ''
		return
	endif

	oFile := FWFileReader():New(cArquivo)

	If (oFile:Open())
		If ! (oFile:EoF())
			While (oFile:HasLine())
				cLin := oFile:GetLine()
				TrataLinha(cLin)
			EndDo
		EndIf
		oFile:Close()
	EndIf

	For nInd := 1 To Len(aCab)

		aCab[nInd][2] := 0
	next

Return

/*---------------------------------------------------------------------*
	Trata todas as linhas que estão na variavel aLinhas
 *---------------------------------------------------------------------*/
Static Function TrataLinha(cLin)
	Local aLinha 		:= {}

  	aLinha   := strTokArr(cLin, ';')

	if aCab[1][1] == ""
		GravaCab(aLinha)
	else
		TrataDados(aLinha)
	endif
return


Static Function GravaCab(aLinha)
	Local nInd			:= 0

	For nInd := 1 To Len(aLinha)
		aCab[nInd][1] := aLinha[nInd]
		aCab[nInd][2] := 0
	next	
return


/*---------------------------------------------------------------------*
	Grava tabela ZA0
 *---------------------------------------------------------------------*/
Static Function TrataDados(aLinha)
	Local nInd			:= 0
	Local nLen			:= 0

	For nInd := 1 To Len(aLinha)
		nLen := Len(aLinha[nInd])	

		if aCab[nInd][2] < nLen
			aCab[nInd][2] := nLen
		endif
	next	

Return

/*---------------------------------------------------------------------*
	Abre box para o usuario selecionar o arquivo que deseja importar
 *---------------------------------------------------------------------*/
Static Function selArquivo()
	Local cDirIni := GetTempPath()
	Local cTipArq := "Arquivos texto (*.csv)"
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


Static Function gravaTxt()
	Local oFile := FWFileWriter():New("c:\temp\script.txt", .T.)
	Local nInd			:= 0

	If oFile:Exists()
 		oFile:Erase()
 	EndIf
 
	If (oFile:Create())
		For nInd := 1 To Len(aCab)
	 		 oFile:Write(aCab[nInd][1] + " varchar(" + aCab[nInd][2] + ")," + CRLF)
		next	
 		 oFile:Close()
 	Endif
return
