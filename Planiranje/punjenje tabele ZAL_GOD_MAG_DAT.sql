DECLARE
 dDatStart Date := to_date('07.02.2011','dd.mm.yyyy');

 cursor dat_cur is
    select dDatStart dat from dual;
 dat dat_cur % rowtype;

BEGIN

 Dbms_output.Put_line('Datumi');
 Dbms_output.Put_line('----------');
 WHILE dDatStart < sysdate
 loop
   Open dat_cur;
   Fetch dat_cur into dat;
   Dbms_output.Put_line(to_char(dat.dat,'dd.mm.yyyy hh24:mi:ss')
   || ' sys date trunc ' || to_char(TRUNC(sysdate))
   );

   GenerisiStanjeZalNaDan(null,dat.dat);
   commit;

   Close dat_cur;
   dDatStart := dDatStart + 1;
 end loop;
--SELECT DISTINCT NA_DAT
--FROM ZAL_GOD_MAG_DAT
--WHERE NA_DAT >= TO_DATE('01.01.2011')

END;
