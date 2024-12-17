#include "protheus.ch"
#include "parmtype.ch"

/*/{Protheus.doc} VAL1DIA
// CONSISTE O CAMPO H6_DATAFIN
@author Carlos Assis
@since 17/12/2024
@version 1.0
@return ${return}, ${return_description}
@param cDiaSem
@type function
/*/

User function VAL1DIA()
	Local lRet		:= .T.

	if M->H6_DATAFIN - M->H6_DATAINI > 1
		Help('',1,'ERRO',,'APONTAMENTO TEM MAIS DE 2 DIAS',1,0,,,,,,{""})

		lRet := .F.
	endif

Return lRet
