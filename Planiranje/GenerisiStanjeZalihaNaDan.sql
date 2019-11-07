
--GenerisiStanjeZalNaDan (nOrgDeo Number, dDatum
DECLARE
 nRbr NUMBER;
BEGIN
 nRbr := 0;
	FOR MAG IN(SELECT DISTINCT ORG_DEO, datum_dok FROM DOKUMENT
	           WHERE VRSTA_dOK = 21
	             AND GODINA = 2012
	             AND STATUS=1
	           ORDER BY ORG_DEO
	          )
    LOOP
       nRbr := nRbr + 1;
       DBMS_OUTPUT.PUT_LINE(rpad(nRbr,3)||' '||rpad(MAG.ORG_DEO,5)||' '||to_char(mag.datum_dok,'dd.mm.yy'));
       GenerisiStanjeZalNaDan (MAG.ORG_DEO, mag.datum_dok);
       commit;
    END LOOP;



END;
