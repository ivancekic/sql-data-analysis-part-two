SELECT
       nvl(k.dobavljac,'987987') dobavljac
     , nvl((select naziv from poslovni_partner where sifra = k.dobavljac), 'NE POSTOJI VEZA PROIZVODA U KATALUGU') naziv_dobavljaca,
--       &g_trajanje_datum_od, &g_trajanje_datum_do,
       PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID
     , GOTOV_PR_SIFRA,GOTOV_PR_NAZIV,GOTOV_PR_JM
     , (
	         Select Cena --, Kol_Cena , Fak_Cena
	         From Prodajni_Cenovnik
	         Where Proizvod = gotov_pr_sifra AND
	               Valuta = 'YUD' AND
	               Datum = ( Select max( C1.Datum )
	                         From Prodajni_Cenovnik C1
	                         Where C1.Proizvod = gotov_pr_sifra AND
	                               C1.Valuta = 'YUD' AND
	                               C1.Datum <= &g_trajanje_datum_od
	                               --TO_DATE( TO_CHAR(dDatum,'DD.MM.YYYY')||' '||'23:59:59','DD.MM.YYYY HH24.MI:SS')
	                        )
       ) prod_cena_RSD

     , GOTOV_PR_PLAN_ZELJENA_KOL * (
	         Select Cena --, Kol_Cena , Fak_Cena
	         From Prodajni_Cenovnik
	         Where Proizvod = gotov_pr_sifra AND
	               Valuta = 'YUD' AND
	               Datum = ( Select max( C1.Datum )
	                         From Prodajni_Cenovnik C1
	                         Where C1.Proizvod = gotov_pr_sifra AND
	                               C1.Valuta = 'YUD' AND
	                               C1.Datum <= &g_trajanje_datum_od
	                               --TO_DATE( TO_CHAR(dDatum,'DD.MM.YYYY')||' '||'23:59:59','DD.MM.YYYY HH24.MI:SS')
	                        )
       ) plan_prihod_RSD

     , (
	         Select Cena --, Kol_Cena , Fak_Cena
	         From Prodajni_Cenovnik
	         Where Proizvod = gotov_pr_sifra AND
	               Valuta = 'YUD' AND
	               Datum = ( Select max( C1.Datum )
	                         From Prodajni_Cenovnik C1
	                         Where C1.Proizvod = gotov_pr_sifra AND
	                               C1.Valuta = 'YUD' AND
	                               C1.Datum <= &g_trajanje_datum_od
	                               --TO_DATE( TO_CHAR(dDatum,'DD.MM.YYYY')||' '||'23:59:59','DD.MM.YYYY HH24.MI:SS')
	                        )
       ) prod_cena_EUR

     , GOTOV_PR_PLAN_ZELJENA_KOL * (
	         Select Cena --, Kol_Cena , Fak_Cena
	         From Prodajni_Cenovnik
	         Where Proizvod = gotov_pr_sifra AND
	               Valuta = 'EUR' AND
	               Datum = ( Select max( C1.Datum )
	                         From Prodajni_Cenovnik C1
	                         Where C1.Proizvod = gotov_pr_sifra AND
	                               C1.Valuta = 'EUR' AND
	                               C1.Datum <= &g_trajanje_datum_od
	                               --TO_DATE( TO_CHAR(dDatum,'DD.MM.YYYY')||' '||'23:59:59','DD.MM.YYYY HH24.MI:SS')
	                        )
       ) plan_prihod_EUR


     , GOTOV_PR_TIP,GOTOV_PR_TIP_NAZIV,GOTOV_PR_GRUPA,GOTOV_PR_SASTAVNICA,GOTOV_PR_SASTAVNICA_SARZA,GOTOV_PR_PLAN_ZELJENA_KOL
     , GOTOV_PR_PLANIRANA_PRODAJA,GOTOV_PR_OPTIMALNA_ZALIHA,GRUPA_PROIZVODA
     , gotov_pr_pos_gr
     , gotov_pr_pos_gr_naziv
     , gotov_pr_prod_JM
     , gotov_pr_fak_treb

 	 ,d_dom.nabavljeno					d_nab
	 ,d_dom.STANJE_ZAL					d_stanje_zal
	 ,d_dom.STANJE_NA_DAN				d_stanje_na_dan
	 ,d_dom.prod_kol					d_prod_kol
	 ,d_dom.prod_VRED_RSD				d_prod_VRED_RSD
     ,d_dom.prod_VRED_RAB_RSD			d_prod_VRED_RAB_RSD
     ,d_dom.prod_VRED_SA_RAB_RSD		d_prod_VRED_SA_RAB_RSD

	 ,d_ino.nabavljeno					i_nab
	 ,d_ino.STANJE_ZAL					i_stanje_zal
	 ,d_ino.STANJE_NA_DAN				i_stanje_na_dan
     ,d_ino.prodato						i_prod_kol
     ,d_ino.prodato_vred_rsd			i_prod_vred_rsd
     ,d_ino.prodato_vred_rab_rsd		i_prod_vred_rab_rsd
     ,d_ino.prodato_vred_sa_rab_rsd		i_prodato_vred_sa_rab_rsd
     ,d_ino.prodato_vred_rab_eur		i_prod_vred_rab_eur
     ,d_ino.prodato_vred_sa_rab_eur		i_prodato_vred_sa_rab_eur
     ,d_ino.prodato_vred_eur			i_prod_vred_eur
