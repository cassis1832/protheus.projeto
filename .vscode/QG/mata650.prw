#INCLUDE 'protheus.ch'
#INCLUDE 'parmtype.ch'
#INCLUDE 'TBICONN.CH'

User Function Tmata650()
	local aArea         := GetArea()
	Local aDados        := {}
	Local cItem         := "01"         // Item
	Local cNum          := "000001"     // Numero da OP
	Local cProduto      := "Produto-01" // Produto
	Local cSeq          := "001"        // Sequencia
	Local dInicio       := Date()       // Previsao inicio
	Local dEmissao      := Date()       // Data de emissao
	Local dEntrega      := Date() + 1   // Previsao entrega
	Local nOpcao        := 3            // Inclusao = 3 // Alteracao = 4 // Exclusao = 5
	Local nQnt          := 1            // Quantidade
	Private lMsErroAuto := .F.

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "PCP"

	//===============================================================//
	//                          INCLUSAO                             //
	//===============================================================//
	If nOpcao == 3
		aDados :=   {{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
			{'C2_SEQUEN'   ,cSeq               ,NIL},;
			{'C2_DATPRI'   ,dInicio            ,NIL},;
			{'C2_DATPRF'   ,dEntrega           ,NIL},;
			{'C2_PRODUTO'  ,cProduto           ,NIL},;
			{'C2_QUANT'    ,nQnt               ,NIL},;
			{'AUTEXPLODE'  ,"S"                ,NIL}}

		//===============================================================//
		//                          ALTERACAO                            //
		//===============================================================//
	elseif nOpcao == 4
		aDados :=   {{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
			{'C2_PRODUTO'  ,cProduto           ,NIL},;
			{'C2_NUM'      ,cNum               ,NIL},;
			{'C2_QUANT'    ,nQnt               ,NIL},;
			{'C2_EMISSAO'  ,dEmissao           ,NIL},;
			{'C2_DATPRI'   ,dInicio            ,NIL},;
			{'C2_DATPRF'   ,dEntrega           ,NIL}}

		//===============================================================//
		//                           EXCLUSAO                            //
		//===============================================================//
	elseif nOpcao == 5
		aDados :=   {{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
			{'C2_ITEM'     ,cItem              ,NIL},;
			{'C2_PRODUTO'  ,cProduto           ,NIL},;
			{'C2_NUM'      ,cNum               ,NIL},;
			{'C2_SEQUEN'   ,cSeq               ,NIL}}
	Endif

	//===============================================================//
	//     Se alteracao(4) ou exclusao(5), deve-se posicionar no     //
	//     registro da SC2 antes de executar a rotina automatica     //
	//===============================================================//
	If nOpcao == 4 .Or. nOpcao == 5
		SC2->(DbSetOrder(1))
		SC2->(DbSeek(xFilial("SC2")+cNum+cItem+cSeq)) //FILIAL + NUM + ITEM + SEQUEN + ITEMGRD
	EndIf

	Begin Transaction

		MsExecAuto({|x, y|Mata650(x,y)},aDados,nOpcao)
		If !lMsErroAuto
			ConOut("operacao realizada com sucesso! " +Time())
		Else
			aErro := MostraErro()
			Conout("Nao foi possivel realizar operacao" +Time())
			DisarmTransaction()
		EndIf

	End Transaction
	RestArea (aArea)


	RESET ENVIRONMENT

Return Nil
