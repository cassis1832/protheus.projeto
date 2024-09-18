#Include "Protheus.ch"
#include "rwmake.ch"
#include "TbiConn.ch"

User Function Tmata650()
	Local aMATA650 := {} //-Array com os campos
	LOCAL DDATABASE := CTOD("08/11/2018")

//---------------------
// 3 - Inclusao
// 4 - Alteracao
// 5 - Exclusao
//---------------------
	Local nOpc := 3

	Private lMsErroAuto := .F.

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

	aMATA650 := { {'C2_FILIAL' ,"01" ,NIL},;
		{'C2_NUM' ,"000060" ,NIL},;
		{'C2_ITEM' ,"01" ,NIL},;
		{'C2_SEQUEN' ,"001" ,NIL},;
		{'C2_PRODUTO' ,"P001 " ,NIL},;
		{'C2_LOCAL' ,"01" ,NIL},;
		{'C2_QUANT' ,5 ,NIL},;
		{'C2_DATPRI' ,DDATABASE ,NIL},;
		{'C2_DATPRF' ,CTOD("09/11/2018") ,NIL},;
		{'AUTEXPLODE' ,"S" ,NIL}}

	ConOut("Inicio : "+Time())

	msExecAuto({|x,Y| Mata650(x,Y)},aMata650,nOpc)

	If !lMsErroAuto
		ConOut("Sucesso! ")
	Else
		ConOut("Erro!")
		MostraErro()
	EndIf

	ConOut("Fim : "+Time())

	RESET ENVIRONMENT
Return Nil
