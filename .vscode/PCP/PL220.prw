#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL220
Função: Consulta carga máquina SH8
@author Assis
@since 09/09/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL220()
/*/

Static cTitulo := "Carga Maquina"

User Function PL220()
	Local aPergs		:= {}
	Local aResps		:= {}
	Local cCondicao		:= ""
	Local oBrowse

	Private aComboLin	:= {"Estamparia","Solda"}
	Private cRecurso 	:= ""
	Private cLinha		:= ""

	AAdd(aPergs ,{2, "Linha de producao:"	,01, aComboLin, 70, "", .T.})
	AAdd(aPergs, {1, "Recurso"				, CriaVar("H1_CODIGO",.F.),,,"SH1",, 70, .F.})

	If ParamBox(aPergs, "PLANO DE PRODUCAO", @aResps,,,,,,,, .T., .T.)
		nLinha		:= aResps[1]
		cRecurso	:= aResps[2]
	Else
		return
	endif

	FwMsgRun(NIL, {|oSay| PreparaSH8(oSay)}, "Preparando arquivo de trabalho", "Preparando arquivo de trabalho...")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SH8")
	oBrowse:SetDescription(cTitulo)

	if (allTrim(cRecurso) != '')
		cCondicao := "H8_RECURSO == '" + cRecurso + "'"
	else
		IF nLinha == 1
			cCondicao := "H8_XLINPRD == '" + "E" + "'"
		else
			cCondicao := "H8_XLINPRD == '" + "S" + "'"
		endif
	endif

	oBrowse:SetFilterDefault( cCondicao )
	oBrowse:DisableDetails()

	// oBrowse:SetOnlyFields({'H8_XPROD','H8_OP'})
	// oBrowse:AddLegend("SH8->SH8_STATUS == '0'", "GREEN", "Ativo")
	// oBrowse:AddLegend("SH8->SH8_STATUS == '1'", "YELLOW", "Com erro")
	// oBrowse:AddLegend("SH8->SH8_STATUS == '9'", "RED", "Inativo")

	oBrowse:Activate()
Return Nil


Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL220' OPERATION 2   					  ACCESS 0
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL220' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8     				  Access 0
Return aRot

/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
    Local oStSH8   := FWFormStruct(1, "SH8")
 
	oStSH8:SetProperty('H8_OPER',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSH8:SetProperty('H8_RECURSO',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStSH8:SetProperty('H8_QUANT',MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL220M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil) 
	oModel:AddFields("FORMSH8",/*cOwner*/,oStSH8)
	oModel:SetPrimaryKey({'SH8_FILIAL','SH8_CODPED'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMSH8"):SetDescription("Formulario do Cadastro "+cTitulo)
Return oModel

/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL220")      
    Local oStSH8 := FWFormStruct(2, "SH8")    

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
    oView:AddField("VIEW_SH8", oStSH8, "FORMSH8")
    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView('VIEW_SH8', 'Dados - '+cTitulo )  
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SH8","TELA")

Return oView


Static Function MVCMODELPOS(oModel)
	Local lOk			:= .T.
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL220ProLeg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE","Ativo"})
    AAdd(aLegenda,{"BR_AMARELO","Com Erro"})
    AAdd(aLegenda,{"BR_VERMELHO","Inativo"})
    BrwLegenda("Registros", "Status", aLegenda)
return


/*---------------------------------------------------------------------*
  Atualiza o cod. produto na SH8
 *---------------------------------------------------------------------*/
Static Function PreparaSH8(oSay)
	SH8->(dbSetOrder(1))
	SC2->(dbSetOrder(1))
	SB1->(dbSetOrder(1))

	While SH8->(!Eof())
	
		if allTrim(SH8->H8_XPROD) == '' .or. SH8->H8_XPROD == Nil .or. allTrim(SH8->H8_XLINPRD) == ''
			RecLock("SH8", .F.)

			if SC2->(MsSeek(xFilial("SC2") + SH8->H8_OP))
				SH8->H8_XPROD := SC2->C2_PRODUTO
			endif

			if SB1->(MsSeek(xFilial("SB1") + SC2->C2_PRODUTO))
				SH8->H8_XLINPRD := SB1->B1_XLINPRD
			endif
			
			MsUnLock()
		endif

		SH8->(dbSkip())
	End
return

