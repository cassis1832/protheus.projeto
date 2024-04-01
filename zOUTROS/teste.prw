#INCLUDE "PROTHEUS.CH"
#Include "TBIConn.ch"

User Function TESTE()

	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase

	dbSelectArea("ZA1")
Return
