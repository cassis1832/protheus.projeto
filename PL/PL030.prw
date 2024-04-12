#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL030
	Atualização das demandas do MRP com base no EDI (SVR)
   	Atualizar tabelas SVB e SVR - demandas do MRP (cliente/loja)
@author Assis
@since 11/04/2024
@version 1.0
	@return Nil, Função não tem retorno
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
	Elimina todas as demandas do código "AUTO"
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

return


/*---------------------------------------------------------------------*
	Cria as demandas no código "AUTO"
 *---------------------------------------------------------------------*/
Static Function CriaDemandas()
	
	Local nSequencia := 0

	dbSelectArea("ZA0")
	
	ZA0->(DBSetOrder(2))  // Filial, cliente, loja
	
	DBGoTop()

   	While ZA0->( !Eof() )

		nSequencia := nSequencia + 1

		// Inclusão
		DbSelectArea("SVR")
	
		RecLock("SVR", .T.)	
	
		SVR->VR_FILIAL		:= xFilial("SVR")
		SVR->VR_SEQUEN   	:= nSequencia
		SVR->VR_CODIGO   	:= "AUTO"
		SVR->VR_DATA 	  	:= ZA0->ZA0_DTENTR
		SVR->VR_TIPO   	:= "9"
		SVR->VR_PROD 		:= ZA0->ZA0_PRODUT
		SVR->VR_QUANT 	   := ZA0->ZA0_QTDE
		SVR->VR_LOCAL   	:= '02'
		SVR->VR_DOC 		:= ZA0->ZA0_NUMPED
		SVR->VR_REGORI   	:= 0
		SVR->VR_ORIGEM   	:= 'SVR'

		ZA0->( dbSkip() )
  	End While

	MsUnLock() 
Return
