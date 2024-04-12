#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL030
	Atualiza��o das demandas do MRP com base no EDI (SVR)
   	Atualizar tabelas SVB e SVR - demandas do MRP (cliente/loja)
@author Assis
@since 11/04/2024
@version 1.0
	@return Nil, Fun��o n�o tem retorno
	@example
	u_PL030()
/*/

User Function PL030()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	//----------------------------------------------
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase
	//----------------------------------------------

	SetFunName("PL030")

	// Limpar as demandas existentes - manuais - cliente/loja
	// Recriar salvando o ID na demanda para ter referencia

	LimpaDemandas()
	CriaDemandas()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


/*---------------------------------------------------------------------*
	Elimina todas as demandas do c�digo "AUTO"
 *---------------------------------------------------------------------*/
Static Function LimpaDemandas()

	dbSelectArea("SVR")
	SVR->(DBSetOrder(1))  // 
	DBGoTop()

   	While SVR->( !Eof() )

		if VR_CODIGO = 'AUTO'
      		RecLock("SVR", .F.)
      		DbDelete()
      		SVR->(MsUnlock())
		EndIf

		SVR->( dbSkip() )
  	End While

	dbSelectArea("T4J")
	T4J->(DBSetOrder(1))  // 
	DBGoTop()

   	While T4J->( !Eof() )

		if T4J_CODE = 'AUTO'
      		RecLock("T4J", .F.)
      		DbDelete()
      		SVR->(MsUnlock())
		EndIf

		T4J->( dbSkip() )
  	End While

return


/*---------------------------------------------------------------------*
	Cria as demandas no c�digo "AUTO"
 *---------------------------------------------------------------------*/
Static Function CriaDemandas()
	
	Local nSequencia := 0
	Local cLocal	 := ''

	dbSelectArea("ZA0")
	ZA0->(DBSetOrder(2))  // Filial, cliente, loja
	DBGoTop()

   	While ZA0->( !Eof() )
		cLocal := ''
		nSequencia := nSequencia + 1

		DbSelectArea("SB1")
		SB1->(DBSetOrder(1))  

	 	DBSeek(xFilial("SB1")+ZA0->ZA0_PRODUT)

		if ! Eof()
			IF B1_FILIAL == xFilial("SB1") .And. B1_PRODUTO == ZA0_PRODUT 
				cLocal := SB1->B1_LOCAL
			EndIf
		EndIf

		// Inclus�o
		DbSelectArea("SVR")
		RecLock("SVR", .T.)	
		SVR->VR_FILIAL		:= xFilial("SVR")
		SVR->VR_CODIGO   	:= "AUTO"
		SVR->VR_SEQUEN   	:= nSequencia
		SVR->VR_PROD 		:= ZA0->ZA0_PRODUT
		SVR->VR_LOCAL   	:= '02'
		SVR->VR_DATA 	  	:= ZA0->ZA0_DTENTR
		SVR->VR_QUANT 	   	:= ZA0->ZA0_QTDE
		SVR->VR_TIPO   		:= "9"
		SVR->VR_DOC 		:= ZA0->ZA0_NUMPED
		SVR->VR_REGORI   	:= 0
		SVR->VR_ORIGEM   	:= 'SVR'
		SVR->(MsUnlock())

		DbSelectArea("T4J")
		RecLock("T4J", .T.)	
		T4J->T4J_FILIAL		:= SVR->VR_FILIAL
		T4J->T4J_DATA 	  	:= SVR->VR_DATA
		T4J->T4J_PROD 		:= SVR->VR_PROD
		T4J->T4J_ORIGEM   	:= SVR->VR_TIPO
		T4J->T4J_DOC 		:= SVR->VR_DOC
		T4J->T4J_QUANT 	   	:= SVR->VR_QUANT
		T4J->T4J_LOCAL   	:= SVR->VR_LOCAL
		T4J->T4J_PROC		:= 2
		T4J->T4J_IDREG   	:= SVR->VR_FILIAL + SVR->VR_CODIGO + SVR->VR_SEQUEN
		T4J->T4J_CODE   	:= SVR->VR_CODIGO
		T4J->(MsUnlock())

		ZA0->( dbSkip() )
  	End While

Return
