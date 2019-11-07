   Select * from planiranje_zaglavlje
   where PLAN_TIP_ID = 2
     and PLAN_CIKLUS_ID = 2013
     and (
          ( PLAN_PERIOD_ID = 2 and PLAN_TRAJANJE_ID <= 2 )
          OR
          ( PLAN_PERIOD_ID = 3 and PLAN_TRAJANJE_ID <= 8 )
         )
     and broj_dok > 0
  Order by PLAN_PERIOD_ID, PLAN_TRAJANJE_ID, BROJ_DOK
