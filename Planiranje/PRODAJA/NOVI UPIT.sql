--ORG_DEO	PROIZVOD	TIP_PROIZVODA	UL02	STANJE_ZAL	STANJE_NA_DAN
--139		11471		1				139				66				66
--88		11471		1				88			  4366			  8369
--													  4432			  8435
SELECT
       S.PROIZVOD, TIP_PROIZVODA
     , SUM(STANJE_ZAL)getStanje,SUM(STANJE_NA_DAN) getStanjeNaDan
     , (
		select
				sum(
					 (case --when z.SKLADISNA_JM != p.jed_mere    then z.stanje*p.faktor_prodajne
					       when z.SKLADISNA_JM  = p.prodajna_jm then z.stanje*p.faktor_prodajne
					       when z.SKLADISNA_JM  = p.jed_mere    then z.stanje
					   else z.stanje
					   end
					   )
				   )

		  from INVEJ_ZALIHE_FIRME@CITAJ_KON z
		     , PROIZVOD p
		 where z.firma = (select iz01 from MAPIRANJE
						   where modul='FIRMA' and ul01 = 'FIR')
           and z.SIFRA_FIRMA = &pro
           and z.vrsta = 'PRO'
           and z.sifra_firma = p.sifra (+)
       ) getStanjeINV
     , (

		select
				sum(
					 (case
					       when z.SKLADISNA_JM  = p.prodajna_jm then z.REZERVISANO_SKL*p.faktor_prodajne
					       when z.SKLADISNA_JM  = p.jed_mere    then z.REZERVISANO_SKL
					   else z.REZERVISANO_SKL
					   end
					   )
				   )
		  from INVEJ_ZALIHE_FIRME_REZ@CITAJ_KON z
		     , PROIZVOD p
		 where z.firma = (select iz01 from MAPIRANJE
						 where modul='FIRMA' and ul01 = 'FIR')
           and z.SIFRA_FIRMA = &pro
           and z.datum_dok between
	           nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))

	            and
	            nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
           and z.sifra_firma = p.sifra (+)

       )  getRezervisanoINV
     ,(
		SELECT
		        sum(nvl(d.rezervisano, 0))
		  FROM
			  (
				select d.datum_dok, d.org_deo, sd.proizvod
			     ,nvl(sum(
				      (case when sd.jed_mere = p.prodajna_jm then (sd.kolicina-sd.realizovano)*p.faktor_prodajne
				     		when sd.jed_mere = p.jed_mere    then (sd.kolicina-sd.realizovano)
				       end
			          )
			       ),0) rezervisano
				from DOKUMENT d
				   , STAVKA_DOK sd
				   , PROIZVOD p
				where d.broj_dok = sd.broj_dok
				and d.vrsta_dok  = sd.vrsta_dok
				and d.godina     = sd.godina
		        and sd.proizvod  = p.sifra
				and d.status in (1,3)
				and sd.vrsta_dok = '10'
				and (sd.kolicina-sd.realizovano)>0
		        and d.org_deo in (select to_number(ul02)
								   from mapiranje m
								  where m.modul = 'PLANIRANJE'
								    and m.VRSTA = 'MAGACINI_PROIZVODI_OK'
								 )
				group by  d.datum_dok, sd.proizvod ,d.org_deo
			  ) d
        WHERE d.proizvod = &Pro
          and d.datum_dok between
	           nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))

	            and
	            nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
      ) getRezervisano
    , (
	   Select -1 * round(sum(sd.kolicina * sd.faktor * sd.k_robe),5)
	   From dokument d, stavka_dok sd, proizvod p
	   Where (d.VRSTA_DOK,d.BROJ_DOK,d.GODINA)
	   in (
		    select VRSTA_DOK,BROJ_DOK,GODINA
			from dokument d
			Where (d.vrsta_Dok,d.tip_dok)
			  in  (SELECT vrsta_Dok,tip_dok
			       FROM VR_TIP_DOK_GRUPISANJE
			       WHERE GRUPA_CEGA = 'REALIZACIJA_PRODAJE'
			      )

			union

			Select za_VRSTA_DOK,za_BROJ_DOK,za_GODINA
			From vezni_Dok
			Where (VRSTA_DOK,BROJ_DOK,GODINA)
			   in (select VRSTA_DOK,BROJ_DOK,GODINA
			       from dokument d
			       Where
					      (d.vrsta_Dok,d.tip_dok)
					  in  (SELECT vrsta_Dok,tip_dok
					       FROM VR_TIP_DOK_GRUPISANJE
					       WHERE GRUPA_CEGA = 'REALIZACIJA_PRODAJE'
					      )
			      )
			  and za_vrsta_dok in ('12','13','31')
			)
	   and d.status > 0
           and d.datum_dok between
	           nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))

	            and
	            nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
									                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
									                                                   and PLAN_PERIOD_ID=&p_period_id
									                                                   and TRAJANJE_ID=&p_trajanje_id)
									                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
	   and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
	   and p.sifra = sd.proizvod
	   and sd.k_robe <> '0'
	   and sd.proizvod = &Pro
      )  getRealProdajePeriod
    , (
			Select distinct GOTOV_PR_PLAN_ZELJENA_KOL
			From planiranje_view
			Where plan_ciklus_id	= &p_ciklus_id
			  and plan_period_id	= &p_period_id
			  and plan_trajanje_id	= &p_trajanje_id
			  and plan_tip_id		= '3' -- proizvodnja -- g_tip_id
		--      and broj_dok			= 1 --g_broj_dok
			  and varijanta_id 		= 1 --g_varijanta_id
			  and GOTOV_PR_SIFRA	= &pro
      )      getPlanProizvPeriod

   , (
		Select sum (gpr_zeljena_kol)
		From
			(

				Select sum(pv.GOTOV_PR_PLAN_ZELJENA_KOL) / count(gotov_pr_sifra) gpr_zeljena_kol

				From planiranje_view pv, proizvod p
				Where plan_ciklus_id	= &p_ciklus_id
				  and plan_period_id	= &p_period_id
				  and plan_trajanje_id	= &p_trajanje_id
				  and plan_tip_id		= '3' -- proizvodnja -- g_tip_id
	--		      and broj_dok			= 1 --g_broj_dok
				  and varijanta_id 		= 1 --g_varijanta_id
				  and GOTOV_PR_SIFRA	= p.sifra
				  and p.tip_proizvoda	= TIP_PROIZVODA
--				  AND PV.gotov_pr_sifra = &PRO
				Group by gotov_pr_sifra
		)
     ) getPlanProizvPeriodTipPro

