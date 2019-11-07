select
       PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_CIKLUS_GODINA,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,VARIJANTA_ID,DAT_OD,DAT_DO,BROJ_DOK,ORG_DEO_ID
     , MATERIJAL_SIFRA
     , POT_KOL_GOD
     , POT_KOL,STANJE_NA,OCEK,OSTALI_PLAN,MIN_NAB,STANJE,KOL_SIGNALNA
     , PLAN_NAB,PLAN_NAB*ZAD_NAB pot_nov, nabavljeno, nabavljeno - PLAN_NAB odstupanje, round((nabavljeno / PLAN_NAB) * 100,2) ost_proc
     , round(POT_KOL * zad_nab,2) plan_tro
     , br_rad_dana

     , KOL_MIN,KOL_MAX,KOL_OPT,DANA_NABAVKA,K_RIZIKA,ZAD_NAB, nabavljeno

     , ' ' RAZMAK_PRORACUNI_KOL
     , ROUND(POT_KOL_GOD / BR_RAD_DANA,2)											Dnevne_pot
     , ROUND((POT_KOL_GOD / BR_RAD_DANA) * DANA_NABAVKA,2)							Zmin	-- KOL_MINIMALNA
     , ROUND((POT_KOL_GOD / BR_RAD_DANA) * DANA_NABAVKA * K_RIZIKA,2)				Zsigm	-- KOL_SIGURONOSNA
     , ROUND((POT_KOL_GOD / BR_RAD_DANA) * DANA_NABAVKA * (1 + K_RIZIKA),2)			Zstand	-- KOL_STANDARDNA
     , ROUND((POT_KOL_GOD / BR_RAD_DANA) * DANA_NABAVKA * (1 + K_RIZIKA),2)			Zsign	-- KOL_SIGNALNE


