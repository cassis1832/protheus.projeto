#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWPrintSetup.ch"

User Function tstimplc()
	//Local cLocal:= GETTEMPPATH()
	Local oPrinter
	Local cPath := "c:\teste\" //local do .rel
	//Local cPath := "l:/home/evandro/tmp/"
	Local nSize
	
	//RpcSetEnv('99','01','','') 

	//oPrinter := FWMSPrinter():New('teste.pdf',IMP_SPOOL,.F.,cPath,.F.,,,"PDFCreator",.T.,.F.,,.F.)
	oPrinter := FWMSPrinter():New('teste.pdf',IMP_PDF,.F.,cPath,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	//oPrinter:setDevice(IMP_PDF)
	oPrinter:cPathPDF := cPath //diretorio na rede do pdf
	//oPrinter:SetPortrait() //retrato
	//oPrinter:SetLandscape() //paisagem 
	oPrinter:SetPaperSize(0, 300, 400) //Tamanho da folha
	//oPrinter:Setup()

	cTxt := "Lorem ipsum dolor sit amet. Qui laudantium obcaecati a dolores fugit quo dolor iure aut blanditiis facere."
	cTxt2 :="Rem odio nulla et perspiciatis explicabo et nisi facere cum dolor repudiandae nam incidunt dolorem et galisum distinctio qui soluta incidunt."

	nSize := oPrinter:GetTextWidth(cTxt, oFont1,2)

	oPrinter:SayAlign( 02/*linha*/,10/*coluna*/,cTxt/*texto*/,oFont1/*fonte*/,550/*Largura*/,;
		200/*Altura*/, CLR_HRED/*Cor*/, 3/*AlinhamentoH*/, 2/*AlinhamentoV*/ )

	oPrinter:SayAlign( 80/*linha*/,10/*coluna*/,cTxt2/*texto*/,oFont1/*fonte*/,550/*Largura*/,;
		200/*Altura*/, CLR_HRED/*Cor*/, 3/*AlinhamentoH*/, 2/*AlinhamentoV*/ )
	oPrinter:Line( 960, 10, 960, 900, ,"-2")

	//oPrinter:QRCode(150,150,"QR Code gerado com sucesso", 100)
	//oPrinter:SayBitmap( 70 , 10 , "\system\tela8.jpg" , 550 , 200 )
	//oPrinter:SayBitmap( 70 , 10 , "\imp\20046.jpg" , 550 , 200 )
	oPrinter:SayBitmap( 70 , 10 , "\imp\clipng.png" , 550 , 200 )
	//oPrinter:SayBitmap( 70 , 10 , "\imp\clijpg.jpg" , 550 , 200 )


	oPrinter:EndPage()
	oPrinter:Preview()
	FreeObj(oPrinter)
	oPrinter := Nil

	//rpcclearenv()

Return
