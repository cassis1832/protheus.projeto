#INCLUDE 'protheus.ch'
#INCLUDE 'parmtype.ch'
#INCLUDE 'TBICONN.CH'

// Deletar OPS sem uso
User Function zAssis()
	local aArea         := GetArea()
	Local oSay 			:= NIL

	Private lMsErroAuto := .F.

	If ! FWAlertNoYes("DELETE DE OPS ANTIGAS 28/10/2024", "Continuar?")
		Return
	EndIf

//	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "PCP"

	FwMsgRun(NIL, {|oSay| Atualiza(oSay)}, "Deletando OP ", "Preparando...")

	MessageBox("ATUALIZACAO EFETUADA COM SUCESSO!","",0)

	RestArea (aArea)

	RESET ENVIRONMENT
Return


Static Function Atualiza(oSay)
	Local aDados        := {}
	Local nOpcao        := 5            // Inclusao = 3 // Alteracao = 4 // Exclusao = 5
	Local dData			:= Daysub(Date(),7)
	Local cOP			:= ''
	Local nAcum			:= 0

	SC2->(DbSetOrder(1))
	SC2->(DbGoTop())

	While SC2->(! EOF())

		if SC2->C2_FILIAL  == xFilial("SC2") 	.and. ;
				SC2->C2_DATPRI  <= dData 		.and. ;
				SC2->C2_QUJE  	== 0	 		.and. ;
				SC2->C2_TPOP	== 'F'			.and. ;
				SC2->C2_TPPR	== 'I'			.and. ;
				A650DefLeg(3)	== .F.			.and. ;
				alltrim(dtOs(SC2->C2_DATRF))   == ""

			cOP := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN

			oSay:SetText("Deletando: " + cOP + " - " + cValToChar(nAcum))
			ProcessMessages() // FORÇA O DESCONGELAMENTO DO SMARTCLIENT
			Sleep(300)

			aDados :=   {;
				{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
				{'C2_ITEM'     ,SC2->C2_ITEM       ,NIL},;
				{'C2_PRODUTO'  ,SC2->C2_PRODUTO    ,NIL},;
				{'C2_NUM'      ,SC2->C2_NUM        ,NIL},;
				{'C2_SEQUEN'   ,SC2->C2_SEQUEN     ,NIL};
				}

			Begin Transaction

				MsExecAuto({|x, y|Mata650(x,y)},aDados,nOpcao)
				If !lMsErroAuto
					ConOut("delete realizado com sucesso! " +Time() + ' ' + cOP)
					nAcum := nAcum + 1
				Else
					MessageBox("NAO FOI POSSIVEL DELETAR!","",0)
				EndIf

			End Transaction

		endif

		if nAcum >= 50
			exit
		endif

		SC2->(DbSkip())
	enddo

	alert(nAcum)
Return Nil
