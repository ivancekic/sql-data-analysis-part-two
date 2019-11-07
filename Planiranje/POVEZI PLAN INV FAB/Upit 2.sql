
--SELECT PROIZVOD, COUNT(*)
--FROM
--(
Select

--       PROIZVOD,BROJ_SASTAVNICE,KOLICINA,KOMENTAR,STATUS_ID,OPTIMALNA_ZALIHA
--     , REALIZOVANA_PROIZVODNJA,PLANIRANA_PRODAJA,PLANIRANA_POTROSNJA,PREDVIDJENO_STANJE,KORISNIK,DATUM
--       &n_tip_id PLAN_TIP_ID, &n_ciklus_id PLAN_CIKLUS_ID, &n_period_id PLAN_PERIOD_ID, &n_trajanje_id PLAN_TRAJANJE_ID
--       , 1 BROJ_DOK, 1 VARIJANTA_ID, 1 STAVKA_ID

--  	,   ps.PROIZVOD, p.jed_mere, p.planska_JM, p.faktor_planske
--     , k.dobavljac
--     ,
       k.nabavna_sifra
     , ps.BROJ_SASTAVNICE
--     , SUM(nvl(KOLICINA,0)) KOLICINA_SKL_JM
     , SUM(nvl(KOLICINA,0) * faktor_planske)				 KOLICINA
     , 0 status
--     , SUM(nvl(OPTIMALNA_ZALIHA,0))							 OPTIMALNA_ZALIHA_SKL_JM
     , SUM(nvl(OPTIMALNA_ZALIHA,0) * faktor_planske)		 OPTIMALNA_ZALIHA
--     , SUM(nvl(PLANIRANA_PRODAJA,0))						 PLANIRANA_PRODAJA_SKL_JM
     , SUM(nvl(PLANIRANA_PRODAJA,0) * faktor_planske)		 PLANIRANA_PRODAJA

--     , 'INVEJ' KORISNIK
--     , '28.10.2011 15:44:35' DATUM
--     , PS.PROIZVOD
From planiranje_stavka ps
    , proizvod p
	,
	(
      Select k.firma, f.kratak_naziv, k.dobavljac, k.proizvod,k.nabavna_sifra
      From katalog_view K, firme f Where f.id=k.firma
      Group by k.firma, k.dobavljac, k.proizvod,f.kratak_naziv, k.nabavna_sifra
	) k
Where

      ps.plan_tip_id			= &n_tip_id
  and ps.PLAN_CIKLUS_ID			= &n_ciklus_id
  and ps.PLAN_period_ID			= &n_period_id
  and ps.plan_trajanje_id		= &n_trajanje_id
  and ps.broj_dok				in (1,2)
  and ps.proizvod=k.proizvod
  and k.dobavljac is not null
  and p.sifra = ps.proizvod
  and k.dobavljac='172'
  AND PPROIZVOD.TIP@ALBUS(NABAVNA_SIFRA)=1

--  AND nabavna_sifra IN ('370231','370241','370285')
Group by ps.PROIZVOD, k.dobavljac, k.nabavna_sifra, ps.BROJ_SASTAVNICE
, p.jed_mere, p.planska_JM, p.faktor_planske
HAVING   SUM(nvl(KOLICINA,0) * faktor_planske) > 0
Order by
--to_number(dobavljac) desc,
to_number(nabavna_sifra), ps.PROIZVOD
--)
--GROUP BY PROIZVOD
--HAVING COUNT (*)>1
