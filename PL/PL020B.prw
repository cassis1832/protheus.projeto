#Include "TOTVS.ch"

/*/{Protheus.doc} PL020B
Declara a Classe vinda da FWModelEvent e os métodos que serão utilizados
@see https://tdn.totvs.com/pages/releaseview.action?pageId=269552294
/*/

Class PL020B From FWModelEvent
	Method New() CONSTRUCTOR
	Method BeforeTTS()
	Method InTTS()
	Method AfterTTS()
EndClass

/*/{Protheus.doc} New
Método para "instanciar" um observador
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method New(oModel) CLASS PL020B
Return

/*/{Protheus.doc} BeforeTTS
Método acionado antes de fazer as gravações da transação
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method BeforeTTS(oModel) Class PL020B

	Local aArea  := FWGetArea()
	Local oModel := FWModelActive()
	Local lOk	 := .T.

	if oModel:getOperation() <> 5
		SA1->(dbSetOrder(1))
		DA1->(dbSetOrder(2)) // produto + tabela + item

		cFilSA1 := xFilial("SA1")
		cFilDA1 := xFilial("DA1")

		// Verificar a tabela de preços do cliente
		If SA1->(! MsSeek(cFilSA1 + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA))
			lOk     := .F.
			MessageBox("Cliente não cadastrado!","",0)
		else
			If DA1->(! MsSeek(cFilDA1 + ZA0->ZA0_PRODUT + SA1->A1_TABELA, .T.))
				MessageBox("Tabela de preços não encontrada para o item","",0)
				lOk     := .F.
			EndIf
		EndIf

		if lOk == .T.
			lOk:= oModel:LoadValue("FORMZA0","ZA0_STATUS","0")
		else
			lOk:= oModel:LoadValue("FORMZA0","ZA0_STATUS","1")
		Endif
	EndIf

	FWRestArea(aArea)
Return

/*/{Protheus.doc} InTTS
Método acionado durante as gravações da transação
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method InTTS(oModel) Class PL020B
	//Aqui você pode fazer as durante a gravação (como alterar campos)
Return

/*/{Protheus.doc} AfterTTS
Método acionado após as gravações da transação
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method AfterTTS(oModel) Class PL020B
	//Aqui você pode fazer as operações após gravar

	//Exibe uma mensagem, caso não esteja sendo executado via job ou ws
	// If ! IsBlind()
	// 	ShowLog("Passei pelo Commit de forma nova (FWModelEvent)")
	// EndIf
Return
