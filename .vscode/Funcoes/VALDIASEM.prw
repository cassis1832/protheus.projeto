#include "protheus.ch"
#include "parmtype.ch"

/*/{Protheus.doc} DIASEM
// CONSISTE O CAMPO A7_XDIASEM
@author Carlos Assis
@since 26/07/2024
@version 1.0
@return ${return}, ${return_description}
@param cDiaSem
@type function
/*/

User function VALDIASEM()
	Local cDiaSem	:= M->A7_XDIASEM
	Local aDiaSem	:= {}
	Local lRet		:= .T.
	Local nInd		:= 0

	if AllTrim(cDiaSem) == ""
		aDiaSem := {"2","3","4","5","6"}
	else
		aDiaSem := StrTokArr(AllTrim(cDiaSem), ';')
	endif

	For nInd = 1 to len(aDiaSem) step 1
		if aDiaSem[nInd] != "1" .and. ;
				aDiaSem[nInd] != "2" .and. ;
				aDiaSem[nInd] != "3" .and. ;
				aDiaSem[nInd] != "4" .and. ;
				aDiaSem[nInd] != "5" .and. ;
				aDiaSem[nInd] != "6" .and. ;
				aDiaSem[nInd] != "7" .and. ;
				aDiaSem[nInd] != ""
			lRet := .F.
		endif
	next
Return lRet
