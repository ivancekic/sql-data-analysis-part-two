DECLARE

	 dDatStart Date := to_date('01.01.2012','dd.mm.yyyy');

	 cursor dat_cur is
	    select dDatStart dat from dual;
	 dat dat_cur % rowtype;
	 dat1 Date;

     CURSOR k0_Cur(dDat date) is
		select GOD,MAG,DAT_PS,UK_DOK,MES,PROIZVOD,NA_DAT
		     , PROMET_NA_DAN +
		       case when DAT_PS = D3.na_dat then
		                 0
		       else
			        nvl(
						(
			                select STANJE from ZAL_GOD_MAG_DAT_N z
			                where z.god=D3.GOD and z.mag=d3.MAG and z.pro=D3.proIZVOD
			                  and z.NA_DAT = (select max(z1.na_dat) from ZAL_GOD_MAG_DAT_N z1
			                                  where z1.god=D3.GOD and z1.mag=d3.MAG and z1.pro=D3.proIZVOD
			                                    and z1.na_dat < d3.na_dat
			                                 )
						)
			        ,0)
		       end  stanje_na_dan
		from
		(
			select GOD,MAG,DAT_PS,UK_DOK,MES,PROIZVOD,NA_DAT, sum(PROMET_NA_DAN) PROMET_NA_DAN
			from
			(
				select god, mag, dat_ps, uk_dok, MES, proizvod, na_dat, PROMET_NA_DAN
				from
				(
					select d.GODINA god,d.MAG,d.DAT_PS,d.UK_DOK,d.MES,d.datum_dok na_dat,sd.proizvod
									     , round(sum(
									                 ( case when D.Vrsta_Dok ||','||D.Tip_Dok in ('3,14','4,14') then
									                      sd.kolicina
									                   else
									                      sd.realizovano
									                   end
									                 )
									                 * K_ROBE * sd.faktor
									                )
									             ,5
									            )																						PROMET_NA_DAN
					from
					(
						SELECT
						       d.godina, d.vrsta_Dok, d.broj_dok, d.status, MAG, DAT_PS, 0 UK_DOK, TO_CHAR(datum_dok,'MM') MES, d.datum_dok, d.tip_dok
						FROM
						  dokument d
						,
						(
						  (Select org_deo mag, max(d1.datum_dok) dat_ps
						   from dokument d1
						   Where d1.Org_Deo = nvl(&nOrgDeo,d1.Org_deo) and d1.vrsta_dok = '21'
						     and d1.godina = &nGod and d1.status = 1
						   Group by d1.Org_deo
						  )
						        UNION
						  (Select ID mag, TO_DATE('01.01.'||to_char(&nGod),'dd.mm.yyyy') dat_ps
						   from Organizacioni_deo od
						   Where ID > 0
						     AND id = nvl(&nOrgDeo,od.id)
						     and tip = 'MAG'
						     AND ID NOT IN (
					                          Select org_deo
					                          from dokument d1
					                          Where d1.Org_Deo = nvl(&nOrgDeo,d1.Org_deo) and d1.vrsta_dok = '21'
					                            and d1.godina = &nGod and d1.status = 1
					                         Group by d1.Org_deo
						                  )
						  )
						) ps
						where d.org_deo=ps.mag
						  And d.godina = &nGod and d.Org_Deo = nvl(&nOrgDeo,d.Org_deo) And d.Status > 0
		                  And d.org_Deo=ps.mag
		                  And d.status > 0
					) d
					, stavka_dok sd
					where d.Broj_Dok = sd.Broj_Dok And d.Vrsta_Dok = sd.Vrsta_Dok And d.Godina = sd.Godina
					  AND K_ROBE != 0
					Group by d.GODINA,d.MAG,d.DAT_PS,d.UK_DOK,d.MES,d.datum_dok,d.tip_dok, sd.proizvod
				)
			)
			group by GOD,MAG,DAT_PS,UK_DOK,MES,PROIZVOD,NA_DAT
		) d3
		WHERE
		      na_dat = dDat
		  and mag=157    
		ORDER BY TO_NUMBER(proizvod),mag,na_dat;
	k0 k0_Cur % rowtype;
	cPoruka Varchar2(1000);
BEGIN
 Dbms_output.Put_line('Datumi');
 Dbms_output.Put_line('----------');
 WHILE dDatStart < to_date('03.04.2012','dd.mm.yyyy')--sysdate
 loop
   Open dat_cur;
   Fetch dat_cur into dat;

	   Dbms_output.Put_line(        lpad('god.',4)
	                         ||' '||lpad('mag',5)
	                         ||' '||lpad('dat ps',8)
	                         ||' '||lpad('mes',3)
	                         ||' '||lpad('pro',8)
	                         ||' '||lpad('na dat',8)
	                         ||' '||lpad('stanje',10)
	                         );

	    Open k0_Cur(dat.dat);
	    Loop
	    Fetch k0_Cur into k0;
	    Exit When k0_Cur % NotFound;

--          if k0_Cur % NotFound then
--		   cPoruka:=(        'nema prometa za datum '|| to_char(&dDatN,'dd.mm.yy') );
--
--          else
		   cPoruka:=(        'ima prometa za datum '|| to_char(&dDatN,'dd.mm.yy') );
		   Dbms_output.Put_line(        lpad(to_char(k0.god),4)
		                         ||' '||lpad(to_char(k0.mag),5)
		                         ||' '||lpad(to_char(k0.dat_ps,'dd.mm.yy'),8)
		                         ||' '||lpad(k0.mes,3)
		                         ||' '||lpad(k0.proizvod,8)
		                         ||' '||lpad(to_char(k0.na_dat,'dd.mm.yy'),8)
		                         ||' '||lpad(k0.stanje_na_dan,10)
		                         );

		    Insert  into ZAL_GOD_MAG_DAT_N
		          values (k0.GOD,k0.MAG,k0.DAT_PS,k0.UK_DOK,k0.MES,k0.PROIZVOD,k0.NA_DAT,k0.STANJE_NA_DAN);
            commit;
--          end if;
	    End Loop;
	    Close k0_Cur;

	    Dbms_output.Put_line(        cPoruka ) ;
   Close dat_cur;
   dDatStart := dDatStart + 1;
 end loop;


END;
