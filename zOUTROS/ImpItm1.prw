#Include "Protheus.ch"
#Include "TBIConn.ch"

User Function ImpItm1()
	//
	Local lPar01 := ""
	Local cPar02 := ""
	Local dPar03 := CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase
	//

	//Pegando o modelo de dados, setando a operação de inclusão
	oModel  := FWLoadModel("MATA010")
	oModel  :SetOperation(3)
	oModel  :Activate()

	//Pegando o model e setando os campos
	oSB1Mod := oModel:GetModel("SB1MASTER")
	oSB1Mod:SetValue("B1_COD", "3200")
	oSB1Mod:SetValue("B1_DESC", "Teste de importacao de produto")
	oSB1Mod:SetValue("B1_TIPO", "PA")
	oSB1Mod:SetValue("B1_UM", "PC")
	oSB1Mod:SetValue("B1_LOCPAD", "01")
	oSB1Mod:SetValue("B1_POSIPI", "97030000")
	oSB1Mod:SetValue("B1_ORIGEM", "0")
	oSB1Mod:SetValue("B1_RASTRO", "L")
	oSB1Mod:SetValue("B1_XCLIENT", "L")
	oSB1Mod:SetValue("B1_XPROJ", "L")
	oSB1Mod:SetValue("B1_XITEM", "L")

	//Setando o complemento do produto
	oSB5Mod := oModel:GetModel("SB5DETAIL")
	If oSB5Mod != Nil
		oSB5Mod:SetValue("B5_CEME", "Teste de importacao de produto")
	EndIf

	//Se conseguir validar as informações
	If oModel:VldData()

		//Tenta realizar o Commit
		If oModel:CommitData()
			lOk := .T.

			//Se não deu certo, altera a variável para false
		Else
			lOk := .F.
		EndIf

		//Se não conseguir validar as informações, altera a variável para false
	Else
		lOk := .F.
	EndIf

	//Se não deu certo a inclusão, mostra a mensagem de erro
	If ! lOk
		//Busca o Erro do Modelo de Dados
		aErro := oModel:GetErrorMessage()

		//Monta o Texto que será mostrado na tela
		cMessage := "Id do formulário de origem:"  + ' [' + cValToChar(aErro[01]) + '], '
		cMessage += "Id do campo de origem: "      + ' [' + cValToChar(aErro[02]) + '], '
		cMessage += "Id do formulário de erro: "   + ' [' + cValToChar(aErro[03]) + '], '
		cMessage += "Id do campo de erro: "        + ' [' + cValToChar(aErro[04]) + '], '
		cMessage += "Id do erro: "                 + ' [' + cValToChar(aErro[05]) + '], '
		cMessage += "Mensagem do erro: "           + ' [' + cValToChar(aErro[06]) + '], '
		cMessage += "Mensagem da solução: "        + ' [' + cValToChar(aErro[07]) + '], '
		cMessage += "Valor atribuído: "            + ' [' + cValToChar(aErro[08]) + '], '
		cMessage += "Valor anterior: "             + ' [' + cValToChar(aErro[09]) + ']'

		//Mostra mensagem de erro
		lRet := .F.
		ConOut("Erro: " + cMessage)
	Else
		lRet := .T.
		ConOut("Produto incluido!")
		alert("FIM")
	EndIf

	//Desativa o modelo de dados
	oModel:DeActivate()

RETURN
