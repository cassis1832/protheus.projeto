#INCLUDE "PROTHEUS.CH"

// Ponto de entrada para o MRP
// Esse ponto de entrada é antes de iniciar o processamento
// Vamos tentar usar para fazer manutenção das tabelas de Demanda com os registro EDI

User Function P712EXEC()
	Local cEmpBusca := "98"
	Local cFilBusca := "01"
	Local cLocal    := ""
	Local cProd     := ""
	Local nTamPrd   := GetSx3Cache("B2_COD", "X3_TAMANHO")
	Local nTamLoc   := GetSx3Cache("B2_LOCAL", "X3_TAMANHO")
	Local cTicket   := PARAMIXB

	//Parâmetros de execução do MRP podem ser obtidos na tabela HW1
	HW1->(dbSeek(xFilial("HW1") + cTicket))

	// Abre a tabela da outra empresa para buscar os dados
	NGPrepTBL({{"SB2",1}}, cEmpBusca, cFilBusca)

	DbSelectArea("T4V")
	T4V->(DbGoTop())
	While T4V->(!EoF())
		cProd  := PadR(T4V->T4V_PROD , nTamPrd)
		cLocal := PadR(T4V->T4V_LOCAL, nTamLoc)

		If SB2->(DbSeek(xFilial('SB2') + cProd + cLocal))
			If RecLock('T4V',.F.)
				T4V->T4V_QTD += SB2->B2_QATU //soma o saldo de outra filial no saldo atual do MRP.
				T4V->(MsUnlock())
			EndIf
		EndIf
		T4V->(DbSkip())
	End
