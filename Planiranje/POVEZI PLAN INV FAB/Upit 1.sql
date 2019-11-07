Select PS.proizvod
     , ps.BROJ_SASTAVNICE
     , sum(kolicina) kol
     , sum(OPTIMALNA_ZALIHA) opt
     , KV.nabavna_sifra

From planiranje_STAVKA ps

  , (Select k.firma, f.kratak_naziv, k.dobavljac, k.proizvod,k.nabavna_sifra
     From katalog_view K, firme f Where f.id=k.firma AND K.DOBAVLJAC = '172'
     Group by k.firma, k.dobavljac, k.proizvod,f.kratak_naziv, k.nabavna_sifra
    ) kv

Where
      ps.plan_tip_id			= &c_tip_id
  and ps.PLAN_CIKLUS_ID			= &c_ciklus_id
  and ps.PLAN_period_ID			= &c_period_id
  and ps.plan_trajanje_id		= &c_trajanje_id
  and ps.broj_dok				in (&c_broj_dok)

  AND PS.PROIZVOD = KV.PROIZVOD


--  AND ps1.plan_tip_id			= &c_tip_id
--  and ps1.PLAN_CIKLUS_ID			= &c_ciklus_id
--  and ps1.PLAN_period_ID			= &c_period_id
--  and ps1.plan_trajanje_id		= &c_trajanje_id
--  and ps1.broj_dok				in (&c_broj_dok1)
--

  AND KV.DOBAVLJAC='172'
Group by PS.proizvod
       , ps.BROJ_SASTAVNICE
       , KV.nabavna_sifra
       , KV.dobavljac
Order by to_number(KV.dobavljac) desc, to_number(nabavna_sifra), ps.PROIZVOD
