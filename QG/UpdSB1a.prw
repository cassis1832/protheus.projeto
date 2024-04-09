#Include "PROTHEUS.CH"
#Include "tbiconn.ch"

/*
    SQL para alteração do SB1
*/

User Function zExecQry()

	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase

	Private cQueryUpd 		:= ""
	cQryUpd := " UPDATE " + RetSqlName("SB1") + " "
	cQryUpd += "    SET B1_MRP = 'N' "
	cQryUpd += "  WHERE D_E_L_E_T_ = ' ' "
	cQryUpd += "    AND (B1_PROD LIKE '5%' or B1_PROD LIKE '6%' or B1_PROD LIKE '7%' or B1_PROD LIKE '8%' or B1_PROD LIKE '9%')"

	FWAlertInfo(cQryUpd, "Comando")

	nErro := TcSqlExec(cQryUpd)

	//Se houve erro, mostra a mensagem e cancela a transação
	If nErro != 0
		MsgStop("Erro na execução da query: "+TcSqlError(), "Atenção")
		DisarmTransaction()
	EndIf

	RESET ENVIRONMENT
Return
