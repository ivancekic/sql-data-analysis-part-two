SELECT os.skraceni_naziv, pera.* FROM
(
SELECT IDENT, POsSredstvo.naziv(IDENT) ident_naziv, DOK.POSLOVNA_GODINA GOD, DOK.BROJ, DOK.DATUM,
       DOK.ORG_DEO_NA ORG, PORGANIZACIONIDEO.NAZIV(DOK.ORG_DEO_NA) NAZIV,
       DOK.LOKACIJA_NA LOK, POsLokacija.NAZIV(DOK.LOKACIJA_NA) LOK_NAZIV,
       DOK.ZADUZIO, Pradnici.Podaci(DOK.ZADUZIO) ZADUZIO_,
       DOK.STATUS, DOK.DATUM_PROMENE,  --DOK.USERNAME,
       KOLICINA_ZADUZENA KOL

FROM OS_PRIMOPREDAJA DOK, OS_PRIMOPREDAJA_STAVKA ST
WHERE ST.POSLOVNA_GODINA = DOK.POSLOVNA_GODINA
  AND ST.BROJ            = DOK.BROJ
  AND IDENT IN (Select Ident
                from os_sredstvo
                where rev_grupa = '109'
                  and status = 'A'
               )
) PERA, os_sredstvo os

WHERE PERA.DATUM =( Select max( DOK1.Datum )
                    FROM OS_PRIMOPREDAJA DOK1, OS_PRIMOPREDAJA_STAVKA ST1
                    WHERE ST1.POSLOVNA_GODINA = DOK1.POSLOVNA_GODINA
                      AND ST1.BROJ            = DOK1.BROJ
                      AND ST1.IDENT           = PERA.IDENT
                  )
   AND PERA.DATUM_PROMENE =( Select max( DOK1.Datum_PROMENE )
                             FROM OS_PRIMOPREDAJA DOK1, OS_PRIMOPREDAJA_STAVKA ST1
                             WHERE ST1.POSLOVNA_GODINA = DOK1.POSLOVNA_GODINA
                               AND ST1.BROJ            = DOK1.BROJ
                               AND ST1.IDENT           = PERA.IDENT
                           )
   and os.ident = pera.ident
   and upper(os.skraceni_naziv) in (upper('racunar'), upper('monitor'))
   and (    upper(ident_naziv) like upper('%ESPRIMO%')
         or upper(ident_naziv) like upper('%A17-%')
         or upper(ident_naziv) like upper('%fujitsu%')
       )
ORDER BY os.IDENT
