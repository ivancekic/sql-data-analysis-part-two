SELECT DOK.POSLOVNA_GODINA, DOK.BROJ, DOK.DATUM, DOK.ORG_DEO_NA, DOK.LOKACIJA_NA, DOK.ZADUZIO,
       DOK.STATUS, DOK.DATUM_PROMENE, DOK.USERNAME,
       IDENT, KOLICINA_ZADUZENA

FROM OS_PRIMOPREDAJA DOK, OS_PRIMOPREDAJA_STAVKA ST

WHERE ST.POSLOVNA_GODINA = DOK.POSLOVNA_GODINA
  AND ST.BROJ            = DOK.BROJ
--  AND DOK.RAZDUZIO       = DOK.ZADUZIO
--  AND DOK.ORG_DEO_SA     = DOK.ORG_DEO_NA
--  AND DOK.LOKACIJA_SA    = DOK.LOKACIJA_NA
  AND IDENT IN (Select Ident
                from os_sredstvo
                where rev_grupa = '109'
                  and status = 'A'
               )

  AND DOK.DATUM =( Select max( C1.Datum )
                         From Prodajni_Cenovnik C1
                         Where C1.Proizvod = cProizvod AND
                               C1.Valuta = cValuta AND
                               C1.Datum < TO_DATE(TO_CHAR(dDatum,'DD.MM.YYYY') ||' '||'23:59:59','DD.MM.YYYY HH24:MI:SS')) 
