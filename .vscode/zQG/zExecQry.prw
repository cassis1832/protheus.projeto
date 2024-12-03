#Include "TOTVS.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} User Function zExecQry
Função que executa uma query e já exibe um log em tela em caso de falha
@type  Function
@author Atilio
@since 27/01/2023
@param cQuery, Caractere, Query SQL que será executada no banco
@param lFinal, Lógico, Define se irá encerrar o sistema em caso de falha
@return lDeuCerto, Lógico, .T. se a query foi executada com sucesso ou .F. se não
@example
    u_zExecQry("UPDATE TABELA SET CAMPO = 'AAAA'")

	https://terminaldeinformacao.com/2021/04/21/como-fazer-um-update-via-advpl/
/*/

User Function zExecQry(cQuery, lFinal)
	Local aArea     := FWGetArea()
	Local lDeuCerto := .F.
	Local cMensagem := ""
	Default cQuery  := "UPDATE SB1010 set B1_MRP = 'N' where (B1_PROD LIKE '5%' or B1_PROD LIKE '6%' or B1_PROD LIKE '7%' or B1_PROD LIKE '8%' or B1_PROD LIKE '9%')"
	Default lFinal  := .F.

	cMensagem += cQuery + CRLF + CRLF
	ShowLog(cMensagem)

	//Executa a clausula SQL
	If TCSqlExec(cQuery) < 0

		//Caso não esteja rodando via job / ws, monta a mensagem e exibe
		If ! IsBlind()
			cMensagem := "Falha na atualização do Banco de Dados!" + CRLF + CRLF
			cMensagem += "/* ==== Query: ===== */" + CRLF
			cMensagem += cQuery + CRLF + CRLF
			cMensagem += "/* ==== Mensagem: ===== */" + CRLF
			cMensagem += TCSQLError()
			ShowLog(cMensagem)
		EndIf

		//Se for para abortar o sistema, será exibido uma mensagem
		If lFinal
			Final("zExecQry: Falha na operação. Contate o Administrador.")
		EndIf

		//Se deu tudo certo, altera a flag de retorno
	Else
		lDeuCerto := .T.
	EndIf

	FWRestArea(aArea)
Return lDeuCerto
