select ps.PROIZVOD PRO,ps.JED_MERE JM,ps.PLANSKA_JM PL_JM, ps.FAKTOR_PLANSKE F_PL, ps.DOBAVLJAC, ps.NABAVNA_SIFRA NAB_SIF
     , ps.BROJ_SASTAVNICE BR_SAST
     , ps.KOLICINA KOL
     , ps.OPTIMALNA_ZALIHA OPT_ZAL
     , ps.PLANIRANA_PRODAJA PLAN_PROD
     , pf.DOB,pf.FAB_PRO,pf.FAB_SAST,pf.FAB_KOL,pf.FAB_OPT
from
(
				select PROIZVOD, JED_MERE, PLANSKA_JM, FAKTOR_PLANSKE, DOBAVLJAC, nabavna_sifra
				     , BROJ_SASTAVNICE
				     , sum(KOLICINA_SKL_JM) KOLICINA_SKL_JM
				     , sum(KOLICINA) KOLICINA
				     , sum(OPTIMALNA_ZALIHA_SKL_JM) OPTIMALNA_ZALIHA_SKL_JM
				     , sum(OPTIMALNA_ZALIHA) OPTIMALNA_ZALIHA
				     , sum(PLANIRANA_PRODAJA_SKL_JM) PLANIRANA_PRODAJA_SKL_JM
				     , sum(PLANIRANA_PRODAJA) PLANIRANA_PRODAJA
				from
				(
							Select
							  	   ps.PROIZVOD, p.jed_mere, p.planska_JM, p.faktor_planske
							     , (select dobavljac from katalog_view kv
								    where kv.proizvod = ps.proizvod
								      and (
								              (ps.broj_dok in (2,4) and TIP='T')
								           or (ps.broj_dok not in (2,4) and TIP='K')
								          )
								   )
								   dobavljac
							     , ps.BROJ_SASTAVNICE
				                 , nvl(KOLICINA,0)  							KOLICINA_SKL_JM
				                 , nvl(KOLICINA,0) * faktor_planske 			KOLICINA
				                 , nvl(OPTIMALNA_ZALIHA,0)						OPTIMALNA_ZALIHA_SKL_JM
				                 , nvl(OPTIMALNA_ZALIHA,0) * faktor_planske		OPTIMALNA_ZALIHA
							     , nvl(PLANIRANA_PRODAJA,0)						PLANIRANA_PRODAJA_SKL_JM
							     , nvl(PLANIRANA_PRODAJA,0) * faktor_planske	PLANIRANA_PRODAJA
							     , (select nabavna_sifra from katalog_view kv
								    where kv.proizvod = ps.proizvod
								      and (
								              (ps.broj_dok in (2,4) and TIP='T')
								           or (ps.broj_dok not in (2,4) and TIP='K')
								          )
								   )
								   nabavna_sifra

							From planiranje_stavka ps
						       , proizvod p
							Where
							      ps.plan_tip_id			= &n_tip_id
							  and ps.PLAN_CIKLUS_ID			= &n_ciklus_id
							  and ps.PLAN_period_ID			= &n_period_id
							  and ps.plan_trajanje_id		= &n_trajanje_id
							  and ps.broj_dok				in (1,2)
							  and p.sifra = ps.proizvod
				)
				, (select vrednost from planiranje_mapiranje where vrsta = 'KOPIRANJE_INVEJ_FIRME_DOZVOLJENO') ff
				where dobavljac is not null and NABAVNA_SIFRA is not null
--				  and (
--				           (&cFirma is not null And dobavljac = planiranje_package.Vrati_firma_od_linka(&cFirma) )
--				        or (&cFirma is null     And dobavljac = dobavljac)
--				      )
				  and (
				           (&cFirma is not null And dobavljac = ff.vrednost And dobavljac = planiranje_package.Vrati_firma_od_linka(&cFirma) )
				        or (&cFirma is null     And dobavljac = ff.vrednost )
				      )


				Group by PROIZVOD, JED_MERE, PLANSKA_JM, FAKTOR_PLANSKE,DOBAVLJAC, nabavna_sifra, BROJ_SASTAVNICE
--				Order by to_number(dobavljac) desc, to_number(nabavna_sifra), PROIZVOD;
)ps
,
(
  (
	select '172' dob, PROIZVOD FAB_PRO, BROJ_SASTAVNICE FAB_SAST,KOLICINA FAB_KOL, OPTIMALNA_ZALIHA FAB_OPT
	from planiranje_stavka@albus pf
	where
	      pf.plan_tip_id			= &n_tip_id
	  and pf.PLAN_CIKLUS_ID			= &n_ciklus_id
	  and pf.PLAN_period_ID			= &n_period_id
	  and pf.plan_trajanje_id		= &n_trajanje_id
  )
  union
  (
	select '342' dob, PROIZVOD FAB_PRO, BROJ_SASTAVNICE FAB_SAST,KOLICINA FAB_KOL, OPTIMALNA_ZALIHA FAB_OPT
	from planiranje_stavka@vital pf
	where
	      pf.plan_tip_id			= &n_tip_id
	  and pf.PLAN_CIKLUS_ID			= &n_ciklus_id
	  and pf.PLAN_period_ID			= &n_period_id
	  and pf.plan_trajanje_id		= &n_trajanje_id
  )
  union
  (
	select '1226' dob, PROIZVOD FAB_PRO, BROJ_SASTAVNICE FAB_SAST,KOLICINA FAB_KOL, OPTIMALNA_ZALIHA FAB_OPT
	from planiranje_stavka@medela pf
	where
	      pf.plan_tip_id			= &n_tip_id
	  and pf.PLAN_CIKLUS_ID			= &n_ciklus_id
	  and pf.PLAN_period_ID			= &n_period_id
	  and pf.plan_trajanje_id		= &n_trajanje_id
  )
  union
  (
	select '965' dob, PROIZVOD FAB_PRO, BROJ_SASTAVNICE FAB_SAST,KOLICINA FAB_KOL, OPTIMALNA_ZALIHA FAB_OPT
	from planiranje_stavka@sunce pf
	where
	      pf.plan_tip_id			= &n_tip_id
	  and pf.PLAN_CIKLUS_ID			= &n_ciklus_id
	  and pf.PLAN_period_ID			= &n_period_id
	  and pf.plan_trajanje_id		= &n_trajanje_id
  )
) pf

where ps.nabavna_sifra = pf.FAB_PRO (+)
--  and ( ps.KOLICINA <> FAB_KOL
--        or
--        ps.OPTIMALNA_ZALIHA <> FAB_OPT
--      )
Order by to_number(dobavljac) desc, to_number(nabavna_sifra), ps.PROIZVOD
