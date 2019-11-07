Select *
from PLANIRANJE_ZAGLAVLJE pz
   , PLANIRANJE_VARIJANTA pv
   , PLANIRANJE_STAVKA    ps

where

      pz.PLAN_TIP_ID = 3			-- 2 prodaja, 3 proizvodnja .. iz tabele planiranje_tip
  and pz.PLAN_CIKLUS_ID=2013		-- godina plana
  and pz.PLAN_PERIOD_ID=1			-- 1 godisnji, 2 kvartalni ... iz tabele planiranje_period
  and pz.broj_dok=1

  and pz.PLAN_TIP_ID= pv.PLAN_TIP_ID AND
      pz.PLAN_CIKLUS_ID = pv.PLAN_CIKLUS_ID AND
      pz.PLAN_PERIOD_ID = pv.PLAN_PERIOD_ID AND
      pz.PLAN_TRAJANJE_ID = pv.PLAN_TRAJANJE_ID AND
      pz.BROJ_DOK = pv.BROJ_DOK

  and pv.PLAN_TIP_ID= ps.PLAN_TIP_ID AND
      pv.PLAN_CIKLUS_ID = ps.PLAN_CIKLUS_ID AND
      pv.PLAN_PERIOD_ID = ps.PLAN_PERIOD_ID AND
      pv.PLAN_TRAJANJE_ID = ps.PLAN_TRAJANJE_ID AND
      pv.BROJ_DOK = ps.BROJ_DOK AND
      pv.VARIJANTA_ID = ps.VARIJANTA_ID
