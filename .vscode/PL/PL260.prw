#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL260
Função: Carga maquina - selecao por maquina
@author Assis
@since 04/10/2024	
@version 1.0
	@return Nil, Funcao nao tem retorno
	@example
	u_PL260()
/*/

Static cTitulo := "Plano de Producao por Maquina - MR"

User Function PL260()
	Local oBrowse
	Local aPergs		:= {}
	Local aResps		:= {}
	Local cFiltro		:= ""

	Private dDtIni  	:= Nil
	Private dDtFim  	:= Nil
	Private lEstamp 	:= .F.
	Private lSolda  	:= .F.

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {4, "Estamparia"				,.T.,"Estamparia" ,90,"",.F.})
	AAdd(aPergs, {4, "Solda"					,.T.,"Solda" ,90,"",.F.})

	If ParamBox(aPergs, "PL260 - CARGA MAQUINA MR", @aResps,,,,,,,, .T., .T.)
		dDtIni 		:= aResps[1]
		dDtFim 		:= aResps[2]
		lEstamp		:= aResps[3]
		lSolda		:= aResps[4]
	Else
		return
	endif

	if lEstamp == .T.
		cFiltro		+= " H1_LINHAPR == '01' "
	endif

	if lSolda == .T.
		if cFiltro != ""
			cFiltro += " .or. "
		endif
		cFiltro += "H1_LINHAPR == '02'"
	endif

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SH1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetFilterDefault( cFiltro )
	oBrowse:Activate()
Return Nil

/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar'  ACTION 'U_PL260Consulta()' OPERATION MODEL_OPERATION_VIEW ACCESS 0 
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSH1   := FWFormStruct(1, "SH1")

	oModel:=MPFormModel():New("PL260M", Nil, Nil, Nil, Nil) 
	oModel:AddFields("FORMSH1",/*cOwner*/,oStSH1)
	oModel:SetPrimaryKey({'SH1_FILIAL','SH1_CODIGO'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSH1"):SetDescription("Maquinas "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL260")      
    Local oStSH1 := FWFormStruct(2, "SH1")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SH1", oStSH1, "FORMSH1")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SH1', 'Maquina - ' + cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SH1","TELA")

Return oView


User Function PL260Consulta()
    U_PL230(H1_CODIGO, dDtIni, dDtFim)
return


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL260Leg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return