FROM
(
						select
						       d.org_deo
						     , sd.proizvod
						     , p.tip_proizvoda
						     , M.UL02
						     , round(Sum(
                                          Case When instr(PMapiranje.MOJE_MODUL_PODATAK_LISTA ('PLANIRANJE', 'GOT_PROIZVODI_TIPOVI',  0, 9876789, 'U2'), ','||TIP_PROIZVODA||',' ) = 0 Then
							                 case when k_robe != 0 then
								                 NVL(decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
								                            * case when d.vrsta_dok = '90' then
								                                        0
								                              else
								                                        K_ROBE
								                              end
								                     ,0)
--								             else
--								                 0
							                 end
                                          Else
							                 case when k_robe != 0 and m.ul02 is not null then
								                 NVL(decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
								                            * case when d.vrsta_dok = '90' then
								                                        0
								                              else
								                                        K_ROBE
								                              end
								                     ,0)
--								             else
--								                 0
							                 end
                                          End
                                        )
						            ,5) STANJE_ZAL
						     , ROUND(sum(
                                          Case When instr(PMapiranje.MOJE_MODUL_PODATAK_LISTA ('PLANIRANJE', 'GOT_PROIZVODI_TIPOVI',  0, 9876789, 'U2'), ','||TIP_PROIZVODA||',' ) = 0 Then
							                 case when k_robe != 0 then
								                 case when d.datum_dok <=  nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
								                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
								                                                   and PLAN_PERIOD_ID=&p_period_id
								                                                   and TRAJANJE_ID=&p_trajanje_id)
								                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
							                              then
												     NVL(
												           decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
												                     * case when d.vrsta_dok = '90' then
												                                 0
												                       else
												                                 K_ROBE
												                       end

												        ,0)
--								                 ELSE
--								                     0
								                 End
--							                 ELSE
--							                     0
							                 End
                                          else
							                 case when k_robe != 0 and m.ul02 is not null then
								                 case when d.datum_dok <=  nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
								                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
								                                                   and PLAN_PERIOD_ID=&p_period_id
								                                                   and TRAJANJE_ID=&p_trajanje_id)
								                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
							                              then
												     NVL(
												           decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
												                     * case when d.vrsta_dok = '90' then
												                                 0
												                       else
												                                 K_ROBE
												                       end

												        ,0)
--								                 ELSE
--								                     0
								                 End
--							                 ELSE
--							                     0
							                 End

                                          End
						                )
						           ,5) STANJE_NA_DAN



						from Stavka_dok sd, dokument d, Proizvod p
						   , (SELECT m.ul02
						      FROM MAPIRANJE M
                              WHERE  m.modul = 'PLANIRANJE'
                                 and m.VRSTA = 'MAGACINI_PROIZVODI_OK'
                              ) M
						Where d.broj_dok>0
			 	          and d.godina=&p_ciklus_id
						  and d.status > 0
						  and d.datum_dok between to_date('01.01.'||TO_CHAR(&p_ciklus_id),'dd.mm.yyyy')
						                      and sysdate
						  and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
						  and sd.k_robe != 0
						  AND SD.PROIZVOD = &pro
						  and p.sifra=sd.proizvod
						  AND TO_CHAR(D.ORG_DEO) = M.UL02 (+)


						Group by d.org_deo, sd.proizvod, p.tip_proizvoda, M.UL02
) S
GROUP BY PROIZVOD, TIP_PROIZVODA
