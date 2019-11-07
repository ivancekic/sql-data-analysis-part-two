Select ps.rowid, PS.*
   , (Select polje9 From deja_pomocna_tab
      Where polje79='4000'
        and polje1=ps.proizvod
     ) opt


     , d.polje1, d.polje2, d.polje3, d.polje4, d.polje5, d.polje6, d.polje7, d.polje8, POLJE9
     , KV.*
From planiranje_STAVKA ps
   , (Select * From deja_pomocna_tab
      Where polje79='4000'
     ) d

  , (Select k.firma, f.kratak_naziv, k.dobavljac, k.proizvod
     From katalog_view K, firme f Where f.id=k.firma
     Group by k.firma, k.dobavljac, k.proizvod,f.kratak_naziv
    ) kv

Where
      ps.plan_tip_id			= &c_tip_id
  and ps.PLAN_CIKLUS_ID			= &c_ciklus_id
  and ps.PLAN_period_ID			= &c_period_id
  and ps.plan_trajanje_id		= &c_trajanje_id
  and ps.broj_dok				in (&c_broj_dok1)

  and ps.proizvod = d.polje6

  AND TO_CHAR(KV.dobavljac) = 965

  AND PS.PROIZVOD = KV.PROIZVOD
ORDER BY TO_NUMBER(PS.PROIZVOD)
