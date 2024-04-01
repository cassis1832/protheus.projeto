#INCLUDE "Protheus.ch"

Class Pessoa

    Data cNomPerson
    Data dNascimento

    Method New(cNome, dDtNasc) CONSTRUCTOR
EndClass


Method New(cNome, dDtNasc) Class Pessoa
    ::cNomPerson    := cNome
    ::dNascimento   := dDtNasc
Return self
