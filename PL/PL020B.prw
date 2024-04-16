#Include "TOTVS.ch"

/*/{Protheus.doc} PL020B
Declara a Classe vinda da FWModelEvent e os m�todos que ser�o utilizados
@see https://tdn.totvs.com/pages/releaseview.action?pageId=269552294
/*/

Class PL020B From FWModelEvent
	Method New() CONSTRUCTOR
	Method BeforeTTS()
	Method InTTS()
	Method AfterTTS()
EndClass

/*/{Protheus.doc} New
M�todo para "instanciar" um observador
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method New(oModel) CLASS PL020B
Return

/*/{Protheus.doc} BeforeTTS
M�todo acionado antes de fazer as grava��es da transa��o
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

		// Verificar a tabela de pre�os do cliente
		If SA1->(! MsSeek(cFilSA1 + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA))
			lOk     := .F.
			MessageBox("Cliente n�o cadastrado!","",0)
		else
			If DA1->(! MsSeek(cFilDA1 + ZA0->ZA0_PRODUT + SA1->A1_TABELA, .T.))
				MessageBox("Tabela de pre�os n�o encontrada para o item","",0)
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
M�todo acionado durante as grava��es da transa��o
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method InTTS(oModel) Class PL020B
	//Aqui voc� pode fazer as durante a grava��o (como alterar campos)
Return

/*/{Protheus.doc} AfterTTS
M�todo acionado ap�s as grava��es da transa��o
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/

Method AfterTTS(oModel) Class PL020B
	//Aqui voc� pode fazer as opera��es ap�s gravar

	//Exibe uma mensagem, caso n�o esteja sendo executado via job ou ws
	// If ! IsBlind()
	// 	ShowLog("Passei pelo Commit de forma nova (FWModelEvent)")
	// EndIf
Return
