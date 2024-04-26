FUNCTION X2Unico()
	Local cT1 := "T1"

	TCLink()

	DBCreate(cT1 , {{"CPOC1", "C", 10, 0}, ;
		{"CPOC2", "C", 10, 0}}, "TOPCONN")

	USE (cT1) ALIAS TRB EXCLUSIVE NEW VIA "TOPCONN"

	// exemplo com duas colunas
	nRet := TCUnique(cT1, "CPOC1+CPOC2")

	if nRet == 0
		conout("Índice único criado com sucesso")
	endif

	DBCloseArea()

	TCUnlink()
RETURN
