-- ***************************************************************************
-- ** ????!!! Datum preve amortizacije mora biti jednak datumu aktiviranja  **
-- ***************************************************************************
Select rowid, NAZIV, ident, datum_nabavke, datum_aktiviranja, datum_amortizacije
From OS_SREDSTVO

WHERE IDENT BETWEEN --5313 AND 5316
      5317 --AND 5323
--5324
 AND 5327