FROM
(
   select
          ps.plan_tip_id
	    , ps.plan_ciklus_id
        , ps.plan_period_id
	    , ps.plan_trajanje_id
	    , ps.broj_dok
	    , ps.varijanta_id

        , ps.proizvod          gotov_pr_sifra
	    , p.naziv              gotov_pr_naziv
	    , p.jed_mere           gotov_pr_jm
        , p.tip_proizvoda      gotov_pr_tip
        , tp.naziv             gotov_pr_tip_naziv
        ,
          case when Pmapiranje.VLASNIK_CONN_STR = 'RUBIN' then
	             case when p.grupa_proizvoda = '323' then
	                  'GP-INO'
	             else
	                  'GP-DOM'
	             end
          else
              to_char(p.grupa_proizvoda)
          end     gotov_pr_grupa

        , Case when instr(PMapiranje.MOJE_FIRMA_BAZA,'INVEJ') > 0 Then
	           (Select Org_deo From Dokument d, stavka_dok sd
	            Where d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok and d.godina = sd.broj_dok
	              and sd.proizvod = ps.proizvod
	            Group By Org_Deo
	           )
          End Invej_mag_pro

	    , ps.broj_sastavnice   gotov_pr_sastavnica
        , sz.kolicina          gotov_pr_sastavnica_sarza

	    , nvl(ps.kolicina,0)          gotov_pr_plan_zeljena_kol
        , nvl(ps.planirana_prodaja,0) gotov_pr_planirana_prodaja

        , nvl(ps.optimalna_zaliha,0)  gotov_pr_optimalna_zaliha

        , p.grupa_proizvoda
        , p.posebna_grupa      gotov_pr_pos_gr
        , pg.naziv             gotov_pr_pos_gr_naziv
        , p.prodajna_JM        gotov_pr_prod_JM
        , p.faktor_trebovne    gotov_pr_fak_treb

     from
          planiranje_stavka ps
        , proizvod p
        , sastavnica_zag sz
        , tip_proizvoda tp
        , posebna_grupa pg
	where
	      ps.PLAN_CIKLUS_ID = &c_ciklus_id
	  and ps.PLAN_period_ID = &c_period_id
      and ps.plan_trajanje_id    = &c_trajanje_id
      and ps.plan_tip_id         = &c_tip_id
      and ps.broj_dok            = &c_broj_dok

      and ps.varijanta_id        = &c_varijanta_id

      and p.sifra				 = ps.proizvod
      and p.tip_proizvoda        = tp.sifra

      and pg.grupa=p.posebna_grupa
      and ps.broj_sastavnice     = sz.broj_dok (+)

) pl
,
(
		SELECT sdp.proizvod
             , sum(case when dp.vrsta_Dok in( '3','4','5','30') AND
                             dp.datum_dok <=  &g_trajanje_datum_od AND
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

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_ZAL

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') and
                                   dP.datum_dok <=  &g_trajanje_datum_od
                                   then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_NA_DAN
             , -1 * sum(case when dp.vrsta_Dok in( '11','12','13','31') AND dp.tip_dok not in (23,221,222,238,225)AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 )
                   else
                             null
                   end
                   ) prod_kol

             , -1 * sum(case when dp.vrsta_Dok in( '11','12','13','31') AND dp.tip_dok not in (23,221,222,238,225)AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * SDP.CENA, 2 )
                   else
                             null
                   end
                   ) prod_VRED_RSD
             , -1 * sum(case when dp.vrsta_Dok in( '11','12','13','31') AND dp.tip_dok not in (23,221,222,238,225)AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * SDP.CENA * sdp.RABAT / 100, 2 )
                   else
                             null
                   end
                   ) prod_VRED_RAB_RSD
             , -1 * sum(case when dp.vrsta_Dok in( '11','12','13','31') AND dp.tip_dok not in (23,221,222,238,225)AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * SDP.CENA * (1-sdp.RABAT/100), 2 )
                   else
                             null
                   end
                   ) prod_VRED_SA_RAB_RSD
		FROM dokument dp, stavka_dok sdp

		WHERE dp.broj_dok>0
          and dp.vrsta_Dok > '0'
          and dp.GODINA = &c_ciklus_id
	      and dp.status > 0

	      and dp.datum_dok between to_date('01.01.'|| &c_ciklus_id,'dd.mm.yyyy')
                               and to_date('31.12.'|| &c_ciklus_id,'dd.mm.yyyy')
 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
 	      and dp.org_Deo in (103,104,105,106,107,108)
          and sdp.proizvod in
							(
								 select proizvod
									 from planiranje_stavka
									where
								           plan_tip_id         =  &c_tip_id
								      and  plan_ciklus_id      =  &c_ciklus_id
								      and  plan_period_id      =  &c_period_id
								      and  plan_trajanje_id    =  &c_trajanje_id
								      and  broj_dok   =  &c_broj_dok
									  and  varijanta_id     =  &c_varijanta_id


							     group by proizvod
							)


        group by sdp.proizvod
) d_dom
,(
		SELECT sdp.proizvod
             , sum(case when dp.vrsta_Dok in( '73') AND
                             dp.datum_dok <=  &g_trajanje_datum_od AND
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

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_ZAL

             , round(sum(case when dp.vrsta_dok not in ('2','9','10','80','90') and
                                   dP.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do
                                   then
                                   decode(dp.tip_dok,14,sdp.Kolicina,sdp.realizovano)*sdp.Faktor*sdp.K_ROBE
                         else
                                   null
                         end)

                    ,5) STANJE_NA_DAN

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 )
                   else
                             null
                   end
                   ) prodato

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe * cena1, 2 )
                   else
                             null
                   end
                   ) prodato_vred_rsd

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe * cena1* nvl(sdp.rabat,0)/100, 2 )
                   else
                             null
                   end
                   ) prodato_vred_rab_rsd

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe * cena1* (1-nvl(sdp.rabat,0)/100), 2 )
                   else
                             null
                   end
                   ) prodato_vred_sa_rab_rsd

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * cena, 2 )
                   else
                             null
                   end
                   ) prodato_vred_eur

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * cena* nvl(sdp.rabat,0)/100, 2 )
                   else
                             null
                   end
                   ) prodato_vred_rab_eur

             , -1 * sum(case when dp.vrsta_Dok = '74' AND
                             dp.datum_dok BETWEEN &g_trajanje_datum_od AND &g_trajanje_datum_do AND
                             dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
                             then

                             Round( Decode( dp.Vrsta_Dok ||','||dp.Tip_Dok,
                                            '3,14', sdp.Kolicina,
                                            '4,14', sdp.Kolicina,
                                            sdp.Realizovano ) * sdp.K_Robe * cena* (1-nvl(sdp.rabat,0)/100), 2 )
                   else
                             null
                   end
                   ) prodato_vred_sa_rab_eur

		FROM dokument dp, stavka_dok sdp

		WHERE dp.broj_dok>0
          and dp.vrsta_Dok > '0'
          and dp.GODINA = &c_ciklus_id
	      and dp.status > 0

	      and dp.datum_dok between to_date('01.01.'|| &c_ciklus_id,'dd.mm.yyyy')
                               and to_date('31.12.'|| &c_ciklus_id,'dd.mm.yyyy')
 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
 	      and dp.org_Deo in (123,124,125,126,127,128)
          and sdp.proizvod in
							(
								 select proizvod
									 from planiranje_stavka
									where
								           plan_tip_id         =  &c_tip_id
								      and  plan_ciklus_id      =  &c_ciklus_id
								      and  plan_period_id      =  &c_period_id
								      and  plan_trajanje_id    =  &c_trajanje_id
								      and  broj_dok   =  &c_broj_dok
									  and  varijanta_id     =  &c_varijanta_id


							     group by proizvod
							)


        group by sdp.proizvod
) d_ino
,
(
	Select DOBAVLJAC,PROIZVOD,NABAVNA_SIFRA
	From
	(
		select case when proizvod in ('3764','3807','3815','7330') then
		                 '965'
		       else
		                 DOBAVLJAC
		       end       DOBAVLJAC
		     , PROIZVOD,NABAVNA_SIFRA,NABAVNI_NAZIV,CENA,VALUTA,KOL_CENA,JM_CENA,DATUM
		     , RABAT,KOMENTAR,VALUTA_PLACANJA
		from katalog k--, poslovni_partner pp
		where dobavljac in ('90','206','342','172','594','127','711','965','138','1138','1226')
		  and proizvod in (
		                    Select proizvod
		 				     from
						          planiranje_stavka ps
							where
							      ps.PLAN_CIKLUS_ID			= &c_ciklus_id
						      and ps.plan_tip_id			= &c_tip_id
							  and ps.PLAN_period_ID			= &c_period_id
						      and ps.plan_trajanje_id		= &c_trajanje_id

						      and ps.broj_dok				= &c_broj_dok
						      and ps.varijanta_id			= &c_varijanta_id

		                )
		--  and pp.sifra = k.dobavljac
	)
Group by DOBAVLJAC,PROIZVOD,NABAVNA_SIFRA
order by to_number(proizvod)
) k
where pl.GOTOV_PR_SIFRA = d_dom.proizvod (+)
  and pl.GOTOV_PR_SIFRA = d_ino.proizvod (+)
  and pl.GOTOV_PR_SIFRA = k.proizvod (+)
--  and pl.GOTOV_PR_SIFRA = 1612

order by
		  to_number(nvl(k.dobavljac,'987987'))
       , case when Pmapiranje.VLASNIK_CONN_STR = 'RUBIN' then
                   gotov_pr_grupa
         else
                   GOTOV_PR_TIP
         end

       , gotov_pr_pos_gr_naziv
       , gotov_pr_prod_JM desc
       , gotov_pr_fak_treb;