From
(
	select pl.PLAN_TIP_ID, pl.PLAN_CIKLUS_ID, pl.PLAN_CIKLUS_GODINA, pl.PLAN_PERIOD_ID, pl.PLAN_TRAJANJE_ID
	     , pl.VARIJANTA_ID,pl.DAT_OD, pl.DAT_DO, pl.BROJ_DOK, pl.ORG_DEO_ID, pl.MATERIJAL_SIFRA
	     , pl.POT_KOL_GOD
	     --         E,            F,       G,              H
	     , pl.POT_KOL, pl.STANJE_NA, pl.OCEK, pl.OSTALI_PLAN

	     , (pl.POT_KOL + pl.OSTALI_PLAN)-(pl.STANJE_NA + pl.OCEK) MIN_NAB

		 ,
		  (
			   select sum(stanje)
	           From zalihe z
	           where z.proizvod = pl.MATERIJAL_SIFRA
	             and z.org_deo in
	                             (
									    select
									      distinct podm.magacin_id
									      from zalihe z
									         , planiranje_org_deo_magacin podm
									     where podm.magacin_id  = z.org_deo
									       and z.proizvod       = pl.MATERIJAL_SIFRA
									       and podm.org_deo_id  = pl.ORG_DEO_ID
	                             )
		   ) stanje
	     , pod.kol_signalna -- L
	     , pl.POT_KOL + pod.kol_signalna - pl.STANJE_NA plan_nab
	     , pod.kol_min, pod.kol_max, pod.kol_opt, pod.dana_nabavka, pod.k_rizika
	     , vratizadnjunabavnu(pl.materijal_sifra) zad_nab
	     , nvl(
			     (
						Select Sum( Round( Decode( d.Vrsta_Dok || d.Tip_Dok,
						                          '314', sd.Kolicina,
						                          '414', sd.Kolicina,
						            sd.Realizovano ) * sd.Faktor * sd.K_Robe, 5 ) )
						From dokument d, stavka_dok sd

						Where D.GODINA = pl.PLAN_CIKLUS_GODINA
						  and d.status > 0
						  and nvl(d.ppartner,'2') <> '2'
						  and d.vrsta_Dok in ('3','4','5','30')
						  and d.datum_dok between dat_od and dat_do
						  and d.ORG_DEO
						      in (Select pom.MAGACIN_ID
						      	  From PLANIRANJE_VIEW plv3, PLANIRANJE_ORG_DEO_MAGACIN pom
								  Where plv3.PLAN_TIP_ID      = pl.PLAN_TIP_ID
							        and plv3.PLAN_CIKLUS_ID   = pl.PLAN_CIKLUS_ID
							        and plv3.PLAN_PERIOD_ID   = pl.PLAN_PERIOD_ID
							        and plv3.PLAN_TRAJANJE_ID = pl.PLAN_TRAJANJE_ID
							        and plv3.ORG_DEO_ID   = pom.ORG_DEO_ID
							        and plv3.MATERIJAL_SIFRA  = pl.materijal_sifra
					       )
						  and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
						  and sd.proizvod = pl.materijal_sifra
						  and k_robe != '0'
					)
      	     ,0) nabavljeno
			 ,(
				  select m.ul02 from  mapiranje m
				  where m.modul = 'MAGACIN'
				    and m.VRSTA =  'BROJ RADNIH DANA'
			  ) br_rad_dana
	from
	(
		Select PLAN_TIP_ID
		     , PLAN_CIKLUS_ID,PLAN_CIKLUS_GODINA,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID
		     , PLAN_TRAJANJE_DATUM_OD dat_od, PLAN_TRAJANJE_DATUM_Do dat_do
		     , ORG_DEO_ID, materijal_sifra
		     ,
		       (
					Select round(sum(pv1.MATERIJAL_PLAN_POTREBNA_KOL),2) pot_kol
					From planiranje_view pv1
					Where pv1.PLAN_TIP_ID        = 3
						and pv1.PLAN_CIKLUS_ID   = pv.PLAN_CIKLUS_ID
						and pv1.PLAN_PERIOD_ID   = 1
						and pv1.PLAN_TRAJANJE_ID = 1
						and pv1.VARIJANTA_ID     = 1
						and pv1.materijal_sifra  = pv.materijal_sifra
	           ) pot_kol_god
		     , round(sum(MATERIJAL_PLAN_POTREBNA_KOL),2) pot_kol
			 ,
		       (
					select sum(stanje)
					from ZAL_GOD_MAG_DAT z
					where z.mag
							    in (Select pom.MAGACIN_ID
									From PLANIRANJE_VIEW plv2, PLANIRANJE_ORG_DEO_MAGACIN pom
									Where plv2.PLAN_TIP_ID      = pv.PLAN_TIP_ID
									  and plv2.PLAN_CIKLUS_ID   = pv.PLAN_CIKLUS_GODINA
									  and plv2.PLAN_PERIOD_ID   = pv.PLAN_PERIOD_ID
									  and plv2.PLAN_TRAJANJE_ID = pv.PLAN_TRAJANJE_ID
									  and plv2.ORG_DEO_ID		= pom.ORG_DEO_ID
									  and MATERIJAL_SIFRA 		= pv.materijal_sifra
							       )
					  and z.pro =  pv.materijal_sifra
					  and z.na_dat = PLAN_TRAJANJE_DATUM_OD
					  and z.god = to_char(pv.PLAN_TRAJANJE_DATUM_OD,'yyyy')
					  and  nvl(STANJE,'0') >= '0'
		        ) stanje_na
		     ,nvl(
				     (
					 select sum(sd.kolicina-sd.realizovano) ocekivano
				       from dokument d
				          , stavka_dok sd
					  where

					        d.vrsta_dok ='2'
					    and d.status in ('0','1','3')
				        and d.datum_dok between  pv.PLAN_TRAJANJE_DATUM_OD and pv.PLAN_TRAJANJE_DATUM_Do
				        and d.broj_dok  = sd.broj_dok and d.vrsta_dok = sd.vrsta_dok and d.godina    = sd.godina
					    and proizvod= pv.materijal_sifra
				        and (sd.kolicina-sd.realizovano)>0
				      )
				 ,0)     ocek
			 ,nvl(
					   (
							Select round(sum(pv1.materijal_plan_potrebna_kol),2)
							From planiranje_view pv1
							where pv1.PLAN_TIP_ID      = pv.PLAN_TIP_ID
							  and pv1.PLAN_CIKLUS_ID   = pv.PLAN_CIKLUS_ID
							  and pv1.PLAN_PERIOD_ID   = pv.PLAN_PERIOD_ID
							  and pv1.PLAN_TRAJANJE_ID = pv.PLAN_TRAJANJE_ID
							  and pv1.broj_dok
							            NOT IN (
													SELECT BROJ_DOK
													FROM planiranje_view pv2
													where pv2.PLAN_TIP_ID		= pv1.PLAN_TIP_ID
													  and pv2.PLAN_CIKLUS_ID	= pv1.PLAN_CIKLUS_ID
													  and pv2.PLAN_PERIOD_ID	= pv1.PLAN_PERIOD_ID
													  and pv2.PLAN_TRAJANJE_ID	= pv1.PLAN_TRAJANJE_ID
													  and pv2.BROJ_DOK			= pv1.BROJ_DOK
													  and pv2.materijal_sifra	= pv1.materijal_sifra

							                   )
							  and pv1.materijal_sifra = pv.materijal_sifra
				  	   )
			      ,0) ostali_plan
		From planiranje_view pv
		where pv.PLAN_TIP_ID      = 3
		  and pv.PLAN_CIKLUS_ID   = 2011
		  and pv.PLAN_PERIOD_ID   = 3
		  and pv.PLAN_TRAJANJE_ID = 1
		  and pv.VARIJANTA_ID = 1
--		  AND pv.STATUS_PLAN = 1
	 	  and materijal_sifra = 10115--10128

		Group by PLAN_TIP_ID, PLAN_CIKLUS_ID,PLAN_CIKLUS_GODINA,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID
		       , PLAN_TRAJANJE_DATUM_OD, PLAN_TRAJANJE_DATUM_DO
		       , ORG_DEO_ID, materijal_sifra
	) pl
	,
	(
	  Select *
	  From PROIZVOD_PODACI
	) POD

	where pl.materijal_sifra = pod.proizvod (+)
)
