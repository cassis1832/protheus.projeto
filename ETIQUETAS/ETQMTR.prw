#include "totvs.ch"
#Include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTR
Impressão Etiqueta Cliente GKTB
@author  Vinicius Pereira
@since   06/11/2023
@version 1.0
/*/
//-------------------------------------------------------------------
User Function ETQMTR()
	Local oGet1
	Local cGet1 := space(20)
//	Local oRadMenu1
//	Local nRadMenu1 := 1
//	Local oRadMenu2
//	Local nRadMenu2 := 2
	Local oSay1
	Local oSButton1
	Local oSButton2
	Local oSButton3
	Private oWBrowse1
	Private aWBrowse1 := {}
	Private oOk := LoadBitmap( GetResources(), "LBOK")
	Private oNo := LoadBitmap( GetResources(), "LBNO")
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Emissão de Etiqueta" FROM 000, 000  TO 450, 800 COLORS 0, 16777215 PIXEL

	fWBrowse1()
	//DEFINE SBUTTON oSButton1 FROM 008, 307 TYPE 06 OF oDlg ENABLE ACTION ETQMTRB(nRadMenu1,aWBrowse1)
	//DEFINE SBUTTON oSButton2 FROM 027, 307 TYPE 17 OF oDlg ENABLE ACTION ETQMTRA(nRadMenu1,nRadMenu2,cGet1)
    DEFINE SBUTTON oSButton1 FROM 008, 307 TYPE 06 OF oDlg ENABLE ACTION ETQMTRB(aWBrowse1)
	DEFINE SBUTTON oSButton2 FROM 027, 307 TYPE 17 OF oDlg ENABLE ACTION ETQMTRA(cGet1)
	DEFINE SBUTTON oSButton3 FROM 046, 307 TYPE 02 OF oDlg ENABLE ACTION oDlg:end()
    //@ 016, 005 RADIO oRadMenu1 VAR nRadMenu1 ITEMS "Vendas","Compras" SIZE 092, 018 OF oDlg COLOR 0, 16777215 PIXEL
	//@ 040, 005 RADIO oRadMenu2 VAR nRadMenu2 ITEMS "Pedido","Nota","Lote" SIZE 092, 026 OF oDlg COLOR 0, 16777215 PIXEL
	@ 031, 111 SAY oSay1 PROMPT "DIGITE NUMERO DA NOTA / SERIE " SIZE 137, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 041, 112 MSGET oGet1 VAR cGet1 SIZE 111, 010 OF oDlg COLORS 0, 16777215 PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//------------------------------------------------
Static Function fWBrowse1()
	// Insert items here
	Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," ",0," ",stod(" ")," "," "," "," "," "})

	@ 068, 005 LISTBOX oWBrowse1 Fields HEADER " ","Qtd Impre","Pedido","Nota Fiscal","Serie","Cliente","Nome","Produto","Descrição","Quantidade","Lote","Emissão","Espécie","Peso Liq.","Cod. Prod. Cliente","Descr. Prod. Cliente","End. Cliente" SIZE 390, 152 OF oDlg PIXEL ColSizes 50,50
	oWBrowse1:SetArray(aWBrowse1)
	oWBrowse1:bLine := {|| {;
		If(aWBrowse1[oWBrowse1:nAT,1],oOk,oNo),;
			aWBrowse1[oWBrowse1:nAt,2],;
			aWBrowse1[oWBrowse1:nAt,3],;
			aWBrowse1[oWBrowse1:nAt,4],;
			aWBrowse1[oWBrowse1:nAt,5],;
			aWBrowse1[oWBrowse1:nAt,6],;
			aWBrowse1[oWBrowse1:nAt,7],;
			aWBrowse1[oWBrowse1:nAt,8],;
			aWBrowse1[oWBrowse1:nAt,9],;
			aWBrowse1[oWBrowse1:nAt,10],;
			aWBrowse1[oWBrowse1:nAt,11],;
			aWBrowse1[oWBrowse1:nAt,12],;
			aWBrowse1[oWBrowse1:nAt,13],;
			aWBrowse1[oWBrowse1:nAt,14],;
			aWBrowse1[oWBrowse1:nAt,15],;
			aWBrowse1[oWBrowse1:nAt,16],;
			aWBrowse1[oWBrowse1:nAt,17]}}
		// DoubleClick event
		oWBrowse1:bLDblClick := {|| ETQMTRE(), oWBrowse1:DrawSelect()}
		//oWBrowse1:bHeaderClick := {|o,x| markAll(oWBrowse1)}

		Return
//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTRA
ROTINA PARA PESQUISAR OS DADOS DA NOTA
@author  Vinicius Pereira
@since   0703/2022
@version 1.0
/*/
//-------------------------------------------------------------------
STATIC FUNCTION ETQMTRA(cPesq)
	Local cTrb      := "TRBXDF"
	Local cSerie    := ""
	Local cNota     := ""

	IF EMPTY(cPesq)
		aWBrowse1 := {}
		Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," ",0," ",stod(" ")," "," "," "," "})
	else
		aWBrowse1 := {}

		IIF(SELECT(cTrb)>0,(cTrb)->(DBCLOSEAREA()),NIL)

		if at('/',cPesq)>0
			cNota   := padr(substr(cPesq,1,at('/',cPesq)-1),tamsx3("D2_DOC")[1])
			cSerie  := padr(substr(cPesq,at('/',cPesq)+1),tamsx3("D2_SERIE")[1])
		else
			cNota   := padr(cPesq,tamsx3("D2_DOC")[1])
		endif

		BEGINSQL ALIAS cTrb
        SELECT * FROM %TABLE:SF2% A
	    	INNER JOIN %TABLE:SD2% B ON A.F2_DOC = B.D2_DOC
				AND A.F2_SERIE = B.D2_SERIE
				AND A.F2_FILIAL = %EXP:FWXFILIAL("SF2")%
				AND B.D2_FILIAL = %EXP:FWXFILIAL("SD2")%
				AND A.%NOTDEL%
				AND B.%NOTDEL%
			INNER JOIN %TABLE:SB1% C ON C.B1_FILIAL = %EXP:FWXFILIAL("SB1")%
				AND C.%NOTDEL%
				AND B.D2_COD = C.B1_COD
			INNER JOIN %TABLE:SA1% D ON D.A1_FILIAL = %EXP:FWXFILIAL("SA1")%
				AND D.%NOTDEL%
				AND A.F2_CLIENTE = D.A1_COD
				AND A.F2_LOJA = D.A1_LOJA
			INNER JOIN %TABLE:SA7% E ON E.%NOTDEL%
    			AND B.D2_CLIENTE = E.A7_CLIENTE
				AND B.D2_LOJA = E.A7_LOJA
				AND B.D2_COD =  E.A7_PRODUTO
			WHERE
				A.F2_DOC = %EXP:cNota%
				AND A.F2_SERIE = %EXP:cSerie%
		ENDSQL

		DBSELECTAREA(cTrb)
		if  (cTrb)->(EOF())
			Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," ",0," ",stod(" ")," "," "," "," "," "})
			MsgInfo("NF não encontrada!")
		else
			WHILE (cTrb)->(!EOF())
				(cTrb)->(AADD(aWBrowse1,{.F.,1,D2_PEDIDO,D2_DOC,D2_SERIE,A1_COD, A1_NOME, B1_COD, B1_DESC, D2_QUANT, D2_LOTECTL, stod(D2_EMISSAO),F2_ESPECI1,F2_PLIQUI,A7_CODCLI,A7_DESCCLI,B1_XENDCLI}))
				(cTrb)->(DBSKIP())
			END
		endif
	ENDIF
	oWBrowse1:SetArray(aWBrowse1)
	oWBrowse1:bLine := {|| {;
		If(aWBrowse1[oWBrowse1:nAT,1],oOk,oNo),;
			aWBrowse1[oWBrowse1:nAt,2],;
			aWBrowse1[oWBrowse1:nAt,3],;
			aWBrowse1[oWBrowse1:nAt,4],;
			aWBrowse1[oWBrowse1:nAt,5],;
			aWBrowse1[oWBrowse1:nAt,6],;
			aWBrowse1[oWBrowse1:nAt,7],;
			aWBrowse1[oWBrowse1:nAt,8],;
			aWBrowse1[oWBrowse1:nAt,9],;
			aWBrowse1[oWBrowse1:nAt,10],;
			aWBrowse1[oWBrowse1:nAt,11],;
			aWBrowse1[oWBrowse1:nAt,12],;
			aWBrowse1[oWBrowse1:nAt,13],;
			aWBrowse1[oWBrowse1:nAt,14],;
			aWBrowse1[oWBrowse1:nAt,15],;
			aWBrowse1[oWBrowse1:nAt,16],;
			aWBrowse1[oWBrowse1:nAt,17]}}
		// DoubleClick event
		oWBrowse1:bLDblClick := {|| ETQMTRE(), oWBrowse1:DrawSelect()}
		oWBrowse1:bHeaderClick := {|o,x| markAll(oWBrowse1) }
		oWBrowse1:refresh()
		RETURN
