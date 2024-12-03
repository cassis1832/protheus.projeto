#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL200
Função: Geração de pedido de venda 
		Com base no pedido EDI 	- PL180
		Com base no estoque 	- PL210
@author Assis
@since 08/09/2024	
@version 1.0
	@return Nil, Fução não tem retorno
/*/

User Function PL200old()
	Local aPergs        := {}
	Local aResps	    := {}
	Local lRet 			:= .T.

	Local cCliente    	:= ''
	Local cLoja       	:= ''
	Local dLimite     	:= Date()

	AAdd(aPergs, {1, "Informe o cliente ", CriaVar("ZA0_CLIENT",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a loja "   , CriaVar("ZA0_LOJA",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite ", CriaVar("ZA0_DTENTR",.F.),,,"ZA0",, 50, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cCliente := aResps[1]
		cLoja    := aResps[2]
		dLimite  := aResps[3]
	Else
		lRet := .F.
		return lRet
	endif

	if dLimite > DaySum(date(),3)
		FWAlertError("EM PERIODO DE HOMOLOGACAO NAO GERAR PEDIDOS PARA MAIS DE 3 DIAS")
		lRet := .f.
	endif

	SA1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA1->(dbSetOrder(1))

	// Verificar o cliente
	if SA1->(! MsSeek(xFilial("SA1") + cCliente + cLoja))
		lRet := .F.
		FWAlertError("Cliente nao cadastrado: " + cCliente,"Cadastro de Clientes")
	else
		// Verificar condição de pagamento do cliente
		If SE4->(! MsSeek(xFilial("SE4") + SA1->A1_COND))
			lRet := .F.
			FWAlertError("Cliente sem condicao de pagamento cadastrada: " + cCliente,"Condicao de Pagamento")
		EndIf

		// Verificar a tabela de precos do cliente
		If SA1->A1_TABELA == ""
			lRet := .F.
			FWAlertError("Tabela de precos do cliente nao encontrada!", "Tabela de precos")
		EndIf
	EndIf

	if lRet == .F.
		return
	endif

	if cCliente == '000004' .or. cCliente == '000005' .or. cCliente == '000006' .or. cCliente == '000007'
		u_PL210(cCliente, cLoja, dLimite)
	else
		u_PL180(cCliente, cLoja, dLimite)
	endif
return
