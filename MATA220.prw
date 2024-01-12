#INCLUDE "PROTHEUS.CH"
#INCLUDE "TbIconn.ch"
#INCLUDE "TopConn.ch" 
#INCLUDE "TbIconn.ch"

User Function MyMata220()

    Local PARAMIXB1 := {}
    Local PARAMIXB2 := 3
    Local cProd := "04"
    Local cArmazem := "01"
    Local cQtdIni := 30
    PRIVATE lMsErroAuto := .F.

    //------------------------//| Abertura do ambiente |//------------------------
    RpcSetEnv( "99","01", "Administrador", "", "EST")
    ConOut(Repl("-",80))
    ConOut(PadC("Teste de Cadastro de Saldos Iniciais",80))
    ConOut("Inicio: "+Time())

    //------------------------//| Teste de Inclusao |//------------------------

    PARAMIXB1 := {}
    aadd(PARAMIXB1,{"B9_COD",cProd,})
    aadd(PARAMIXB1,{"B9_LOCAL",cArmazem,})
    aadd(PARAMIXB1,{"B9_QINI",cQtdIni,})

    MSExecAuto({|x,y| mata220(x,y)},PARAMIXB1,PARAMIXB2)

    If !lMsErroAuto
        ConOut("Incluido com sucesso! "+cProd)
    Else
        ConOut("Erro na inclusao!")
    EndIf

    ConOut("Fim : "+Time())

Return Nil
