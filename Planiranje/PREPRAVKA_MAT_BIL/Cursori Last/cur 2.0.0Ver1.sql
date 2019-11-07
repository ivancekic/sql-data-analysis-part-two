--PLV.PLAN_CIKLUS_ID,PLV.PLAN_CIKLUS_NAZIV,
--PLV.PLAN_PERIOD_ID,PLV.PLAN_PERIOD_NAZIV,
--PLV.PLAN_TRAJANJE_ID,PLV.PLAN_TRAJANJE_DATUM_OD,PLV.PLAN_TRAJANJE_DATUM_DO,
--PLV.BROJ_DOK,
--PLV.ORG_DEO_ID,PLV.ORG_DEO_NAZIV,
--PLV.BROJ_DOK1,
--PLV.STATUS_PLAN,PLV.OPIS_PLAN,
--PLS.NAZIV STATUS_PLAN_NAZIV,
--PLV.VARIJANTA_ID,PLVA.OPIS STATUS_VARIJANTA_OPIS
--PLV.STATUS_VARIJANTA,

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

from PLANIRANJE_CIKLUS			plcik
   , PLANIRANJE_TIP				pltip
   , PLANIRANJE_PERIOD			plper
   , PLANIRANJE_TRAJANJE        pltra
   , organizacioni_deo			od
   , PLANIRANJE_STATUS			plstat
   , PLANIRANJE_ZAGLAVLJE		plzag
   , PLANIRANJE_VARIJANTA       plvar

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

