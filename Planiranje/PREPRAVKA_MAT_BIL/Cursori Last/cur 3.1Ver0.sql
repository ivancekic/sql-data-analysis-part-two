-- podaci za MATERIJALE sta treba utrositi i sta je utroseno

-- Rubin 216 rec.: Vreme 13.203 s / 3.625 - 4.047 s
-- Monus 365 rec.: Vreme 12.375 s / 6.328 - 8.672 s
			select
			      MGP.VREDNOST GP_TIP,
			      MPP.VREDNOST PP_TIP,

				  plan.MATERIJAL_TIP
				, plan.MATERIJAL_SIFRA
				, plan.MATERIJAL_NAZIV
				, round(plan.MATERIJAL_KOL_SUM,5) MATERIJAL_KOL_SUM
				, plan.MATERIJAL_JED_MERE
				, plan.MATERIJAL_ZADNJA_NABAVNA_CENA
				, plan.MATERIJAL_POSGR
				, pg.naziv		MATERIJAL_POSGR_NAZIV
				, nabavljeno
				, round(stanje_zal,5) STANJE_ZAL
				, round(stanje_na_dan,5) STANJE_NA_DAN
				, kon.PRO_SIFRA_FIRMA
				, round(kon.PRO_INV_STANJE_NA_DAN,5) PRO_INV_STANJE_NA_DAN
				, round(kontrola.kontrola_stanje,5) KONTROLA_STANJE
				, round(kon1.PRO_INV_STANJE,5) PRO_INV_STANJE
				, round(kotrola_inv.kontrola_inv_stanje,5) KONTROLA_INV_STANJE
				, round(inv_ocek,5) INV_OCEK
				, round(treb.kol_treb,5) KOL_TREB
				, round(Pro_Pod.KOL_SIGNALNA,5) KOL_SIGNALNA
				, round(OCEK,5) OCEK
				, round(OCEK_INV,5) OCEK_INV

			    , round(
			      CASE WHEN trunc(sysdate) - trunc( nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID=  &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id )
					                             ,to_date('01.01.0001','dd.mm.yyyy'))) > 0 THEN
			                NULL
			      ELSE
			                case when MATERIJAL_KOL_SUM + NVL(OST_PLAN_materijal_kol_sum,0) - NVL(stanje_na_dan,0) + NVL(PRO_INV_STANJE_NA_DAN,0) > 0
			                          then
			                               MATERIJAL_KOL_SUM + NVL(OST_PLAN_materijal_kol_sum,0) - NVL(stanje_na_dan,0) + NVL(PRO_INV_STANJE_NA_DAN,0)
			                else
			                               null
			                END
			      end,5) za_nabavku

			    , round(
			      CASE WHEN trunc(sysdate) - trunc( nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID=  &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id )
					                             ,to_date('01.01.0001','dd.mm.yyyy'))) > 0 THEN
			                NULL
			           ELSE

			                CASE WHEN NVL(Pro_Pod.KOL_SIGNALNA,0) - stanje_zal > 0 THEN
			                     Pro_Pod.KOL_SIGNALNA - stanje_zal + NVL(OCEK,0) + NVL(PRO_INV_STANJE,0) + NVL(OCEK_INV,0)
			                ELSE
			                     NULL
			                END
			       END,5)         HITNA_NAB

			    , round(
			      CASE WHEN trunc(sysdate) - trunc( nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID=  &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id )
					                             ,to_date('01.01.0001','dd.mm.yyyy'))) > 0 THEN
			                NULL
			      ELSE
					        case when  materijal_kol_sum  + nvl(OST_PLAN_materijal_kol_sum,0) + nvl(KOL_SIGNALNA,0)
					           -
					           ( nvl(stanje_na_dan,0) + nvl(PRO_INV_STANJE_NA_DAN,0) )  > 0
					                 then

					                 materijal_kol_sum  + nvl(OST_PLAN_materijal_kol_sum,0) + nvl(KOL_SIGNALNA,0)
					           -
					           ( nvl(stanje_na_dan,0) + nvl(PRO_INV_STANJE_NA_DAN,0) )
					         else
					                null
					         END
			      end,5)           PLAN_NABAVKE

			    , round((select ZAD_NAB_CENA_DOK_VRED from proizvod where sifra = plan.MATERIJAL_SIFRA),4) zadnja_nabavna_cena

			    , round(
			      CASE WHEN materijal_kol_sum  + nvl(KOL_SIGNALNA,0) - ( nvl(stanje_na_dan,0) + nvl(PRO_INV_STANJE_NA_DAN,0) ) <> 0 THEN
			                round(
			                          nabavljeno / (materijal_kol_sum  + nvl(KOL_SIGNALNA,0) - ( nvl(stanje_na_dan,0) + nvl(PRO_INV_STANJE_NA_DAN,0) )
			                ) * 100 , 2)  + 1
			      ELSE
			                 NULL
			      END,5) PLAN_NABAVKE_ODST_PROC
			    , round(OST_PLAN_materijal_kol_sum,5) OST_PLAN_materijal_kol_sum
			    , trunc(sysdate) - trunc( nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID=  &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id )
					                             ,to_date('01.01.0001','dd.mm.yyyy')))  plan_view_status
			from
			(
				 select
				        /*+ INDEX(planiranje_stavka planir_s_pk) */
				        materijal_tip
				      , materijal_sifra
				      , materijal_naziv
				      , sum(materijal_plan_potrebna_kol) materijal_kol_sum
				      , materijal_jed_mere
				      , materijal_zadnja_nabavna_cena
					  , MATERIJAL_POSGR
					  ---------------------------------------------------------------------------------------------------
					 from planiranje_view
					where
				           plan_tip_id         = &p_tip_id
				      and  plan_ciklus_id      =  &p_ciklus_id
				      and  plan_period_id      = &p_period_id
				      and  plan_trajanje_id    = &p_trajanje_id
				      and  broj_dok   = &p_broj_dok
					  and  varijanta_id     = &p_varijanta_id
				 	  --**********************************************************************************************************************************--
				 	  --**********************************************************************************************************************************--

					  and  status_stavka       = 1
			          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
			                                     FROM PLANIRANJE_MAPIRANJE
			                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
			                                    )
				 group by
				          materijal_tip
				        , materijal_sifra
				        , materijal_naziv
				        , materijal_jed_mere
				        , materijal_zadnja_nabavna_cena
						, MATERIJAL_POSGR
				 order by
						   MATERIJAL_POSGR
			 		     , materijal_naziv
			) plan

			,(
					SELECT sdp.proizvod

			             , sum(case when dp.vrsta_Dok in( '3','4','5','30') AND
			                             dp.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
			                                              AND nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
			                             And dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
			                             then

			                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
			                                            '3,14', sdp.Kolicina,
			                                            '4,14', sdp.Kolicina,
			                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 )
			                   else
			                             null
			                   end
			                   ) nabavljeno

			             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') then
			                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
			                         else
			                                   null
			                         end)

			                    ,5) STANJE_ZAL

			             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') and
			                                   dP.datum_dok <=  nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
			                                   then
			                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
			                         else
			                                   null
			                         end)

			                    ,5) STANJE_NA_DAN

					FROM dokument dp, stavka_dok sdp
					   , PLANIRANJE_ORG_DEO_MAGACIN PM
					WHERE pm.org_deo_id= (SELECT ORG_DEO_ID FROM PLANIRANJE_ZAGLAVLJE PZ
					                      WHERE PZ.plan_tip_id         = &p_tip_id
					                        and PZ.plan_ciklus_id      =  &p_ciklus_id
									        and PZ.plan_period_id      = &p_period_id
									        and PZ.plan_trajanje_id    = &p_trajanje_id
									        and PZ.broj_dok   = &p_broj_dok
					                     )

					  and pm.magacin_id=dp.org_Deo

			          and dp.broj_dok>0
			          and dp.vrsta_Dok > '0'
			          and dp.GODINA =  &p_ciklus_id
				      and dp.status > 0

				      and dp.datum_dok between to_date('01.01.'|| &p_ciklus_id,'dd.mm.yyyy')
			                               and to_date('31.12.'|| &p_ciklus_id,'dd.mm.yyyy')
			 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
			        and sdp.proizvod in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

			        group by sdp.proizvod
			) d
			,
			(
				select SIFRA_FIRMA PRO_SIFRA_FIRMA, SUM(STANJE) PRO_INV_STANJE_NA_DAN
				from ZAL_GOD_MAG_DAT_INV@CITAJ_KON z
				where z.na_dat = nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
				  and z.god = to_char(nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy')),'yyyy')
				  and nvl(STANJE,'0') >= '0'
				  and z.firma = (select iz01 from MAPIRANJE
								  where modul='FIRMA' and ul01 = 'FIR')
			        and z.sifra_firma in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

			    GROUP BY SIFRA_FIRMA
			) kon
			,
			(select sd.proizvod kontrola_pro, nvl(sum(sd.kolicina*sd.faktor),0)  kontrola_stanje
		       from dokument d
		          , stavka_dok sd
			  where d.broj_dok>0
			    and d.vrsta_dok = '3'
			    and d.godina = to_char(nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy')),'yyyy')
			    and d.broj_dok=sd.broj_dok
			    and d.vrsta_dok=sd.vrsta_dok
			    and d.godina=sd.godina
			    and d.status < 0

		        and d.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
                                              where PLAN_CIKLUS_ID=  &p_ciklus_id
						                        and PLAN_PERIOD_ID= &p_period_id
						                        and TRAJANJE_ID= &p_trajanje_id )
						                    ,to_date('01.01.0001','dd.mm.yyyy'))
		                            and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
                                              where PLAN_CIKLUS_ID=  &p_ciklus_id
                                                and PLAN_PERIOD_ID= &p_period_id
						                        and TRAJANJE_ID= &p_trajanje_id )
						                    ,to_date('01.01.0001','dd.mm.yyyy'))
			        and sd.proizvod in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

		     Group by sd.proizvod
			) kontrola
			,
			(
			    Select SIFRA_FIRMA PRO_SIFRA_FIRMA, sum(stanje)  PRO_INV_STANJE
			    From INVEJ_ZALIHE_FIRME@CITAJ_KON
			    Where firma = (select iz01 from MAPIRANJE
			                   where modul='FIRMA' and ul01 = 'FIR')
			      and vrsta = 'NAB'
			        and sifra_firma in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

			    GROUP BY SIFRA_FIRMA

			) kon1
			,
			(
			    Select SIFRA_FIRMA kontrola_pro, sum(nvl(kontrola,0))  kontrola_inv_stanje
			    From INVEJ_ZALIHE_FIRME_KONTR@CITAJ_KON zo
			    Where zo.firma = (select iz01 from MAPIRANJE
				   			      where modul='FIRMA' and ul01 = 'FIR')
			      and zo.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
                                                   and PLAN_PERIOD_ID= &p_period_id
						                           and TRAJANJE_ID= &p_trajanje_id )
						                      ,to_date('01.01.0001','dd.mm.yyyy'))
                                       and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                           and PLAN_PERIOD_ID= &p_period_id
						                           and TRAJANJE_ID= &p_trajanje_id )
						                           ,to_date('01.01.0001','dd.mm.yyyy'))
			        and zo.sifra_firma in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

			    Group by SIFRA_FIRMA
			) kotrola_inv
			,
			(
				select SIFRA_FIRMA kontrola_pro, sum(nvl(ocekivano,0)) inv_ocek
				  from INVEJ_ZALIHE_FIRME_OCEK@CITAJ_KON zo
				 where zo.firma = (select iz01 from MAPIRANJE
								    where modul='FIRMA' and ul01 = 'FIR')
				  and zo.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
                                                   and PLAN_PERIOD_ID= &p_period_id
                                                   and TRAJANJE_ID= &p_trajanje_id )
                                               ,to_date('01.01.0001','dd.mm.yyyy'))
				                       and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
                                                   and PLAN_PERIOD_ID= &p_period_id
						                           and TRAJANJE_ID= &p_trajanje_id )
						                      ,to_date('01.01.0001','dd.mm.yyyy'))
			        and sifra_firma in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)

			    Group by SIFRA_FIRMA
			) inv_ocek
			,
			(
				 select sd.proizvod, sum(nvl(sd.kolicina*sd.faktor, 0)) kol_treb
			       from dokument d
			          , stavka_dok sd
				  where d.vrsta_dok = '8'
				    and d.status < 0
			        and d.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
                                                  where PLAN_CIKLUS_ID=  &p_ciklus_id
						                            and PLAN_PERIOD_ID= &p_period_id
						                            and TRAJANJE_ID= &p_trajanje_id )
						                        ,to_date('01.01.0001','dd.mm.yyyy'))
			                            and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
                                                  where PLAN_CIKLUS_ID=  &p_ciklus_id
						                            and PLAN_PERIOD_ID= &p_period_id
						                            and TRAJANJE_ID= &p_trajanje_id )
						                            ,to_date('01.01.0001','dd.mm.yyyy'))
			        AND d.broj_dok=sd.broj_dok and d.vrsta_dok=sd.vrsta_dok and d.godina=sd.godina
			        and sd.proizvod in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)
			     group by sd.proizvod
			) treb
			,
			(
			   select *
			   from PROIZVOD_PODACI  P
				where P.VAZI_OD = (SELECT MAX(VAZI_OD)
				                   FROM PROIZVOD_PODACI P1
				                   WHERE P1.Proizvod = P.Proizvod
				                     AND P1.VAZI_OD <= nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
			                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
			                                                   and PLAN_PERIOD_ID= &p_period_id
			                                                   and TRAJANJE_ID= &p_trajanje_id )
		                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
				                   )
			) Pro_Pod
			,
			(
			     select SD.PROIZVOD, nvl(sum(sd.kolicina-sd.realizovano),0) OCEK
			       from dokument d
			          , stavka_dok sd
				  where d.vrsta_dok = '2'
				    and d.status in (1,3)
			        and d.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                          where PLAN_CIKLUS_ID=  &p_ciklus_id
						                            and PLAN_PERIOD_ID= &p_period_id
						                            and TRAJANJE_ID= &p_trajanje_id )
						                            ,to_date('01.01.0001','dd.mm.yyyy'))
			                            and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
						                          where PLAN_CIKLUS_ID=  &p_ciklus_id
						                            and PLAN_PERIOD_ID= &p_period_id
						                            and TRAJANJE_ID= &p_trajanje_id )
						                            ,to_date('01.01.0001','dd.mm.yyyy'))
				    AND d.broj_dok=sd.broj_dok and d.vrsta_dok=sd.vrsta_dok and d.godina=sd.godina
			        and (sd.kolicina-sd.realizovano)>0
			        and sd.proizvod in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)
			     GROUP BY SD.PROIZVOD
			) OCEK
			,
			(
				select zo.SIFRA_FIRMA PRO_SIFRA_FIRMA, SUM(nvl(ocekivano,0)) OCEK_INV
				  from INVEJ_ZALIHE_FIRME_OCEK@CITAJ_KON zo
				 where zo.firma = (select iz01 from MAPIRANJE
								    where modul='FIRMA' and ul01 = 'FIR')

				  and zo.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
                                       and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID=  &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id )
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
			      and zo.SIFRA_FIRMA in
										(
											 select
											        materijal_sifra
												 from planiranje_view
												where
											           plan_tip_id         = &p_tip_id
											      and  plan_ciklus_id      =  &p_ciklus_id
											      and  plan_period_id      = &p_period_id
											      and  plan_trajanje_id    = &p_trajanje_id
											      and  broj_dok   = &p_broj_dok
												  and  varijanta_id     = &p_varijanta_id
												  and  status_stavka       = 1
										          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
										                                     FROM PLANIRANJE_MAPIRANJE
										                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
										                                    )
										     group by materijal_sifra
										)
			     GROUP BY ZO.SIFRA_FIRMA
			) OCEK_INV
			,
			(
				 select
				        /*+ INDEX(planiranje_stavka planir_s_pk) */
				        materijal_tip OST_PLAN_materijal_tip
				      , materijal_sifra OST_PLAN_materijal_sifra
				      , sum(materijal_plan_potrebna_kol) OST_PLAN_materijal_kol_sum
				      , materijal_jed_mere OST_PLAN_materijal_jed_mere
			 		  , MATERIJAL_POSGR OST_PLAN_MATERIJAL_POSGR
					  ---------------------------------------------------------------------------------------------------
					 from planiranje_view
					where
				           plan_tip_id         = &p_tip_id
				      and  plan_ciklus_id      = &p_ciklus_id
				      and  plan_period_id      = &p_period_id
				      and  plan_trajanje_id    = &p_trajanje_id
				      and  broj_dok   != &p_broj_dok
					  and  varijanta_id     = &p_varijanta_id
				 	  --**********************************************************************************************************************************--
				 	  --**********************************************************************************************************************************--

					  and  status_stavka       = 1
			          AND  MATERIJAL_TIP NOT IN (SELECT VREDNOST
			                                     FROM PLANIRANJE_MAPIRANJE
			                                     WHERE VRSTA IN ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
			                                    )
				 group by
				          materijal_tip
				        , materijal_sifra
				        , materijal_naziv
				        , materijal_jed_mere
						, MATERIJAL_POSGR
				 order by
						   MATERIJAL_POSGR
			 		     , materijal_naziv
			)OP
			, posebna_grupa pg
            , (SELECT * FROM PLANIRANJE_MAPIRANJE
               WHERE VRSTA = 'GOT_PROIZVODI_TIPOVI') MGP

            , (SELECT * FROM PLANIRANJE_MAPIRANJE
               WHERE VRSTA = 'POLUPROIZVODI_TIPOVI') MPP

			where plan.MATERIJAL_SIFRA=d.proizvod (+)
			  and plan.MATERIJAL_SIFRA=kon.PRO_SIFRA_FIRMA (+)
			  and plan.MATERIJAL_SIFRA=kontrola.kontrola_pro (+)
			  and plan.MATERIJAL_SIFRA=kon1.PRO_SIFRA_FIRMA (+)
			  and plan.MATERIJAL_SIFRA=kotrola_inv.kontrola_pro (+)
			  and plan.MATERIJAL_SIFRA=inv_ocek.kontrola_pro (+)
			  and plan.MATERIJAL_SIFRA=treb.proizvod (+)
			  and plan.MATERIJAL_SIFRA=Pro_Pod.proizvod (+)
			  and plan.MATERIJAL_SIFRA=OCEK.proizvod (+)
			  and plan.MATERIJAL_SIFRA=OCEK_INV.PRO_SIFRA_FIRMA (+)
              and PLAN.materijal_sifra = OP.OST_PLAN_materijal_sifra(+)

              and pg.grupa = MATERIJAL_POSGR

              AND MATERIJAL_TIP = MGP.VREDNOST (+)
              AND MATERIJAL_TIP = MPP.VREDNOST (+)
			order by
                      NVL(MGP.VREDNOST,0),
                      NVL(MPP.VREDNOST,0),
					  MATERIJAL_POSGR
				    , materijal_naziv
            ;
