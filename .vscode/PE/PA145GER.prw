#INCLUDE "TOTVS.CH"

/*/{Protheus.doc}	PA145GER
	Ponto de entrada para atualizacao das ordens geradas pelo MRP
	26/11/2024 - Atualizar o tipo da ordem para ordens externas
@author Carlos Assis
@since 26/11/2024
@version 1.0   
/*/
User Function PA145GER()
	Local cAliasQry := GetNextAlias()
	Local cOrigem   := "PCPA144"
	Local cTicket   := PARAMIXB[1]

	//
	//SC2 - Ordens de Produção
	//
	BeginSql Alias cAliasQry
      SELECT C2_FILIAL, C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO
        FROM %Table:SC2%
       WHERE C2_SEQMRP = %Exp:cTicket%
         AND C2_BATROT = %Exp:cOrigem%
         AND %notDel%
	EndSql

	SB1->(dbSetOrder(1))
	SC2->(dbSetOrder(1))

	//Percorre todos os registros gerados no processamento
	While (cAliasQry)->(!Eof())
		SB1->(dbSeek(xFilial("SB1") + (cAliasQry)->C2_PRODUTO))

		if SB1->B1_XTPPR == 'E'
			SC2->(dbSeek(xFilial("SC2") + (cAliasQry)->C2_NUM + (cAliasQry)->C2_ITEM + (cAliasQry)->C2_SEQUEN))

			RecLock('SC2', .F.)
			SC2->C2_TPPR = SB1->B1_XTPPR
			SC2->(MsUnlock())
		endif

		(cAliasQry)->(dbSkip())
	End

	(cAliasQry)->(dbCloseArea())
Return
