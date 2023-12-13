#Include "Protheus.ch"
#Include "TBIConn.ch"

User Function ImpOpr1()
	//
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
    lPar01 := SuperGetMV("MV_PARAM",.F.)
    cPar02 := cFilAnt
    dPar03 := dDataBase
	//

    //Pegando o modelo de dados, setando a operação de inclusão
    oModel  := FWLoadModel("PCPA124")
    oModel  :SetOperation(3)
    oModel  :Activate()
   
    //Pegando o model e setando os campos
    oSB1Mod := oModel:GetModel("SG2MASTER")
    oSB1Mod:SetValue("G2_CODIGO"    , "01"      ) 
    oSB1Mod:SetValue("G2_PRODUTO"    , "3200"      ) 
    oSB1Mod:SetValue("G2_OPERAC"   , "777"     ) 
    oSB1Mod:SetValue("G2_RECURSO"   , "PG4003"     ) 
    oSB1Mod:SetValue("G2_DESCRI"     , "PEGAR A PECA"       ) 
    oSB1Mod:SetValue("G2_MAOOBRA" , "1"   ) 
    oSB1Mod:SetValue("G2_SETUP" , "1"   ) 
    oSB1Mod:SetValue("G2_LOTEPAD" , "1"   ) 
    oSB1Mod:SetValue("G2_TEMPAD" , "1"   ) 
    oSB1Mod:SetValue("G2_TPOPER" , "1"   ) 
    oSB1Mod:SetValue("G2_CTRAB" , "EG2002"   ) 
    oSB1Mod:SetValue("G2_LOTEPAD" , "1"   ) 
     
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
        ConOut("Operacoes incluidas!")
        alert("FIM")
    EndIf
    
    //Desativa o modelo de dados
    oModel:DeActivate()
RETURN
