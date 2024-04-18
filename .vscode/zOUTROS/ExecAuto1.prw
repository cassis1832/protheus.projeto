#INCLUDE "Protheus.ch"
#Include "TBIConn.ch"

User Function ImpItm()
    Local aDados    := {}
    Local lMsErroAuto
    
	//
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
    lPar01 := SuperGetMV("MV_PARAM",.F.)
    cPar02 := cFilAnt
    dPar03 := dDataBase
	//

    AADD( aDados, {"B1_COD", "111111", NIL })
    AADD( aDados, {"B1_DESC", "DESCR 1", NIL })
    AADD( aDados, {"B1_TIPO", "PA", NIL })
    AADD( aDados, {"B1_UM", "PC", NIL })
    AADD( aDados, {"B1_LOCPAD", "01", NIL })

    lMsErroAuto := .F.

    MSExecAuto({|x,y| mata010(x,y), aDados, 3})

    if lMsErroAuto
        MostraErro("\SYSTEM\LOG\", FUNNAME() + ".LOG" )
        MSGINFO( "NAO FUNCIONOU", "ERRO" )
        DisarmTransaction()
    endif

RETURN
