#INCLUDE "Protheus.ch"
#Include "TBIConn.ch"

User Function ImpOpr2()
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

  AADD( aDados, {"G2_CODIGO"    , "01"  , NIL     }) 
    AADD( aDados, {"G2_PRODUTO"    , "3200" , NIL }     ) 
    AADD( aDados, {"G2_OPERAC"   , "777"   , NIL  } ) 
    AADD( aDados, {"G2_RECURSO"   , "PG4003" , NIL  }   ) 
    AADD( aDados, {"G2_DESCRI"     , "PEGAR A PECA" , NIL   }    ) 
    AADD( aDados, {"G2_MAOOBRA" , "1"   , NIL }) 
    AADD( aDados, {"G2_SETUP" , "1"  , NIL  }) 
    AADD( aDados, {"G2_LOTEPAD" , "1" , NIL  } ) 
    AADD( aDados, {"G2_TEMPAD" , "1" , NIL   }) 
    AADD( aDados, {"G2_TPOPER" , "1" , NIL   }) 
    AADD( aDados, {"G2_CTRAB" , "EG2002" , NIL }  ) 
    AADD( aDados, {"G2_LOTEPAD" , "1" , NIL   }) 
    AADD( aDados, {"G2_LOTEPAD" , "1" , NIL  } ) 
    AADD( aDados, {"G2_LOTEPAD" , "1" , NIL  } ) 
    lMsErroAuto := .F.

    MSExecAuto({|x,y| pcpa124(x,y), aDados, 3})

    if lMsErroAuto
        Alert("ERROOOOOOOOOOOOO")
        MostraErro("\SYSTEM\LOG\", FUNNAME() + ".LOG" )
        MSGINFO( "NAO FUNCIONOU", "ERRO" )
        DisarmTransaction()
    endif

    Alert("22222222222222222")
RETURN
