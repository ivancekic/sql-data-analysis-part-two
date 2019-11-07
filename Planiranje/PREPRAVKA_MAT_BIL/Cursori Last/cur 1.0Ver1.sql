				Select plan.PLAN_CIKLUS_ID, plan.PLAN_CIKLUS_NAZIV
				     , plan.PLAN_TIP_ID, plan.PLAN_TIP_NAZIV
				     , plan.PLAN_PERIOD_ID, plan.PLAN_PERIOD_NAZIV
				     , plan.PLAN_TRAJANJE_ID, plan.PLAN_TRAJANJE_DATUM_OD, plan.PLAN_TRAJANJE_DATUM_DO
				     , plan.BROJ_DOK
				     , plan.ORG_DEO_ID, plan.ORG_DEO_NAZIV, plan.BROJ_DOK1
				     , plan.OPIS_PLAN, plan.STATUS_PLAN, plan.STATUS_PLAN_NAZIV
				     , plan.VARIJANTA_ID, plan.STATUS_VARIJANTA_OPIS, plan.STATUS_ID
				     , plan.KREIRAO_USER, plan.KREIRAO_DATUM, plan.OVERIO_USER, plan.OVERIO_DATUM
				     , plan.TIP_PROIZVODA, plan.TIP_PRO_NAZIV
				     , plan.GOTOV_PR_POSGR, plan.GOTOV_PR_POSGR_NAZIV
				     , plan.GOTOV_PR_SIFRA, plan.GOTOV_PR_NAZIV, plan.GOTOV_PR_JM, plan.KOLICINA GOTOV_PR_PLAN_ZELJENA_KOL_SUM
				     , STANJE_ZAL,STANJE_NA_DAN,PROIZVEDENO
					 , case when nvl(plan.KOLICINA,0) != 0 then
					            round(PROIZVEDENO / plan.KOLICINA  * 100, 2)
					   else
					            null
					   end PROIZVEDENO_PROC
					 , round(NVL(PROIZVEDENO,0) - NVL(plan.KOLICINA,0),2) PROIZVEDENO_ODST

				from
				(
					select plzag.PLAN_CIKLUS_ID, plcik.ciklus_naziv PLAN_CIKLUS_NAZIV
					     , plzag.PLAN_TIP_ID, pltip.TIP_NAZIV PLAN_TIP_NAZIV
					     , plzag.PLAN_PERIOD_ID, plper.PERIOD_NAZIV PLAN_PERIOD_NAZIV
					     , plzag.PLAN_TRAJANJE_ID, pltra.DATUM_OD PLAN_TRAJANJE_DATUM_OD, pltra.DATUM_DO PLAN_TRAJANJE_DATUM_DO
					     , plzag.BROJ_DOK
					     , plzag.ORG_DEO_ID, od.naziv ORG_DEO_NAZIV
					     , plzag.BROJ_DOK1
					     , plzag.OPIS OPIS_PLAN
					     , plzag.STATUS_ID STATUS_PLAN, plstat.NAZIV STATUS_PLAN_NAZIV
					     , plvar.VARIJANTA_ID, plvar.OPIS STATUS_VARIJANTA_OPIS, plvar.STATUS_ID

					     , plzag.KREIRAO_USER, plzag.KREIRAO_DATUM
					     , plzag.OVERIO_USER, plzag.OVERIO_DATUM

					     , p.tip_proizvoda, tp.naziv tip_pro_naziv
					     , p.posebna_grupa GOTOV_PR_POSGR, pgr.naziv GOTOV_PR_POSGR_NAZIV

					     , plstav.proizvod GOTOV_PR_SIFRA, p.naziv GOTOV_PR_NAZIV, p.jed_mere GOTOV_PR_JM
					     , plstav.kolicina


					from PLANIRANJE_CIKLUS			plcik
					   , PLANIRANJE_TIP				pltip
					   , PLANIRANJE_PERIOD			plper
					   , PLANIRANJE_TRAJANJE        pltra
					   , organizacioni_deo			od
					   , PLANIRANJE_STATUS			plstat
					   , PLANIRANJE_ZAGLAVLJE		plzag
					   , PLANIRANJE_VARIJANTA       plvar
					   , PLANIRANJE_STAVKA          plstav
					   , proizvod 					p
					   , posebna_grupa				pgr
					   , tip_proizvoda				tp
					where
					      plcik.ciklus_id=plzag.PLAN_CIKLUS_ID

					  and plper.period_id=plzag.PLAN_PERIOD_ID

					  and pltip.tip_id=plzag.PLAN_TIP_ID

					  and pltra.PLAN_CIKLUS_ID=plzag.PLAN_CIKLUS_ID
					  and pltra.PLAN_PERIOD_ID=plzag.PLAN_PERIOD_ID
					  and pltra.TRAJANJE_ID=plzag.PLAN_TRAJANJE_ID

					  and od.id=plzag.org_deo_id

					  and pltip.tip_id=plstat.PLAN_TIP_ID
					  and plstat.STATUS_ID=plzag.status_id

					  and pltip.tip_id=plvar.PLAN_TIP_ID
					  and plcik.ciklus_id=plvar.PLAN_CIKLUS_ID
					  and plper.period_id=plvar.PLAN_PERIOD_ID
					  and pltra.TRAJANJE_ID=plvar.PLAN_TRAJANJE_ID
					  and plzag.broj_dok=plvar.BROJ_DOK

					  and plzag.PLAN_CIKLUS_ID=&p_ciklus_id
					  and plzag.PLAN_TIP_ID=&p_tip_id
					  and plzag.PLAN_PERIOD_ID=&p_period_id
					  and plzag.PLAN_TRAJANJE_ID=&p_trajanje_id
					  and plzag.BROJ_DOK=&p_broj_dok

					  and plcik.ciklus_id=plstav.PLAN_CIKLUS_ID
					  and pltip.tip_id=plstav.PLAN_TIP_ID
					  and plper.period_id=plstav.PLAN_PERIOD_ID
					  and pltra.TRAJANJE_ID=plstav.PLAN_TRAJANJE_ID
					  and plzag.broj_dok=plstav.BROJ_DOK
					  and plvar.VARIJANTA_ID=plstav.VARIJANTA_ID

					  and p.sifra = plstav.proizvod
					  and pgr.grupa = p.posebna_grupa
					  and tp.sifra = p.tip_proizvoda
				) plan
				,
				(
						select
						       d.org_deo
						     , sd.proizvod
						     , p.tip_proizvoda
						   , (select case when pm.vrsta='GOT_PROIZVODI_TIPOVI' then
						                       1
						             Else
						                       2
						             end GpPp_Order_By
						      from Proizvod p1, planiranje_mapiranje pm
						      where p1.sifra = sd.proizvod and p1.tip_proizvoda=pm.vrednost
						        and pm.VRSTA in('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI' )
						     ) GpPp_Order_By

						     , round(Sum(NVL(decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
						                            * case when d.vrsta_dok = '90' then
						                                        0
						                              else
						                                        K_ROBE
						                              end
						                     ,0)
						                 )
						            ,5) STANJE_ZAL
						     , ROUND(sum(case when d.datum_dok <=  nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID= &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id)
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
						                 ELSE
						                     0
						                 End
						                )
						           ,5) STANJE_NA_DAN
				       , Sum( case when d.vrsta_Dok in( '1','26','45','46') Then
				                        Round( Decode( d.Vrsta_Dok || d.Tip_Dok,
					                                                            '314', sd.Kolicina,
					                                                            '414', sd.Kolicina,
					                                                                   sd.Realizovano
					                                 ) * sd.Faktor * sd.K_Robe
					                          , 5 )
--					          else
--					                    null
					          end
					        ) proizvedeno

						from Stavka_dok sd, dokument d
						   , (select p1.*
						           , case when pm.vrsta='GOT_PROIZVODI_TIPOVI' then
						                       1
						             Else
						                       2
						             end GpPp_Order_By
						           , pm.vrednost
						      from Proizvod p1, planiranje_mapiranje pm
						      where p1.tip_proizvoda=pm.vrednost
						        and pm.VRSTA in('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI' )
						     )p
						Where d.broj_dok>0
			 	          and (   d.vrsta_Dok != '2'
			 	               or d.vrsta_Dok != '9'
			 	               or d.vrsta_Dok != '10'
			 	              )
			 	          and d.godina= &p_ciklus_id
						  and d.status > 0
						  and d.org_Deo in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='MAGACINI_PROIZVODI_OK' )
						  and d.datum_dok between to_date('01.01.'||TO_CHAR(SYSDATE,'YYYY'),'dd.mm.yyyy')
						                      and sysdate
						  and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
						  and sd.k_robe != 0
						  and p.sifra=sd.proizvod
						  and sd.proizvod in
											(
													SELECT

															distinct proizvod
													FROM planiranje_stavka plstav
													WHERE plstav.PLAN_CIKLUS_ID= &p_ciklus_id
													  AND plstav.PLAN_TIP_ID= &p_tip_id
													  AND plstav.PLAN_PERIOD_ID= &p_period_id
													  AND plstav.PLAN_TRAJANJE_ID= &p_trajanje_id
													  AND plstav.broj_dok= &p_broj_dok
													  and plstav.varijanta_id= &p_varijanta_id

											)
						Group by d.org_deo, sd.proizvod, p.tip_proizvoda
				) d
			    WHERE plan.GOTOV_PR_SIFRA=D.PROIZVOD
			    Order by plan.TIP_PROIZVODA desc, plan.GOTOV_PR_POSGR, plan.GOTOV_PR_NAZIV
