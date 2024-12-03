#Include "RwMake.CH"
#include "tbiconn.ch"

//
// Cria SB5 para itens produtivos
//
User Function TMata180()
	Local aCab          := {}

	Private lMsErroAuto := .F.

	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "EST"

	SB1->(DBSetOrder(1))
	SB1->(DbGoTop())

	While !SB1->(EoF())

		if len(AllTrim(SB1->B1_COD)) == 8 .AND. ;
				(substring(SB1->B1_COD,1,1) == '1' .or. substring(SB1->B1_COD,1,1) == '2' .or. substring(SB1->B1_COD,1,1) == '3' .or. substring(SB1->B1_COD,1,1) == '4')

			SB5->(DBSetOrder(1))
			If ! SB5->(MsSeek(xFilial("SB5") + SB1->B1_COD))

				aCab:= {                                ;
					{"B5_COD"   ,SB1->B1_COD    ,Nil},  ;
					{"B5_CEME"  ,SB1->B1_DESC   ,Nil}   ;
					}

				MSExecAuto({|x,y| Mata180(x,y)},aCab,3)     //Inclusão

				//-- Retorno de erro na execução da rotina
				If lMsErroAuto
					conout("erro ao incluir o produto")
					cErro:=MostraErro()
				Else
					conout("Incluído com sucesso")
				Endif

			endif
		endif

		SB1->(DbSkip())
	EndDo

	RESET ENVIRONMENT
Return
