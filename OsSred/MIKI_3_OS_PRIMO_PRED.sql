SELECT 'RUBIN' FIRMA, PERA.IME_PREZIME, RTRIM(LTRIM(os.skraceni_naziv)) TIP_OPREME,
      DECODE (
               (CASE instr(upper(pera.ident_naziv),UPPER('ALK')) WHEN 0 THEN 'nema' ELSE 'ALCATEL' END )
               ,'nema'
               ,(CASE instr(upper(pera.ident_naziv),UPPER('nok')) WHEN 0 THEN 'nema' ELSE 'NOKIA' END)
               ,(CASE instr(upper(pera.ident_naziv),UPPER('alk')) WHEN 0 THEN 'nema' ELSE 'ALCATEL' END)
--               ,(CASE instr(upper(pera.ident_naziv),UPPER('bro')) WHEN 0 THEN 'nema' ELSE 'BROTHER' END)
--               ,'PANASONIC',(CASE instr(upper(pera.ident_naziv),UPPER('pan')) WHEN 0 THEN 'nema' ELSE 'PANASONIC' END)
--               ,'REFLEX',(CASE instr(upper(pera.ident_naziv),UPPER('rex')) WHEN 0 THEN 'nema' ELSE 'REFLEX' END)
--               ,'nema'
      )
         PROIZVODJAC,
       ' ' MARKA, ' ' LOKACIJA, ' ' SERIJSKI_BROJ, PERA.IDENT INVENTARSKI_BROJ,
       pera.ident_naziv,PERA.DATUM_ZADUZENJA, 'RUBIN' FIRMA

FROM
( SELECT rad.ime || ' ' || rad.prezime IME_PREZIME,
         IDENT, POsSredstvo.naziv(IDENT) ident_naziv, DOK.POSLOVNA_GODINA GOD, DOK.BROJ, DOK.DATUM,
         DOK.STATUS, DOK.DATUM_PROMENE DATUM_ZADUZENJA,KOLICINA_ZADUZENA KOL, RAD.SR_STATUS
FROM OS_PRIMOPREDAJA DOK, OS_PRIMOPREDAJA_STAVKA ST, radnici rad
WHERE ST.POSLOVNA_GODINA = DOK.POSLOVNA_GODINA AND ST.BROJ = DOK.BROJ and rad.radnik = dok.ZADUZIO
  AND IDENT IN (Select Ident from os_sredstvo where rev_grupa in('102') and status    = 'A' )
) PERA, os_sredstvo os
WHERE PERA.DATUM =( Select max( DOK1.Datum ) FROM OS_PRIMOPREDAJA DOK1, OS_PRIMOPREDAJA_STAVKA ST1
                    WHERE ST1.POSLOVNA_GODINA = DOK1.POSLOVNA_GODINA AND ST1.BROJ = DOK1.BROJ AND ST1.IDENT = PERA.IDENT
                  )
  AND PERA.DATUM_ZADUZENJA =( Select max( DOK1.Datum_PROMENE ) FROM OS_PRIMOPREDAJA DOK1, OS_PRIMOPREDAJA_STAVKA ST1
                             WHERE ST1.POSLOVNA_GODINA = DOK1.POSLOVNA_GODINA AND ST1.BROJ = DOK1.BROJ AND ST1.IDENT = PERA.IDENT
                           )
   and os.ident     = pera.ident
   and
      (   upper(os.skraceni_naziv) like upper('spikerfo%') or upper(os.skraceni_naziv)  like upper('tel%')
       or upper(os.skraceni_naziv)  like upper('%tel%') or upper(os.skraceni_naziv)  like upper('mobil%')
       )

ORDER BY RTRIM(LTRIM(os.skraceni_naziv)) --os.skraceni_naziv, os.IDENT