//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTRB
Rotina para filtrar as etiquetas
@author  Vinicius Pereira
@since   06/11/2023
@version 1.0
/*/
//-------------------------------------------------------------------
STATIC FUNCTION ETQMTRB(aDados)
	IF LEN(aDados) > 0
    	Processa({|| ETQMTRC(aDados) },"Aguarde","Emitindo a Etiquetas",.F.)
	ELSE
		Aviso("Atenção","Não a Dados para ser impresso!",{"Ok"})
	endif
Return
//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTRC
impressão de vendas
@author  Vinicius Pereira
@since   06/11/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ETQMTRC(aDados)
    u_etqimpr(aDados)
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTRE
ROTINA PARA EDIÇÃO DO GET
@author  Vinicius Pereira
@since   06/11/2023
@version 1.0
/*/
//-------------------------------------------------------------------
STATIC FUNCTION ETQMTRE()
	Local oGet1
	Local nGet1 := oWBrowse1:AARRAY[oWBrowse1:NAT][10]
	Local nGet2 := oWBrowse1:AARRAY[oWBrowse1:NAT][2]
	Local oSButton1
	Local oSButton2
	Static oDlq


	if oWBrowse1:colpos == 10
		oWBrowse1:acolbmps[10] := .T.
		oWBrowse1:lmodified := .t.
		DEFINE MSDIALOG oDlq TITLE "Quantidade" FROM 000, 000  TO 075, 200 COLORS 0, 16777215 PIXEL

		DEFINE SBUTTON oSButton1 FROM 024, 009 TYPE 01 OF oDlq ENABLE action (ETQMTRF(nGet1,oWBrowse1:colpos),oDlq:END())
		DEFINE SBUTTON oSButton2 FROM 024, 063 TYPE 02 OF oDlq ENABLE action oDlq:END()
		@ 007, 020 MSGET oGet1 VAR nGet1 SIZE 060, 010 OF oDlq PICTURE "@E 9999999999"  COLORS 0, 16777215 PIXEL

		ACTIVATE MSDIALOG oDlq CENTERED
		oWBrowse1:AARRAY[oWBrowse1:NAT][1] := (nGet2>0)
	ELSEIF oWBrowse1:colpos == 2
		oWBrowse1:acolbmps[2] := .T.
		oWBrowse1:lmodified := .t.
		DEFINE MSDIALOG oDlq TITLE "Quantidade" FROM 000, 000  TO 075, 200 COLORS 0, 16777215 PIXEL

		DEFINE SBUTTON oSButton1 FROM 024, 009 TYPE 01 OF oDlq ENABLE action (ETQMTRF(nGet2,oWBrowse1:colpos),oDlq:END())
		DEFINE SBUTTON oSButton2 FROM 024, 063 TYPE 02 OF oDlq ENABLE action oDlq:END()
		@ 007, 020 MSGET oGet1 VAR nGet2 SIZE 060, 010 OF oDlq PICTURE "@E 9999999999"  COLORS 0, 16777215 PIXEL

		ACTIVATE MSDIALOG oDlq CENTERED
		oWBrowse1:AARRAY[oWBrowse1:NAT][1] := (nGet2>0)
	else
		//oWBrowse1:AARRAY[oWBrowse1:NAT][1] := !oWBrowse1:AARRAY[oWBrowse1:NAT][1]
	endif

