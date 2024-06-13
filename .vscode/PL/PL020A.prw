#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL020A
    Ponto de entrada para o PL020
    Consistencia do registro
@author Assis
@since 05/01/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL020()
/*/

User Function PL020PE()

	Local aParam    := PARAMIXB
	Local xRet      := .T.
	Local oObj      := ''
	Local cIdPonto  := ''
	Local cIdModel  := ''
	Local lIsGrid   := .F.
	Local cItem     := AvKey("", "DA1_ITEM")

	If aParam == NIL
		Return xRet
	endif

	oObj       := aParam[1]
	cIdPonto   := aParam[2]
	cIdModel   := aParam[3]
	lIsGrid    := ( Len( aParam ) > 3 )

	// Validação ao clicar no Botão Confirmar
	If cIdPonto != 'MODELPOS'
		Return xRet
	EndIf

	SA1->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SA7->(dbSetOrder(1))    // Filial,Cliente,Loja,Produto
	DA1->(dbSetOrder(2))    // Filial,Produto,Tabela,Item (seq)

	If SA1->(! MsSeek(xFilial("SA1") + M->ZA0_CLIENT + M->ZA0_LOJA))
		FWAlertError("CLIENTE NAO CADASTRADO!", "Cadastro de clientes")
		xRet := .F.
	else
		If SB1->(! MsSeek(xFilial("SB1") + M->ZA0_PRODUT))
			FWAlertError("ITEM NAO CADASTRADO!", "Cadastro de itens")
//			Help("",1,"FT300VLD",,"ITEM NAO CADASTRADO",1)
			xRet := .F.
		else
			// Verificar a relacao Item X Cliente
			If SA7->(! MsSeek(xFilial("SA7") + M->ZA0_CLIENT + M->ZA0_LOJA + M->ZA0_PRODUT))
				FWAlertError("Relaçao Item X Cliente no cadastrada!", "Cadastro Produto/Cliente")
				xRet := .F.
			else
				// Verificar a tabela de precos do cliente
				If DA1->(! MsSeek(xFilial("DA1") + M->ZA0_PRODUT + SA1->A1_TABELA + cItem, .T.))
					if DA1->DA1_CODPRO == M->ZA0_PRODUT .AND. DA1->DA1_CODTAB == SA1->A1_TABELA
					else
						FWAlertError("Tabela de precos nao encontrada para o item!", "Tabela de precos")
						xRet := .F.
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
Return xRet
