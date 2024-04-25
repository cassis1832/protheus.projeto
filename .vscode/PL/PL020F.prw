#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL020F
Ponto de entrada para o PL020
Função Manutenção de pedido EDI do cliente - Modelo 2
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL020()
/*/

User Function PL020M()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local lIsGrid    := .F.

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]
		lIsGrid    := ( Len( aParam ) > 3 )

		// Validação ao clicar no Botão Confirmar
		If cIdPonto == 'MODELPOS'
			xRet = Consistencia()
		EndIf
	EndIf

Return xRet

Static Function Consistencia()
	Local lOk	 	:= .T.

	SA1->(dbSetOrder(1))
	SA7->(dbSetOrder(1))
	DA1->(dbSetOrder(2)) // produto + tabela + item

	// Verificar a relacao Item X Cliente
	If SA7->(! MsSeek(xFilial("SA7") + M->ZA0_CLIENT + M->ZA0_LOJA + M->ZA0_PRODUT))
		lOk     := .F.
		FWAlertError("Relação Item X Cliente não cadastrada!", "Cadastro Produto/Cliente")
	else
		M->ZA0_ITCLI   := SA7->A7_CODCLI
		M->ZA0_TES     := SA7->A7_XTES
		M->ZA0_NATUR   := SA7->A7_XNATUR
	EndIf

	// Verificar a tabela de precos do cliente
	If SA1->(! MsSeek(xFilial("SA1") + M->ZA0_CLIENT + M->ZA0_LOJA))
		lOk     := .F.
		FWAlertError("Cliente não cadastrado!", "Cadastro de clientes")
	else
		If DA1->(! MsSeek(xFilial("DA1") + M->ZA0_PRODUT + SA1->A1_TABELA, .T.))
			FWAlertError("Tabela de preços não encontrada para o item!", "Tabela de preços")
			lOk     := .F.
		EndIf
	EndIf

	if lOk == .T.
		M->ZA0_Status  := 0
	else
		M->ZA0_Status  := 1
	EndIf

Return .T.
