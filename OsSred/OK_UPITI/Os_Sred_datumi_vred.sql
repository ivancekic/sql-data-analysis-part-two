Select Os_sredstvo.rowid , Os_sredstvo.IDENT, Os_sredstvo.DATUM_NABAVKE, Os_sredstvo.DATUM_AKTIVIRANJA,
       Os_sredstvo.KOLICINA,Os_sredstvo.JM, Os_sredstvo.NABAVNA_VREDNOST,
       Os_sredstvo.SADASNJA_VREDNOST, Os_sredstvo.OTPISANA_VREDNOST,
       OS_AM_GRUPA.POCETNA_STOPA, Os_sredstvo.PODGRUPA
 From Os_sredstvo , OS_AM_GRUPA
Where Os_sredstvo.am_grupa = OS_AM_GRUPA.GRUPA
--and ident in  (333 , 334 )
Order by Ident
