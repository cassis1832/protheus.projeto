#Include "Protheus.ch"
#Include "TBIConn.ch" 
#Include "Colors.ch"
#Include "RPTDef.ch"
#Include "FwPrintsetup.ch"

/*/{Protheus.doc}RELAT03
Exemplo de relatório gráfico utilizando a classe FwMsPrinter

@author João Leão
@since 17/09/2023
@version 1.0
/*/
User Function Relatorio01()
	Local cFilePrintert		:= "Exemplo" + DToS(Date()) + StrTran(Time(),":","") + ".pdf"
	Local nDevice			:= 6 //1-DISCO, 2-SPOOL, 3-EMAIL, 4-EXCEL, 5-HTML, 6-PDF
	Local lAdjustToLegacy	:= .F.
	Local lDisableSetup		:= .T.
	Local nI				:= 0
	Local nPages			:= 3
	Local nLin				:= 0
	Local nCol				:= 0
	Local oFont9 			:= TFont():New( "Arial",, -9, .T.)
	Local oFont10 			:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 			:= TFont():New( "Arial",, -12, .T.)

	oPrinter := FWMsPrinter():New(cFilePrintert,nDevice,lAdjustToLegacy,,lDisableSetup)
	oPrinter:SetResolution(72)
	oPrinter:SetPortrait() //oPrinter:SetLandscape()
	oPrinter:SetPaperSize(9) //1-Letter, 3-Tabloid, 7-Executive, 8-A3, 9-A4
	oPrinter:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := "c:\temp\" // Se for usado PDF e fora de rotina agendada
	oPrinter:lServer := .F. //.T. Se for usado em rotina agendada
	oPrinter:lViewPDF := .T. //.F. Se for usado em rotina agendada
	For nI := 1 To nPages
		printCabec(oPrinter, @nLin, @nCol)
		While nLin <= 810
			oPrinter:Say(nLin,nCol,"Teste",oFont9,,CLR_HBLUE)
			nLin += 10
			oPrinter:Say(nLin, nCol, "texto para visualização", oFont10,, CLR_HRED)
			nLin += 10
			oPrinter:SayAlign(nLin,nCol,"Texto alinhado",oFont12,450, 50, CLR_HGREEN, 1, 0 )
			nLin += 10
		EndDo

		oPrinter:EndPage()
	Next nPages

	oPrinter:Preview() //Gera e abre o arquivo em PDF
Return

/*/
Inicia a página e imprime o cabeçalho
/*/
Static Function printCabec(oPrinter, nLin, nCol)
	Local oFont14 			:= TFont():New( "Arial",, -14, .T.)
	Local oFont30 			:= TFont():New( "Arial",, -30, .T.)

	oPrinter:StartPage()
	oPrinter:Box(40,15,836,550)
	nLin := 55
	nCol := 50
	oPrinter:SayBitmap( nLin, 20, "C:\temp\JAL.bmp", 100, 100)
	oPrinter:Say(nLin+30,125,"JAL Developer",oFont30)
	nLin += 90
	oPrinter:Say(nLin,125,"Melhor canal do Youtube para aprender sobre Protheus e ADVPL!",oFont14)
	nLin += 20
	oPrinter:Line(nLin, 15, nLin, 550)
	oPrinter:Line(nLin,260,830,260)
	nLin += 10
Return
