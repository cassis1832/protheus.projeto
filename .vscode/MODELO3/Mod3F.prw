User Function CADANALI()

Private cCadastro:="Cadastro de Analises"
Private cAlias1:= "SZM"
Private cAlias2:= "SZN"
Private aRotina:= {}

aAdd( aRotina, {"Pesquisar", "AxPesqui"   , 0, 1 })
aAdd( aRotina, {"Visualizar", "U_ANALISES", 0, 2 })
aAdd( aRotina, {"Incluir",    "U_ANALISES", 0, 3 })
aAdd( aRotina, {"Alterar",    "U_ANALISES", 0, 4 })
aAdd( aRotina, {"Excluir",    "U_ANALISES", 0, 5 })

//No caso do ambiente DOS, desenha a tela padrao de fundo

#IFNDEF WINDOWS
     ScreenDraw("SMT050", 3, 0, 0, 0)
     @3,1 Say cCadastro Color "B/W"
#ENDIF

dbselectarea(cAlias1)
dbsetorder(1)
dbgotop()

mBrowse( 6,1,22,75,"SZM")        //6,1,22,75

Return

//-----------------------------------------------------------------------



User Function ANALISES(cAlias,nRecno,nOpc)

Local i:=0
Local cLinok := "Allwaystrue"
Local cTudook := "U_ANALITUDOOK"
Local nOpce := nopc
Local nOpcg := nopc
Local cFieldok := "allwaystrue"
Local lVirtual := .T.
Local nLinhas := 99
Local nFreeze := 0
Local lRet := .T.

Private aCols := {}
Private aHeader := {}
Private aCpoEnchoice := {}
Private aAltEnchoice := {}
Private aAlt := {}

Regtomemory(cAlias1,(nOpc==3))
Regtomemory(cAlias2,(nOpc==3))

CriaHeader()
CriaCols(nOpc)

lRet:=Modelo3(cCadastro,cAlias1,cAlias2,aCpoEnchoice,cLinok,cTudook,nOpce,;
nOpcg,cFieldok,lVirtual,nLinhas,aAltenchoice,nFreeze,,,150)

If lRet
     
     //Se opcao for inclusão     
     If nOpc == 3
          If MsgYesNo("Confirma gravação dos dados ?",cCadastro)
               Processa({||Grvdados()},cCadastro,"Gravando os dados, aguarde...")
          EndIf
          
     //Se opção for alteração          
     ElseIf nOpc == 4
          If MsgYesNo("Confirma alteração dos dados ?", cCadastro)
               Processa({||Altdados()},cCadastro,"Alterando os dados, aguarde...")
          EndIf
          
     //Se opção for exclusão          
     ElseIf nOpc == 5
          If MsgYesNo("Confirma exclusão dos dados ?", cCadastro)
               Processa({||Excluidados()},cCadastro,"Excluindo os dados, aguarde...")
          EndIf
     EndIf
Else
     RollbackSx8()
EndIf

Return

//-----------------------------------------------------------------------

Static Function CriaHeader()

aHeader:= {}
aCpoEnchoice := {}
aAltEnchoice :={}
dbselectarea("SX3")
dbsetorder(1)
dbseek(cAlias2)

While ! EOF() .and. x3_arquivo == cAlias2
     If Upper(AllTrim(X3_CAMPO)) == "ZN_NUMANA"
          dbSkip()
          Loop
     Endif
     If x3uso(x3_usado) .and. cnivel >= x3_nivel
          aAdd(aHeader,{trim(x3_titulo),;
          x3_campo,;
          x3_picture,;
          x3_tamanho,;
          x3_decimal,;
          x3_valid,;
          x3_usado,;
          x3_tipo,;
          x3_arquivo,;
          x3_context})
     EndIf
     dbskip()
EndDo

dbseek(cAlias1)

While ! EOF() .and. x3_arquivo == cAlias1
     If x3uso(x3_usado) .and. cnivel >= x3_nivel
          aAdd(aCpoEnchoice,x3_campo)
          aAdd(aAltEnchoice,x3_campo)
     EndIf
     dbskip()
EndDo

Return

//-----------------------------------------------------------------------

Static function CriaCols(nOpc)

Local nQtdcpo := 0
Local i:= 0
Local nCols := 0

nQtdcpo := len(aHeader)
aCols:= {}
aAlt := {}

If nOpc == 3
     aAdd(aCols,array(nQtdcpo+1))
     For i := 1 to nQtdcpo
          aCols[1,i] := Criavar(aHeader[i,2])
     Next i
     aCols[1,nQtdcpo+1] := .F.
