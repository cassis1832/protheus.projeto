#include "totvs.ch"
#Include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL130
	Picking-list de producao
	@author  Carlos Assis
	@since   23/07/2024
	@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL130()
	Local oSay1

	Local oSButton1
	Local oSButton2
	Local oSButton3

	Local dDtIni := Date()
	Local dDtFim := Date()

	Private oWBrowse1
	Private aWBrowse1 := {}

	Private oOk := LoadBitmap( GetResources(), "LBOK")
	Private oNo := LoadBitmap( GetResources(), "LBNO")

	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Picking List de Producao" FROM 000, 000  TO 500, 1000 COLORS 0, 16777215 PIXEL

	MontaBrowse()

	DEFINE SBUTTON oSButton2 FROM 020, 280 TYPE 17 OF oDlg ENABLE ACTION Filtrar(dDtIni, dDtFim)
	DEFINE SBUTTON oSButton1 FROM 020, 310 TYPE 06 OF oDlg ENABLE ACTION Imprimir(aWBrowse1)
	DEFINE SBUTTON oSButton3 FROM 020, 340 TYPE 02 OF oDlg ENABLE ACTION oDlg:end()

	@ 010, 040 SAY oSay1 PROMPT "Informe a data inicial " SIZE 60, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 010, 130 SAY oSay2 PROMPT "Informe a data final "   SIZE 80, 030 OF oDlg COLORS 0, 16777215 PIXEL
	@ 010, 130 SAY oSay2 PROMPT "Informe a data final "   SIZE 80, 030 OF oDlg COLORS 0, 16777215 PIXEL

	@ 020, 040 MSGET dDtIni SIZE 70, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 020, 130 MSGET dDtFim SIZE 70, 010 OF oDlg COLORS 0, 16777215 PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
Return

Static Function MontaBrowse()
	// Insert items here
	Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," "})

	@ 050, 005 LISTBOX oWBrowse1 Fields ;
		HEADER " ","Ordem","Item","Sequencia","Produto","Descricao","Cliente","Dt.Inicio","Dt.Termino","Quantidade" ;
		SIZE 490, 200 OF oDlg PIXEL ColSizes 50,50

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
			aWBrowse1[oWBrowse1:nAt,9]};
			}
		oWBrowse1:bLDblClick := {|| ETQMTRE(), oWBrowse1:DrawSelect()}
		Return


//-------------------------------------------------------------------
//	Botão filtrar
//-------------------------------------------------------------------
STATIC FUNCTION Filtrar(dDtIni, dDtFim)

	Local cTrb      := "TRBXDF"

	aWBrowse1 := {}

	IF EMPTY(dDtIni) .or. EMPTY(dDtFim)
		Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," "," "})
	else
		IIF(SELECT(cTrb)>0,(cTrb)->(DBCLOSEAREA()),NIL)

		BEGINSQL ALIAS cTrb
			SELECT B1_COD, B1_DESC, B1_XCLIENT, C2_NUM, C2_ITEM, C2_SEQUEN, C2_DATPRI, C2_DATPRF, C2_QUANT
				FROM %TABLE:SC2% A
				INNER JOIN %TABLE:SB1% B 
				   ON B.B1_FILIAL = %EXP:FWXFILIAL("SB1")%
				  AND A.C2_PRODUTO = B.B1_COD
				  AND B.D_E_L_E_T_ = ' '
				WHERE A.C2_FILIAL  = %EXP:FWXFILIAL("SC2")%
				  AND A.C2_DATPRI >= %EXP:dDtIni%
				  AND A.C2_DATPRI <= %EXP:dDtFim%
				  AND A.C2_TPOP   <> "P"
				  AND A.D_E_L_E_T_ = ' '
		ENDSQL

		DBSELECTAREA(cTrb)

		if  (cTrb)->(EOF())
			Aadd(aWBrowse1,{.f.,0," "," "," "," "," "," "," "})
			MsgInfo("NENHUMA ORDEM DE PRODUCAO FOI ENCONTRADA!")
		else
			WHILE (cTrb)->(!EOF())
				(cTrb)->(AADD(aWBrowse1,{.F., C2_NUM, C2_ITEM, C2_SEQUEN, B1_COD, B1_DESC, B1_XCLIENT, dtoc(stod(C2_DATPRI)), dtoc(stod(C2_DATPRF)), C2_QUANT}))
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
			aWBrowse1[oWBrowse1:nAt,9]}}

		oWBrowse1:bHeaderClick := {|o,x| markAll(oWBrowse1) }
		oWBrowse1:refresh()
		RETURN


//-------------------------------------------------------------------
//	Botão imprimir
//-------------------------------------------------------------------
STATIC FUNCTION Imprimir(aDados)
	IF LEN(aDados) > 0
		Processa({|| ETQMTRC(aDados) },"Aguarde","Emitindo Picking-list...",.F.)
	ELSE
		Aviso("Atencao - nao existem dados para imprimir!",{"Ok"})
	endif
Return


//-------------------------------------------------------------------
//	Imprimir
//-------------------------------------------------------------------
Static Function ETQMTRC(aDados)
	u_PL130A(aDados)
Return


//-------------------------------------------------------------------
//	Marcar ou desmarcar tudo
//-------------------------------------------------------------------
static  Function Markall(oObj)
	Local nI := 0

	For nI := 1 to Len(oObj:aArray)
		oObj:aArray[nI,1] := !oObj:aArray[nI,1]
	Next nI

	oObj:refresh()
Return


//-------------------------------------------------------------------
//	Double click
//-------------------------------------------------------------------
STATIC FUNCTION ETQMTRE()
	oWBrowse1:AARRAY[oWBrowse1:NAT][1] := !oWBrowse1:AARRAY[oWBrowse1:NAT][1]
RETURN()


static function ETQMTRF(nGet1,npos)
	oWBrowse1:AARRAY[oWBrowse1:NAT][npos] := nGet1
return

