SELECT FIRMA, IME_PREZIME, DECODE(PROIZVODJAC,'NOKIA','Mobilni',TIP_OPREME) tip_op,PROIZVODJAC,
       ' 'MARKA,
	   ' ' LOKACIJA, ' ' SERIJSKI_BROJ, INVENTARSKI_BROJ,
       ident_naziv,DATUM_ZADUZENJA, FIRMA1
FROM
(
	SELECT 'RUBIN' FIRMA, PERA.IME_PREZIME, RTRIM(LTRIM(os.skraceni_naziv)) TIP_OPREME,
	       ( CASE
	         WHEN instr(upper(pera.ident_naziv),'ALK') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'NOK') > 0 THEN 'NOKIA'
	         WHEN instr(upper(pera.ident_naziv),'SIME') > 0 THEN 'SIMENS'
	         WHEN instr(upper(pera.ident_naziv),'ERI') > 0 THEN 'ERICSSON'
	         WHEN instr(upper(pera.ident_naziv),'BRO') > 0 THEN 'BROTHER'
	         WHEN instr(upper(pera.ident_naziv),'PAN') > 0 THEN 'PANASONIC'
	         WHEN instr(upper(pera.ident_naziv),'EASY') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'FIRST') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'PREMI') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'DIGITALNI TELE') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'KHFT') > 0 THEN 'PANASONIC'
	         WHEN instr(upper(pera.ident_naziv),'KXT') > 0 THEN 'PANASONIC'
	         WHEN instr(upper(pera.ident_naziv),'KX-') > 0 THEN 'PANASONIC'
	         WHEN instr(upper(pera.ident_naziv),'KHT') > 0 THEN 'PANASONIC'
	         WHEN instr(upper(pera.ident_naziv),'ADVANCE') > 0 THEN 'ALCATEL'
	         WHEN instr(upper(pera.ident_naziv),'REFLE') > 0 THEN 'ALCATEL'
	         ELSE
	           'nema'
	       END
	       ) PROIZVODJAC,
	       PERA.IDENT INVENTARSKI_BROJ,
	       pera.ident_naziv,PERA.DATUM_ZADUZENJA, 'RUBIN' FIRMA1

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
)
ORDER BY TIP_OPREME, MARKA,DECODE(PROIZVODJAC,'NOKIA','Mobilni',TIP_OPREME) --os.skraceni_naziv, os.IDENT
