#INCLUDE "Protheus.ch"

User Function callClass()

    Local cNome := "Carlos Assis"
    Local dData := CTOD( "05/02/1959")

    Local oPessoa   := Pessoa():New(cNome, dData)

    Alert(oPessoa:cNomePerson)
    Alert(oPessoa:dNascimento)
    
Return return_var