Else
     dbselectarea(cAlias2)
     dbsetorder(1)
     dbseek(xfilial(cAlias2)+(cAlias1)->ZM_NUMANA)
     
     While .not. EOF() .and. (cAlias2)->ZN_FILIAL == xfilial(cAlias2) .and. (cAlias2)->ZN_NUMANA==(cAlias1)->ZM_NUMANA
          aAdd(aCols,array(nQtdcpo+1))
          nCols++
          For i:= 1 to nQtdcpo
               If aHeader[i,10] <> "V"
                    aCols[nCols,i] := Fieldget(Fieldpos(aHeader[i,2]))
               Else
                    aCols[nCols,i] := Criavar(aHeader[i,2],.T.)
               EndIf
          Next i
          aCols[nCols,nQtdcpo+1] := .F.
          aAdd(aAlt,Recno())
          dbselectarea(cAlias2)
          dbskip()
     EndDo
EndIf

Return

//-----------------------------------------------------------------------

Static Function GrvDados()

Local bcampo := {|nfield| field(nfield) }
Local i:= 0
Local y:= 0
Local nItem :=0

procregua(len(aCols)+fCount())
dbselectarea(cAlias1)
Reclock(cAlias1,.T.)
For i:= 1 to fcount()
     incproc()
     If "FILIAL" $ fieldname(i)
          Fieldput(i,xfilial(cAlias1))
     Else
          Fieldput(i,M->&(EVAL(BCAMPO,i)))
     EndIf
Next
Msunlock()

dbselectarea(cAlias2)
dbsetorder(1)
For i:=1 to len(aCols)
     incproc()
     If .not. aCols[i,len(aHeader)+1]
          Reclock(cAlias2,.T.)
          For y:= 1 to len(aHeader)
               Fieldput(Fieldpos(trim(aHeader[y,2])),aCols[i,y])
          Next
          nItem++
          (cAlias2)->ZN_FILIAL := xfilial(cAlias2)
          (cAlias2)->ZN_NUMANA := (cAlias1)->ZM_NUMANA
          (cAlias2)->ZN_ITEM := strzero(nItem,2,0)
          Msunlock()
     Endif
Next

Return

//-----------------------------------------------------------------------

Static Function Altdados()
Local bcampo := { |nfield| field(nfield) }
Local i:= 0
Local y:= 0
Local nitem := 0

procregua(len(aCols)+fCount())
dbselectarea(cAlias1)
Reclock(cAlias1,.F.)
For i:= 1 to fcount()
     incproc()
     If "FILIAL" $ fieldname(i)
          Fieldput(i,xfilial(cAlias1))
     Else
          Fieldput(i,M->&(EVAL(BCAMPO,i)))
     EndIf
Next i
Msunlock()

dbselectarea(cAlias2)
dbsetorder(1)
nItem := len(aAlt)+1

For i:=1 to len(aCols)
     If i<=len(aAlt)
          dbgoto(aAlt)
          Reclock(cAlias2,.F.)
          If aCols[i,len(aHeader)+1]
               DbDelete()
          Else
               For y:= 1 to len(aHeader)
                    Fieldput(Fieldpos(trim(aHeader[y,2])),aCols[i,y])
               Next y
          EndIf
          Msunlock()
     Else
          If ! aCols[i,len(aHeader)+1]
               Reclock(cAlias2,.T.)
               For y:= 1 to len(aHeader)
                    Fieldput(Fieldpos(trim(aHeader[y,2])),aCols[i,y])
               Next y
               (cAlias2)->ZN_FILIAL := xfilial(calias2)
               (cAlias2)->ZN_NUMANA := (cAlias1)->ZM_NUMANA
               (cAlias2)->ZN_ITEM := strzero(nItem,2,0)
               Msunlock()
               nItem++
          EndIf
     Endif     
Next i   

Return

//-----------------------------------------------------------------------

Static Function Excluidados()

procregua(len(aCols)+1)

dbselectarea(cAlias2)
dbsetorder(1)
dbseek(xfilial(cAlias2)+(cAlias1)->ZM_NUMANA)
While .not. EOF() .and. (cAlias2)->ZN_FILIAL == xfilial(cAlias2) .and. (cAlias2)->ZN_NUMANA==(cAlias1)->ZM_NUMANA
     incproc()
     Reclock(cAlias2,.F.)
     DbDelete()
     Msunlock()
     dbskip()
EndDo
dbselectarea(cAlias1)
dbsetorder(1)
incproc()
Reclock(cAlias1,.F.)
DbDelete()
Msunlock()

Return

//-----------------------------------------------------------------------

User function ANALITUDOOK()
Local lRet:= .T.
Local i:=0
Local nDel :=0

For i:=1 to len(aCols)
     If aCols[i,len(aHeader)+1]
          nDel++
     Endif
Next

If nDel == len(aCols)
     Msginfo("Para excluir todos os itens, utilize a opção EXCLUIR",cCadastro)
     lRet := .F.
EndIf

Return(lRet)
