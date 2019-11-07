declare

  nTip Number;
  nCiklus Number;
  nPeriod Number;
  nTrajanje Number;
  nBrd Number;

  cArhivaPoruka Varchar2(2000);

  Cursor k1 is
   Select * from planiranje_zaglavlje
   where PLAN_TIP_ID = nTip
     and PLAN_CIKLUS_ID = nCiklus
--     and PLAN_PERIOD_ID = nPeriod
--     and PLAN_TRAJANJE_ID <= nTrajanje
and
(
          ( PLAN_PERIOD_ID = 2 and PLAN_TRAJANJE_ID <= 2 )
          OR
          ( PLAN_PERIOD_ID = 3 and PLAN_TRAJANJE_ID <= 8 )
)
     and broj_dok > 0
     and (PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK)
         not in (select PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK from planiranje_zaglavlje where  PLAN_TIP_ID = nTip and broj_dok < 1 )
  Order by PLAN_TRAJANJE_ID, BROJ_DOK
  ;
  kk1 k1 % rowtype;

begin
---------------------------------------------------------------------------------------------------------------------------------

-- OVAJ DEO JE PREPISAN IZ FORME KOJA JE U RAZRADI

--	planiranje_package.ArhivirajPlan(  :PLAN_ZAGLAVLJE.PLAN_TIP_ID 			-- 2 - prodaja , 3 - proizvodnja
--			                         , :PLAN_ZAGLAVLJE.PLAN_CIKLUS_ID		-- godina
--          			                 , :PLAN_ZAGLAVLJE.PLAN_PERIOD_ID       -- 1 - godisnji, 2 - kvartalni , 3 - mesecni ...
--		                	         , :PLAN_ZAGLAVLJE.PLAN_TRAJANJE_ID     -- rbr za mesecni: 1 - JAN, 2 - FEB ...
--		                        	 , :PLAN_ZAGLAVLJE.BROJ_DOK 			-- redni broj
--	                                 , cArhivaPoruka                        -- poruka o uradjenom
--        			        );
--
---------------------------------------------------------------------------------------------------------------------------------

    nTip := 2;
    nCiklus := 2013;
    nPeriod :=
    2	-- kvartalni
    --3	-- mesecni
    ;
    nTrajanje :=
    2	-- kvartalni
    --8	-- mesecni
    ;

    nBrd :=1;

    Dbms_output.Put_line(   rpad('Tip plana',11) ||' '||
                            rpad('God',4)        ||' '||
                            rpad('Period',10)    ||' '||
                            rpad('Trajanje',10)  ||' '||
                            rpad('Brd',4)
                        );

    Dbms_output.Put_line(   rpad('-',11,'-') ||' '||
                            rpad('-',4,'-')  ||' '||
                            rpad('-',10,'-') ||' '||
                            rpad('-',10,'-') ||' '||
                            rpad('-',4,'-')
                        );


    Open k1;
    loop
    fetch k1 into kk1;
    exit when k1%NotFound;

    Dbms_output.Put_line(   rpad(case when kk1.PLAN_TIP_ID = 1 then ' 1 - ...'
                                      when kk1.PLAN_TIP_ID = 2 then ' 2 - prod'
                                      when kk1.PLAN_TIP_ID = 3 then ' 3 - proizv'

                                 end
                             ,11) ||' '||
                            rpad(to_char(kk1.PLAN_ciklus_ID),4)        ||' '||
                            rpad(case when kk1.PLAN_PERIOD_ID = 1 then ' 1 - god'
                                      when kk1.PLAN_PERIOD_ID = 2 then ' 2 - kvart'
                                      when kk1.PLAN_PERIOD_ID = 3 then ' 3 - mes'
                                      when kk1.PLAN_PERIOD_ID = 4 then ' 4 - ned'
                                      when kk1.PLAN_PERIOD_ID = 5 then ' 5 - dnevni'
                                      when kk1.PLAN_PERIOD_ID = 6 then ' 6 - tromes'
                                 end
                                ,10)    ||' '||
                            rpad(to_char(kk1.PLAN_TRAJANJE_ID),10)  ||' '||
                            rpad(to_char(kk1.broj_dok),4)
                        );

	planiranje_package.ArhivirajPlan(  kk1.PLAN_TIP_ID 			-- 2 - prodaja , 3 - proizvodnja
			                         , kk1.PLAN_ciklus_ID		-- godina
          			                 , kk1.PLAN_PERIOD_ID      	-- 1 - godisnji, 2 - kvartalni , 3 - mesecni ...
		                	         , kk1.PLAN_TRAJANJE_ID	    -- rbr za mesecni: 1 - JAN, 2 - FEB ...
		                        	 , kk1.broj_dok				-- redni broj
	                                 , cArhivaPoruka			-- poruka o uradjenom
        			        );


    Dbms_output.Put_line('Uradjeno je :: ' || cArhivaPoruka);
    If cArhivaPoruka = 'USPESNO STE ARHVIRALI PLAN' then
       commit;
    else
       rollback;
    end if;


    end loop;
    close k1;

--/*
--*/



end;
