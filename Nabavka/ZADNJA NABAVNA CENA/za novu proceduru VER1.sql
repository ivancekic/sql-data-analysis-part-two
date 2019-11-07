Declare

  cOldPro Varchar2(7);
  cZnak Varchar2(7);
  nRbr Number ;
  Cursor vratizadnabcenu_cur is

			select
			       proizvod,NAZIV,ZAD_NAB_CENA_DOK_VRED,ZAD_NAB_CENA_DOK_DAT,PR_MAX_DAT
			     , datum_dok, GODINA,VRSTA_DOK,PPARTNER,RABAT,POREZ,CENA,Z_TROSKOVI
			     , TIP_DOK,CENA1,KOLICINA,PS_CENA1,PS_DATUM_DOK
			from
			(
				select p.SIFRA proizvod ,p.NAZIV,p.ZAD_NAB_CENA_DOK_VRED,p.ZAD_NAB_CENA_DOK_DAT,p.PR_MAX_DAT
				     , pr.GODINA,pr.VRSTA_DOK,pr.PPARTNER,pr.datum_dok
				     , pr.RABAT,pr.POREZ,pr.CENA,pr.Z_TROSKOVI,pr.TIP_DOK,pr.CENA1,pr.KOLICINA

				     , ps.CENA1 ps_cena1, ps.datum_Dok ps_Datum_Dok
				from
				(
					select p.sifra, P.NAZIV
					     , p.ZAD_NAB_CENA_DOK_VRED, p.ZAD_NAB_CENA_DOK_DAT
					     , pr_max_dat
					from proizvod p
					   , (
									Select
									       SD.PROIZVOD, max(d.datum_dok) pr_max_dat
									From dokument d
									   , stavka_dok sd
									   , PROIZVOD P
									Where d.broj_dok> 0
									  and d.godina > 0
									  and ((     d.vrsta_dok = '3' and d.tip_dok  in( 10,16,161, 103,124)
									         and d.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
									        )
									      )

									  and d.status   in (1,5)
					                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
					                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

									  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
									  AND P.SIFRA=SD.PROIZVOD
									  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
					                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
									group by proizvod
					     ) prij_max_dat
					where P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
					                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
					  and prij_max_dat.proizvod (+) = p.sifra
				) p
				,
				(
								Select
								       d.godina, d.vrsta_dok,d.ppartner,
								       SD.PROIZVOD, d.datum_dok
								     , SD.RABAT, SD.POREZ, SD.CENA, Z_TROSKOVI
								     , D.TIP_DOK
								     , CASE WHEN P.TIP_PROIZVODA = 8 THEN
								                 CASE WHEN NVL(Z_TROSKOVI,0) > 0 THEN
								                      ((SD.CENA*SD.KOLICINA)*(1-NVL(SD.RABAT,0)/100) + Z_TROSKOVI) / SD.KOLICINA
								                 ELSE
				                                      (SD.CENA)*(1-NVL(SD.RABAT,0)/100)
				                                 END
				                       ELSE
				                            SD.CENA1
								       END Cena1
								     , SD.KOLICINA
								From dokument d
								   , stavka_dok sd
								   , PROIZVOD P
								Where d.broj_dok> 0
								  and d.godina > 0
								  and (( d.vrsta_dok = '3' and d.tip_dok  in( 10,16,161, 103,124)
								       and d.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
								        )
								      )

								  and d.status   in (1,5)
				                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
				                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

								  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
								  AND P.SIFRA=SD.PROIZVOD
								  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
				                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
				)  pr
				,
				(
								Select
								       SD.PROIZVOD, SD.CENA1, max(d.datum_dok) datum_dok
								From dokument d
								   , stavka_dok sd
								   , PROIZVOD P
								Where d.broj_dok> 0
								  and d.godina > 0
								  and d.vrsta_dok= '21'
								  and d.status   in (1,5)
				                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
				                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

								  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
								  AND P.SIFRA=SD.PROIZVOD
								  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
				                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
				                Group by  SD.PROIZVOD, SD.CENA1
				)  ps
				where pr.proizvod (+) = p.sifra
				  and pr.datum_dok (+)= p.PR_MAX_DAT
				  and ps.proizvod (+) = p.sifra
			) p
			where
			      nvl(ZAD_NAB_CENA_DOK_VRED,0) <> nvl(cena1,nvl(ps_cena1,0))
AND TO_NUMBER(PROIZVOD)< 30
			order by to_number(p.proizvod), nvl(p.datum_dok,p.PS_DATUM_DOK)
--            For Update of ZAD_NAB_CENA_DOK_VRED, ZAD_NAB_CENA_DOK_DAT
			;

  vratizadnabcenu vratizadnabcenu_cur % rowtype;
  nCena Number;
  nCommit Number;
Begin
    nRbr := 1;
    nCommit := 0;
    dbms_output.put_line(rpad('red br',8)||' '||
                         rpad('proizvod',8)||' '||
                         Lpad('cena',10)||' '||
                         Rpad('datum',10)||' '||
                         Rpad('NAZIV',40)
                         ||' '||
                         lpad('ZBNC.DOK',10)||' '||
                         Rpad('ZBNC.DOK.DAT',10)

                         );
    dbms_output.put_line(rpad('-',8,'-')||' '||
                         rpad('-',8,'-')||' '||
                         Lpad('-',10,'-')||' '||
                         Lpad('-',10,'-')||' '||
                         Lpad('-',40,'-')
                         ||' '||
                         Lpad('-',10,'-')||' '||
                         Lpad('-',10,'-')
                         );

    Open vratizadnabcenu_cur;
    LOOP
    -- preuzme podatke , ako postoje
    Fetch vratizadnabcenu_cur Into vratizadnabcenu;
       EXIT WHEN vratizadnabcenu_cur % NOTFOUND ;
     If vratizadnabcenu_cur % NOTFOUND Then  -- ako podaci ne postoji
        nCena := 0;
     Else
        nCena := vratizadnabcenu.Cena1;
     End If;

        If nvl(cOldPro,'AA') <> vratizadnabcenu.proizvod then
--          if nvl(vratizadnabcenu.cena1,nvl(vratizadnabcenu.PS_CENA1,0)) <> 0 then
		       update proizvod
		       set ZAD_NAB_CENA_DOK_VRED =nvl(vratizadnabcenu.cena1,nvl(vratizadnabcenu.PS_CENA1,0))
		         , ZAD_NAB_CENA_DOK_DAT  =nvl(vratizadnabcenu.DATUM_DOK,vratizadnabcenu.PS_DATUM_DOK)
		       where sifra = vratizadnabcenu.proizvod;
               nCommit := nCommit + 1;
dbms_output.put_line('comm pro :: ' || vratizadnabcenu.proizvod ||' nComm:: '||nCommit);
--          end if;

           if nCommit = 101 then
--              commit;
              nCommit := 1;
           end If;
        End If;
           cOldPro := vratizadnabcenu.proizvod;
    end loop;
    Close vratizadnabcenu_cur ;            -- zatvara kursor

--    if nCommit > 0 then
--              commit;
--    end If;

END;
