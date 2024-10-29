#Include "TOTVS.ch"
#Include "TBICONN.ch"

User Function RMATA681()

	Local aVetor := {}
	Local dData
	Local nOpc   := 3 //Incluir
	Private lMsErroAuto :=.F.
	Private lMsHelpAuto :=.T.

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SH6"

	dData:=dDataBase
	aVetor := {;
		{"H6_OP"      ,"00001601001   "         ,NIL},;
		{"H6_PRODUTO" ,"01             "        ,NIL},;
		{"H6_OPERAC"  ,"01"                     ,NIL},;
		{"H6_DTAPONT" ,dData                    ,NIL},;
		{"H6_DATAINI" ,dData                    ,NIL},;
		{"H6_HORAINI" ,"19:11"                  ,NIL},;
		{"H6_DATAFIN" ,dData                    ,NIL},;
		{"H6_HORAFIN" ,"19:20"                  ,NIL},;
		{"H6_PT"      ,'P'                      ,NIL},;
		{"H6_LOCAL"   ,"01"                     ,NIL},;
		{"H6_QTDPROD" ,7                        ,NIL}}

	MSExecAuto({|x| mata681(x)},aVetor, nOpc)

	If lMsErroAuto
		If (!IsBlind())
			MostraErro()
		Else // EM ESTADO DE JOB
			cError := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO

		ENDIF
	Else

		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA681 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	EndIf
Return
