select
        plan.MATERIJAL_TIP
      , plan.MATERIJAL_SIFRA
      , plan.MATERIJAL_NAZIV
      , plan.MATERIJAL_KOL_SUM
      , plan.MATERIJAL_JED_MERE
      , plan.MATERIJAL_ZADNJA_NABAVNA_CENA
      , plan.MATERIJAL_POSGR
      , nabavljeno
      , stanje_zal
      , stanje_na_dan
--, KON.*
      , kon.PRO_SIFRA_FIRMA
      , KON.PRO_INV_STANJE_NA_DAN
      , kontrola_stanje
      , kon1.PRO_INV_STANJE
      , kotrola_inv.kontrola_inv_stanje
      , inv_ocek
      , treb.kol_treb
      , Pro_Pod.KOL_SIGNALNA
      , OCEK
      , OCEK_INV
      , CASE WHEN NVL(Pro_Pod.KOL_SIGNALNA,0) - stanje_zal > 0 THEN
                  Pro_Pod.KOL_SIGNALNA - stanje_zal + NVL(OCEK,0) + NVL(PRO_INV_STANJE,0) + NVL(OCEK_INV,0)
        ELSE
                  NULL
        END                     HITNA_NAB
      , materijal_kol_sum  + nvl(KOL_SIGNALNA,0)
		-
		( nvl(stanje_na_dan,0) + nvl(PRO_INV_STANJE_NA_DAN,0) )  PLAN_NABAVKE

      , (select ZAD_NAB_CENA_DOK_VRED from proizvod where sifra = plan.MATERIJAL_SIFRA ) znc

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
	           plan_tip_id         = 3
	      and  plan_ciklus_id      = 2011
	      and  plan_period_id      = 3
	      and  plan_trajanje_id    = 4
	      and  broj_dok   = 1
	      and  broj_dok1  = 1
	      and  org_deo_id = 3
		  and  varijanta_id     = 1
	 	  --**********************************************************************************************************************************--
	 	  --**********************************************************************************************************************************--

		  and  status_stavka       = 1

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
                             dp.datum_dok <= to_date('01.04.2011','dd.mm.yyyy') AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 )
                   else
                             null
                   end
                   ) nabavljeno

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') and k_robe <> 0 then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_ZAL

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') and
                                   dP.datum_dok <= to_date('01.04.2011','dd.mm.yyyy')
                                   then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_NA_DAN

		FROM dokument dp, stavka_dok sdp
		   , PLANIRANJE_ORG_DEO_MAGACIN PM
		WHERE
		      pm.org_deo_id= 3
		  and pm.magacin_id=dp.org_Deo
          and
          dp.broj_dok>0
          and dp.vrsta_Dok > '0'
          and dp.GODINA =2011
	      and dp.status > 0

	      and dp.datum_dok between to_date('01.01.'||2011,'dd.mm.yyyy')
                               and to_date('31.12.'||2011,'dd.mm.yyyy')
 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
 	      and sdp.proizvod in (
 	                           select  /*+ INDEX(planiranje_stavka planir_s_pk) */
 	                                   materijal_sifra
 	                           from planiranje_view
 	                           where
 	                                   plan_tip_id         = 3
							      and  plan_ciklus_id      = 2011
							      and  plan_period_id      = 3
							      and  plan_trajanje_id    = 4
							      and  broj_dok   = 1
							      and  broj_dok1  = 1
							      and  org_deo_id = 3
								  and  varijanta_id     = 1
								  and  status_stavka       = 1

 	                           group by materijal_sifra
 	                          )

        group by sdp.proizvod
) d
,
(
	select SIFRA_FIRMA PRO_SIFRA_FIRMA, SUM(STANJE) PRO_INV_STANJE_NA_DAN
	from ZAL_GOD_MAG_DAT_INV@CITAJ_KON z
	where z.na_dat = to_date('01.04.2011','dd.mm.yyyy')
	  and z.god = to_char(to_date('01.04.2011','dd.mm.yyyy'),'yyyy')
	  and nvl(STANJE,'0') >= '0'
	  and z.firma = (select iz01 from MAPIRANJE
					  where modul='FIRMA' and ul01 = 'FIR')
    GROUP BY SIFRA_FIRMA
) kon
,
(
     select sd.proizvod kontrola_pro, nvl(sum(sd.kolicina*sd.faktor),0)  kontrola_stanje
       from dokument d
          , stavka_dok sd
	  where d.broj_dok>0
	    and d.vrsta_dok = '3'
	    and d.godina = to_char(to_date('01.04.2011','dd.mm.yyyy'),'yyyy')
	    and d.broj_dok=sd.broj_dok
	    and d.vrsta_dok=sd.vrsta_dok
	    and d.godina=sd.godina
	    and d.status < 0

        and d.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')
     Group by sd.proizvod
) kontrola
,
(
    Select SIFRA_FIRMA PRO_SIFRA_FIRMA, sum(stanje)  PRO_INV_STANJE
    From INVEJ_ZALIHE_FIRME@CITAJ_KON
    Where firma = (select iz01 from MAPIRANJE
                   where modul='FIRMA' and ul01 = 'FIR')
      and vrsta = 'NAB'
    GROUP BY SIFRA_FIRMA

) kon1
,
(
    Select SIFRA_FIRMA kontrola_pro, sum(nvl(kontrola,0))  kontrola_inv_stanje
    From INVEJ_ZALIHE_FIRME_KONTR@CITAJ_KON zo
    Where zo.firma = (select iz01 from MAPIRANJE
	   			      where modul='FIRMA' and ul01 = 'FIR')
      and zo.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')
    Group by SIFRA_FIRMA
) kotrola_inv
,
(
	select SIFRA_FIRMA kontrola_pro, sum(nvl(ocekivano,0)) inv_ocek
	  from INVEJ_ZALIHE_FIRME_OCEK@CITAJ_KON zo
	 where zo.firma = (select iz01 from MAPIRANJE
					    where modul='FIRMA' and ul01 = 'FIR')
	  and zo.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')
    Group by SIFRA_FIRMA
) inv_ocek
,
(
	 select sd.proizvod, sum(nvl(sd.kolicina*sd.faktor, 0)) kol_treb
       from dokument d
          , stavka_dok sd
	  where d.broj_dok=sd.broj_dok
	    and d.vrsta_dok=sd.vrsta_dok
	    and d.godina=sd.godina

	    and d.status < 0
	    and sd.vrsta_dok = 8
        and d.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')
     group by sd.proizvod
) treb
,
(
   select *
	 from PROIZVOD_PODACI
) Pro_Pod
,
(
				     select SD.PROIZVOD, nvl(sum(sd.kolicina-sd.realizovano),0) OCEK
				       from dokument d
				          , stavka_dok sd
					  where d.vrsta_dok = '2'
					    and d.status in (0,1,3)
					    AND d.broj_dok=sd.broj_dok and d.vrsta_dok=sd.vrsta_dok and d.godina=sd.godina

				        and d.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')

				        and (sd.kolicina-sd.realizovano)>0
				     GROUP BY SD.PROIZVOD
) OCEK
,
(
					select zo.SIFRA_FIRMA PRO_SIFRA_FIRMA, SUM(nvl(ocekivano,0)) OCEK_INV
					  from INVEJ_ZALIHE_FIRME_OCEK@CITAJ_KON zo
					 where zo.firma = (select iz01 from MAPIRANJE
									    where modul='FIRMA' and ul01 = 'FIR')

					  and zo.datum_dok between to_date('01.04.2011','dd.mm.yyyy') and to_date('30.04.2011','dd.mm.yyyy')
				     GROUP BY ZO.SIFRA_FIRMA
) OCEK_INV
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
order by MATERIJAL_POSGR
       , materijal_naziv
