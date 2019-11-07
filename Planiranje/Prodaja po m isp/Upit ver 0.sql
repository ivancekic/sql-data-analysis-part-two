SELECT
        PL.PLAN_TIP_ID, PL.PLAN_CIKLUS_ID, PL.PLAN_PERIOD_ID, PL.PLAN_TRAJANJE_ID
      , PL.BROJ_DOK, PL.ORG_DEO_ID, PL.BROJ_DOK1, PL.OPIS
      , PL.STATUS_ID, PL.KREIRAO_USER, PL.KREIRAO_DATUM, PL.OVERIO_USER, PL.OVERIO_DATUM, PL.GENRN_USER, PL.GENRN_DATUM
      , PL.PARENT_PLAN_TIP_ID, PL.PARENT_PLAN_CIKLUS_ID, PL.PARENT_PLAN_PERIOD_ID, PL.PARENT_PLAN_TRAJANJE_ID, PL.PARENT_BROJ_DOK
      , PL.VARIJANTA_ID, PL.PV_OPIS, PL.PPART, PL.MISP, PL.STAVKA_ID, PL.PROIZVOD, PL.KOLICINA, PL.NAZIV_PRO, PL.JM_PRO
FROM
(
Select pz.PLAN_TIP_ID, pz.PLAN_CIKLUS_ID, pz.PLAN_PERIOD_ID, pz.PLAN_TRAJANJE_ID, pz.BROJ_DOK, pz.ORG_DEO_ID, pz.BROJ_DOK1
     , pz.OPIS, pz.STATUS_ID, pz.KREIRAO_USER, pz.KREIRAO_DATUM, pz.OVERIO_USER, pz.OVERIO_DATUM, pz.GENRN_USER, pz.GENRN_DATUM, pz.PARENT_PLAN_TIP_ID, pz.PARENT_PLAN_CIKLUS_ID, pz.PARENT_PLAN_PERIOD_ID, pz.PARENT_PLAN_TRAJANJE_ID, pz.PARENT_BROJ_DOK
     , pv.VARIJANTA_ID, pv.OPIS PV_OPIS
     , trunc((SUBSTR(PV.VARIJANTA_ID,1,12) - 900000000000)/10000) PPART
     , (SUBSTR(PV.VARIJANTA_ID,1,12) - 900000000000) - 10000 * trunc((SUBSTR(PV.VARIJANTA_ID,1,12) - 900000000000)/10000) MISP
     , ps.stavka_id, ps.proizvod, ps.kolicina
     , p.naziv naziv_pro
     , p.jed_mere JM_pro

from planiranje_zaglavlje pz
   , planiranje_varijanta pv
   , planiranje_stavka ps
   , proizvod p

where pz.PLAN_TIP_ID=&p_tip_id
  and pz.PLAN_CIKLUS_ID=&p_ciklus_id
  and pz.PLAN_PERIOD_ID=&p_period_id
  and pz.PLAN_TRAJANJE_ID=&p_trajanje_id
  and pz.BROJ_DOK=&p_broj_dok


  and pz.PLAN_TIP_ID=pv.PLAN_TIP_ID
  and pz.PLAN_CIKLUS_ID=pv.PLAN_CIKLUS_ID
  and pz.PLAN_PERIOD_ID=pv.PLAN_PERIOD_ID
  and pz.PLAN_TRAJANJE_ID=pv.PLAN_TRAJANJE_ID
  and pz.BROJ_DOK=pv.BROJ_DOK

  and pv.VARIJANTA_ID=nvl(&p_varijanta_id,pv.VARIJANTA_ID)

  and pv.PLAN_TIP_ID=ps.PLAN_TIP_ID
  and pv.PLAN_CIKLUS_ID=ps.PLAN_CIKLUS_ID
  and pv.PLAN_PERIOD_ID=ps.PLAN_PERIOD_ID
  and pv.PLAN_TRAJANJE_ID=ps.PLAN_TRAJANJE_ID
  and pv.BROJ_DOK=ps.BROJ_DOK
  and pv.Varijanta_id=ps.Varijanta_id

  and p.sifra=ps.proizvod
) PL
--Order by  PL.Varijanta_id, PL.stavka_id, PL.proizvod