RETURN()
//-------------------------------------------------------------------
/*/{Protheus.doc} ETQMTRF
rotina para gravar o array
@author  Vinicius Pereira
@since   08/03/2022
@version 1.0
/*/
//-------------------------------------------------------------------
static function ETQMTRF(nGet1,npos)
	oWBrowse1:AARRAY[oWBrowse1:NAT][npos] := nGet1
return
//-------------------------------------------------------------------
/*/{Protheus.doc} CriaSx1
criação da estrutura de pergunte
@author  Vinicius Pereira
@since   08/03/2022
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function CriaSx1(cPerg)
	Local j  := 0
	Local nY := 0
	Local aAreaAnt := GetArea()
	Local aAreaSX1 := SX1->(GetArea())
	Local aReg := {}

	aAdd(aReg,{cPerg,"01","Porta de impressão"  ,"mv_ch1","C",45,0,0,"G","","mv_par01","","LPT1","","","","","","","","","","","","",""})
	aAdd(aReg,{"X1_GRUPO","X1_ORDEM","X1_PERGUNT","X1_VARIAVL","X1_TIPO","X1_TAMANHO","X1_DECIMAL","X1_PRESEL","X1_GSC","X1_VALID","X1_VAR01","X1_DEF01","X1_CNT01","X1_VAR02","X1_DEF02","X1_CNT02","X1_VAR03","X1_DEF03","X1_CNT03","X1_VAR04","X1_DEF04","X1_CNT04","X1_VAR05","X1_DEF05","X1_CNT05","X1_F3"})


	dbSelectArea("SX1")
	dbSetOrder(1)

	For ny:=1 to Len(aReg)-1
		If !dbSeek(aReg[ny,1]+aReg[ny,2])
			RecLock("SX1",.T.)
			For j:=1 to Len(aReg[ny])
				FieldPut(FieldPos(aReg[Len(aReg)][j]),aReg[ny,j])
			Next j
			MsUnlock()
		EndIf
	Next ny

	RestArea(aAreaSX1)
	RestArea(aAreaAnt)

Return Nil

/*/{Protheus.doc} EtqCli
rotina de impressão via impressora termica ZEBRA
@author  Vinicius A. Pereira
@since   06/11/2023
@version 1.0
/*/
User Function etqimpr(aDados)
	Local aArea     := GetArea()
	Local cPorta    := "LPT1"
    Local cFila     := "ETQCLI"
	Local ENTER		 := Chr(13)+Chr(10)
    Local nX,nY

	MSCBPRINTER("ZEBRA", cPorta ,,,.F.,,,,40000 , cFila, .F.)
	MSCBCHKSTATUS(.F.)

	For nX:=1 to len(aDados)
		If aDados[nX][1]
			For nY:=1 to aDados[nX][2]
				MSCBINFOETI("VOLUMES","10X10")
				MSCBWrite("CT~~CD,~CC^~CT~" + ENTER)
				MSCBWrite("^XA" + ENTER)
				MSCBWrite("~TA000" + ENTER)
				MSCBWrite("~JSN" + ENTER)
				MSCBWrite("^LT0" + ENTER)
				MSCBWrite("^MNW" + ENTER)
				MSCBWrite("^MTT" + ENTER)
				MSCBWrite("^PON" + ENTER)
				MSCBWrite("^PMN" + ENTER)
				MSCBWrite("^LH0,0" + ENTER)
				MSCBWrite("^JMA" + ENTER)
				MSCBWrite("^PR4,4" + ENTER)
				MSCBWrite("~SD15" + ENTER)
				MSCBWrite("^JUS" + ENTER)
				MSCBWrite("^LRN" + ENTER)
				MSCBWrite("^CI27" + ENTER)
				MSCBWrite("^PA0,1,1,0" + ENTER)
				MSCBWrite("^XZ" + ENTER)
				MSCBWrite("^XA" + ENTER)
				MSCBWrite("^MMT" + ENTER)
				MSCBWrite("^PW799" + ENTER)
				MSCBWrite("^LL799" + ENTER)
				MSCBWrite("^LS0" + ENTER)
				MSCBWrite("^FT50,320^BQN,2,8" + ENTER)
				MSCBWrite("^FH\^FDLA,"+AllTrim(aDados[nX][15])+AllTrim(Str(aDados[nX][2]))+AllTrim(aDados[nX][11])+"^FS" + ENTER)
				MSCBWrite("^FO91,0^GFA,1245,8880,80,:Z64:eJzt2D2O3CAUAGAQBaWP4KNwNIi2SJkj5ChBSpEyV3C0Rcq1lAYpCMJ7/Ji/Gc+sojTxK2Y9GH/eteHxWEKuuOKKK6644oor/vPwFj6lC0feO+YhCGF+I4R6hV1WD9/glMHzCg+JCNdwC+1AUI8/KVyNn9iVo6fI4ncQNHoy3IiEpnABntd4GJpDo8P20A/OOLyrQk/d9bCp87Axeqb2dFTve9vM09lzncd7b4Vb1t4+87bshSsOb3vEM/e97dSzrWdn3l68vfWW3hO95+57pvL2w3MnXhx/Or5SfAjJs+jZ1osvGseziPdKHlwb+sQJwL2Kh8ULT8dBMzQy/yV46+/kkdQuO08c3nJ4Nnm08czMe2u9NSMw+0jvwVRpPNF7/s033jLzwj2TJ7wq3ufwFMWvxz3hRm899b61Hp96PntL58nOo8FTNzxps/ezeNzr4n0KT16+Pu7h1Hvae3nIU8kL6bfxfOex4Om5RzHVoPc69T6G7/7r+zydPNp6dPRo6y1lfjBMrej9uO29tB4P3jb3OGTl7G0TL1Dn3jrztsrbay99YKqJniOtJ8s6tqSlSYO3J4+Al1bV8OSZZ3lRjV7oFuzDoyn/bTi10qHfZOfhGvbh3Cv5Hj1yeGbu8cGzvWeyJ9zhibm3cdd5q4WHNq6XvWcnnoK3dOpt2Qvp4HlPmN7LLwHrp+ytburtix09YWuvIJAOTjy5r9nbb3npoWmcvmX8LX4y/g7vmB9y7zz8e3M6KPOj9dL8UNKsZvRW13h5krFYTkSPQ7IbPGHEiWeWklT4Q97eeeGixuOVpw+PZa/OL0pYOXhYdRweK0l0welTvO8Tbz33jqS81h6de05urUd771iEIB1U3tvEW5yfemrmidoj2WPPemURh3RQeT57uvI8ZMDaY7c9SAeHJ/24nofKY+7puv4rRcvf9szMq+shFYv72uODl9c32nrCj/WaYhMPX9nEg4E98URVn068NKSm3lZ7qx/rXfDImZfrUz71mnpc0dFzmOhSxm49XXuLT/sF23gu/Zpxn6ggt0AKYnGLEj2Nm5il3s9kr+yPbO/52jOVx9MmK27+0n4LNoHjfkuR0bPPelvj2c4TUak8lpDOY9nTD3j2CU/Vnhw8M3r7zMt1V73fV7F/7UnwRO3RuUfyPva9Hu89m+vM5FGYzTv+yDcIFEzSFXbgOJ7hK8yWsp+OA11qLCRY7JT+n3PFFVdcccUVV/z7+AMc8kcH:CEBB" + ENTER)
				MSCBWrite("^FO260,101^GB533,129,6^FS" + ENTER)
				MSCBWrite("^FO260,235^GB533,96,6^FS" + ENTER)
				MSCBWrite("^FO522,101^GB0,129,3^FS" + ENTER)
				MSCBWrite("^FO260,335^GB533,244,6^FS" + ENTER)
				MSCBWrite("^FO522,335^GB0,94,3^FS" + ENTER)
				MSCBWrite("^FO7,686^GB785,99,6^FS" + ENTER)
				MSCBWrite("^FO260,583^GB262,99,6^FS" + ENTER)
				MSCBWrite("^FO526,583^GB266,99,6^FS" + ENTER)
				MSCBWrite("^FO264,428^GB522,0,3^FS" + ENTER)
				MSCBWrite("^FO7,335^GB249,347,6^FS" + ENTER)
				MSCBWrite("^FO14,578^GB241,0,3^FS" + ENTER)
				MSCBWrite("^FO14,428^GB241,0,3^FS" + ENTER)
				MSCBWrite("^FO268,104^GFA,89,192,8,:Z64:eJxjYCANFPAf/v+/AUjLP4bQFkAIErewgNBARgEfhK5Ho+HyYBqmrwCsvl7+gUV9H5DmPwCmiQUABHcdHQ==:EBCF" + ENTER)
				MSCBWrite("^FO530,104^GFA,69,96,4,:Z64:eJxjYMAOCpJ/MFSAcQNDDgQ/SAPjHw+SgeLJQLFEEH7c8ACEE4AYmzkAb6kZdQ==:C78F" + ENTER)
				MSCBWrite("^FO268,237^GFA,137,288,12,:Z64:eJxjYKAO4O/jq58j+f//ASBb/hxf/Two28KPr0BOQsYCpMaCj69AGsougLLZIex6yRky9u2Y7AKJGwj1MHYFiB0BNRNovkQFxBz58+/qZ1TI2B8HuacfyLaAsCkBALY7I+0=:8F9A" + ENTER)
				MSCBWrite("^FO268,338^GFA,249,384,16,:Z64:eJxjYKAtqJ/Pfv6BhQxzg3z/5wc/IPwfNjLMB+rPg/kF8u3nLHJk2A588GP+AOb3Q/gP+Jg/gviyvecs3snwPTzAx7xxxwOGetne8w+OyfAkHuB/DOHfPf/juAxP4fHzj3cD+QUyN8/ZHpeRKTx+jnm2BQOYL/tfRv7jQRj/J5A/R/7Hw3PM88H8wnP2zXMsLD6eY+6zAJo3p/D8b8b5HySA7oPxvzPe/yADdD+IT20AAOpdYiY=:84DA" + ENTER)
				MSCBWrite("^FO530,338^GFA,209,384,16,:Z64:eJy1zjEOwjAMBVBDJLwgZ2UId2DMxlV6hCBm5I5svVJ6AbiCKy7QqEuQIkTSFE4Af/KT9WUD/Desx/EIHCIHL8VdHlueEgcpPt3UdfCIhKpZ3Ipgzte9l7xGdOIAzvdHqN4cirkbnovtbIJLNdnSdwT7ah0/7j0SoU7Va1PvG1P6Tk/5P1QJd9vX7JD/x1VES8W/zhsJvklE:2FB3" + ENTER)
				MSCBWrite("^FO268,429^GFA,253,576,24,:Z64:eJzN0D0KwkAQBeANWywizBxAMYewGUFM6UG8wNhpGS3SeaaELdIlV1jxAoY0K8SfdSUQksJSB6b5isebEeK/BmMbxWmDKRpMgyor62P0tEKEuonO+hEatKGRN+faO62BqvxADEtiNcoKqWXickgp2ueCCGZEKnC+8c6gaFEIJgC3rZuBl5e5TK6tr756ISedfBj4DoC2OTDDlBnfPv709P1Pnf7o+/TuvZe1c2v6/3GuvP9qXoTAcvU=:CD95" + ENTER)
				MSCBWrite("^FO268,589^GFA,261,480,20,:Z64:eJzF0DEKwjAUBuAnDt3MBVp7jWTpkSSjky10yJYLKHiGbhZHh2x6hZSAXaREXFoIiUmJiwfQN37ww/8/gP+cpiZN8ViUlU1G9JKTAaCdjebYbM6bYt5MQUEJWC31JILVB287Cl3v7RkMi6W3x4aCDNa0AiSJVnrTSDWt+dgwRDu3DmQ22/0as3siKsjYl12CJb5L760LXY7BUM3S9Vbx2I8TcZJoYfObVjzu4MRhicDkQgab93JisfzFn99ww3x1:6DDF" + ENTER)
				MSCBWrite("^FO534,589^GFA,209,384,16,:Z64:eJy10LENwkAMBVBTscIhIrJGohQwBmOkTHfXscIVEYvQGFFcSUtpKwMk9NE58UWECeLuSfa3ZYBty7YmAuSu6GVMvhtxYLHsRdT1yXQIw6VEDslHwwQElVtNtMPkTOcPPvkMPP4dcLaoa/NRvx9zv1v9VL8WXxmBscKfmy7AF3V/q3m+kZveR0ue9UXc6/3EMdvgPxM321d+:E194" + ENTER)
				MSCBWrite("^FO405,691^GFA,425,768,32,:Z64:eJyt0T1qwzAYBmCZb9CmFDp0ET2HSgq+Qc/iNEs7yUWDliLnACK5ioIL2Zo1QwcbDd5SFUNxqXEq/wSaoTWUCt5FD5b8fkLov9btiDcjrv90KweZZGFgRRbhDLs2DTi/G1Z152mydVyU0t1NHK59qgOueCrDj+6HZlbfsHxzrs52lOFLH2oVnVkJQrYelZqwrACFdpTiiY93EpXeRdz6fEmuTCF08MIoxqx1TaK5BOm/aX2l7k1hdfA4+HVx6sn2zdhSB2rw6kBPXLzmJvvUcHTXHL2/P94HJptqaAZHxYlb72szXcKBMUx8kNU08v0k7vsv9ih/mqoLPPRHXf+t70+6+a2eEZelfIdhfijfVHzdwEPTOSQKhWDFHmQ/f5SnjqMa4pp8e6cgHnlI8zvDmI+d/8P6ArmWpaM=:760C" + ENTER)
				MSCBWrite("^FO398,691^GB0,87,3^FS" + ENTER)
				MSCBWrite("^FO14,691^GFA,425,768,32,:Z64:eJyt0T1qwzAYBmCZb9CmFDp0ET2HSgq+Qc/iNEs7yUWDliLnACK5ioIL2Zo1QwcbDd5SFUNxqXEq/wSaoTWUCt5FD5b8fkLov9btiDcjrv90KweZZGFgRRbhDLs2DTi/G1Z152mydVyU0t1NHK59qgOueCrDj+6HZlbfsHxzrs52lOFLH2oVnVkJQrYelZqwrACFdpTiiY93EpXeRdz6fEmuTCF08MIoxqx1TaK5BOm/aX2l7k1hdfA4+HVx6sn2zdhSB2rw6kBPXLzmJvvUcHTXHL2/P94HJptqaAZHxYlb72szXcKBMUx8kNU08v0k7vsv9ih/mqoLPPRHXf+t70+6+a2eEZelfIdhfijfVHzdwEPTOSQKhWDFHmQ/f5SnjqMa4pp8e6cgHnlI8zvDmI+d/8P6ArmWpaM=:760C" + ENTER)
				MSCBWrite("^FO18,583^GFA,249,384,16,:Z64:eJy10KEOwjAQBuC6M6S1JFvGK4DrwpK+Cg67KhzLQkIdewEepqMJM4RZZKdmKyuWjOuGwhLOfeL+P3eE/HdYbUpt27G1FJzQZNWZ0jq0ZzCguTSnndPdM4sg4YTwFP1CJxEwdJ4alQfTrQIOwef1I3ijQKjJfHbz8YXfg2UD837lJxezpamGGzouehr6ZH+NTei3fYL5wo7LBbr1ej+IhjB/5LRGd/rg0CT7OnDx23/ezq5lsA==:930F" + ENTER)
				MSCBWrite("^FO18,429^GFA,237,480,20,:Z64:eJxjYBgYwN/4w76BobjZ/v/PPxYG9mAx+cN/7B8wFB8Giv2zMahvAIlZuPNZfACKMbczHrcxeHgALMbOblHBUJwMEjMzePAAJFbAx25hARMzPPC4ASFmzNz+8bwxptg/NDFpoN4/hhsPIJsHEjsHE6vg47MoYCjmBtlhsPHgAZj7Ph4o5geLfXh4uAHqj4dgsZ+HN3yob26A+rfxQDE7WKzAnrmB9kEMBgDwVldf:3E7E" + ENTER)
				MSCBWrite("^FO18,338^GFA,141,192,8,:Z64:eJxjYCAN1DMU1H88AKQPVNR/fMDAUPjgBjtzAgNDwQcoXXiHnb2gAEj3sLMZgOg+djYLIF3cx85nAZQv/sfO/wNIP/7Pzv8HqP85O7uMTAFD/TFmdgkeIM3H3G7BV0C0ewCpgiEU:0ED8" + ENTER)
				MSCBWrite("^FT290,310^A0N,62,70^FH\^FD"+Substr(AllTrim(aDados[nX][7]),1,10)+"^FS" +ENTER) //Nome Cliente
				MSCBWrite("^FT535,200^A0N,70,55^FH\^FD"+AllTrim(aDados[nX][4])+"^FS" +ENTER) //Nota Fiscal
				MSCBWrite("^FT270,200^A0N,70,50^FH\^FD"+AllTrim(aDados[nX][11])+"^FS" +ENTER) //Lote
				MSCBWrite("^FT270,420^A0N,55,48^FH\^FD"+aDados[nX][13]+"^FS" +ENTER) //Especie
				MSCBWrite("^FT25,420^A0N,55,48^FH\^FD"+Substr(DtoS(aDados[nX][12]),7,2)+"/"+Substr(DtoS(aDados[nX][12]),5,2)+"/"+Substr(DtoS(aDados[nX][12]),1,4)+"^FS" +ENTER) //Emissao
				MSCBWrite("^FT535,420^A0N,70,55^FH\^FD"+AllTrim(Str(aDados[nX][14]))+"^FS" +ENTER) //Peso Liquido
				MSCBWrite("^FT18,530^A0N,60,28^FH\^FD"+AllTrim(aDados[nX][8])+"^FS" +ENTER) //Codigo Produto Metal
				MSCBWrite("^FT320,525^A0N,90,55^FH\^FD"+AllTrim(aDados[nX][15])+"^FS" +ENTER) //Cod. Produto Cliente
				MSCBWrite("^FT290,565^A0N,30,30^FH\^FD"+AllTrim(aDados[nX][16])+"^FS" +ENTER) //Descr. Produto Cliente
				MSCBWrite("^FT100,665^A0N,70,50^FH\^FD"+AllTrim(Str(aDados[nX][2]))+"^FS" +ENTER) //Qtd. de Etiquetas
				MSCBWrite("^FT540,665^A0N,70,50^FH\^FD"+AllTrim(aDados[nX][17])+"^FS" +ENTER) //Endereço g-ktb

                // 1  2      3      4        5       6       7         8      9         10        11                12         13        14        15         16       17                  
                //.F.,1,D2_PEDIDO,D2_DOC,D2_SERIE,A1_COD, A1_NOME, B1_COD, B1_DESC, D2_QUANT, D2_LOTECTL, stod(D2_EMISSAO,F2_ESPECI1,F2_PLIQUI,A7_CODCLI,A7_DESCCLI,B1_XENDCLI

				MSCBWrite("^PQ1,0,1,Y" + ENTER)
				MSCBWrite("^XZ" + ENTER)
				MSCBEND()
			Next nY
		EndIf
	Next nX

	MSCBCLOSEPRINTER()

	RestArea( aArea )
Return nil

//-------------------------------------------------------------------
/*/{Protheus.doc} Markall
rotina para marcar ou desmarcar todos
@author  Vinicius Pereira
@since   26/04/2022
@version 1,0
/*/
//-------------------------------------------------------------------
static  Function Markall(oObj)

	Local nI := 0

	For nI := 1 to Len(oObj:aArray)
		oObj:aArray[nI,1] := !oObj:aArray[nI,1]
	Next nI

	oObj:refresh()
Return
