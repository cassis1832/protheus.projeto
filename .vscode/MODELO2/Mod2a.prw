#include "protheus.ch"
#INCLUDE "rwmake.ch"

/*
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360021384491-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Modelo2-com-mais-de-99-Registros
*/

User Function Md2()

	Local nOpcx:=3

//+-----------------------------------------------+
//¦ Montando aHeader para a Getdados ¦
//+-----------------------------------------------+

	dbSelectArea("Sx3")
	dbSetOrder(1)
	dbSeek("ZA1")
	nUsado:=0
	aHeader:={}

	While !Eof() .And. (x3_arquivo == "ZA1")

		IF X3USO(x3_usado) .AND. cNivel >= x3_nivel
			nUsado:=nUsado+1

			AADD(aHeader,{ TRIM(x3_titulo),x3_campo,;
				x3_picture,x3_tamanho,x3_decimal,;
				"ExecBlock('Md2valid',.f.,.f.)",x3_usado,;
				x3_tipo, x3_arquivo, x3_context } )

		Endif

		dbSkip()

	End

//+-----------------------------------------------+
//¦ Montando aCols para a GetDados ¦
//+-----------------------------------------------+

	aCols:= Array(1,nUsado+1)

	dbSelectArea("Sx3")
	dbSeek("ZA1")

	nUsado:=0

	While !Eof() .And. (x3_arquivo == "ZA1")

		IF X3USO(x3_usado) .AND. cNivel >= x3_nivel
			nUsado:=nUsado+1

			IF nOpcx == 3

				IF x3_tipo == "C"
					aCOLS[1][nUsado] := SPACE(x3_tamanho)

				Elseif x3_tipo == "N"
					aCOLS[1][nUsado] := 0

				Elseif x3_tipo == "D"
					aCOLS[1][nUsado] := dDataBase

				Elseif x3_tipo == "M"
					aCOLS[1][nUsado] := ""

				Else
					aCOLS[1][nUsado] := .F.

				Endif

			Endif

		Endif

		dbSkip()
	End

	aCOLS[1][nUsado+1] := .F.

//+----------------------------------------------+
	//¦ Variaveis do Cabecalho do Modelo 2 ¦
	//+----------------------------------------------+

	cCliente:=Space(6)

	cLoja :=Space(2)

	dData :=Date()

	//+----------------------------------------------+
	//¦ Variaveis do Rodape do Modelo 2
	//+----------------------------------------------+
	nLinGetD:=0

	//+----------------------------------------------+
	//¦ Titulo da Janela ¦
	//+----------------------------------------------+

	cTitulo:="TESTE DE MODELO2"

	//+----------------------------------------------+
	//¦ Array com descricao dos campos do Cabecalho ¦
	//+----------------------------------------------+
	aC:={}

	#IFDEF WINDOWS

		AADD(aC,{"cCliente" ,{15,10} ,"Cod. do Cliente","@!",'ExecBlock("MD2VLCLI",.F.,.F.)',"SA1",})

		AADD(aC,{"cLoja" ,{15,200},"Loja","@!",,,})

		AADD(aC,{"dData" ,{27,10} ,"Data de Emissao",,,,})

	#ELSE

		AADD(aC,{"cCliente" ,{6,5} ,"Cod. do Cliente","@!",'ExecBlock("MD2VLCLI",.F.,.F.)',"SA1",})

		AADD(aC,{"cLoja" ,{6,40},"Loja","@!",,,})

		AADD(aC,{"dData" ,{7,5} ,"Data de Emissao",,,,})

	#ENDIF

	//+-------------------------------------------------+
	//¦ Array com descricao dos campos do Rodape ¦
	//+-------------------------------------------------+

	aR:={}

	#IFDEF WINDOWS

		AADD(aR,{"nLinGetD" ,{120,10},"Linha na GetDados", "@E 999",,,.F.})

	#ELSE

		AADD(aR,{"nLinGetD" ,{19,05},"Linha na GetDados","@E 999",,,.F.})

	#ENDIF

	//+------------------------------------------------+
	//¦ Array com coordenadas da GetDados no modelo2 ¦
	//+------------------------------------------------+

	#IFDEF WINDOWS

		aCGD:={44,5,118,315}

	#ELSE

		aCGD:={10,04,15,73}

	#ENDIF

//+----------------------------------------------+
//¦ Validacoes na GetDados da Modelo 2 ¦
//+----------------------------------------------+

	cLinhaOk := "ExecBlock('Md2LinOk',.f.,.f.)"
	cTudoOk := "ExecBlock('Md2TudOk',.f.,.f.)"

//+----------------------------------------------+
//¦ Chamada da Modelo2 ¦
//+----------------------------------------------+
// lRet = .t. se confirmou
// lRet = .f. se cancelou

	lRet:= Modelo2(cTitulo,aC,aR,aCGD,nOpcx,cLinhaOk,cTudoOk, , , ,999)

	If lRet
		//Inclui os Registros na tabela SZF
		For nInd := 1 to len( aCols )
			If !(aCols[nInd][len(aHeader)+1]) //não foi deletado
				// Em 11/02/15 inserimos o tratamento do motivo para apontamentos de horas não vinculados à OP conforme pedido do Haroldo - MG
				// Em 19/03/14 retiramos a validação de apontamentos existentes desta área e a movemos para função que valida todo o vetor acols - MG
				RecLock("ZA1",.t.)

				Replace ZA1->ZA1_FILIAL with xFilial('SZF') , ;
					ZA1->ZA1_MUSICA with aCols[nInd][aScan( aHeader, { |x| x[2]="ZA1_MUSICA" } )] , ;
					ZA1->ZA1_TITULO with aCols[nInd][aScan( aHeader, { |x| x[2]="ZA1_TITULO" } )] , ;//cCCustoMO , ;
					ZA1->ZA1_DATA with aCols[nInd][aScan( aHeader, { |x| x[2]="ZA1_DATA" } )] , ;
					ZA1->ZA1_GENERO with aCols[nInd][aScan( aHeader, { |x| x[2]="ZA1_GENERO" } )]

				ZA1->(MsUnlock())
			EndIf
		Next
	EndIf



Return lRet

User function Md2LinOk()

//Msginfo("Validando a linha")

Return .t.

User function Md2TudOk()

//Msginfo("Validando o Formulário")

Return .t.

User function Md2valid()

//Msginfo("Validando")

Return .t.


User function MD2VLCLI()

//Msginfo("Validando")

Return .t.
