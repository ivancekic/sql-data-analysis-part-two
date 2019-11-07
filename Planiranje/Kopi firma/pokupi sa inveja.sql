			Select
2 PLAN_TIP_ID, 2012 PLAN_CIKLUS_ID, 2 PLAN_PERIOD_ID, 1 PLAN_TRAJANJE_ID, 4 BROJ_DOK, 1 VARIJANTA_ID, 1 STAVKA_ID			,
k.nabavna_sifra,
			       ps.BROJ_SASTAVNICE
	             , SUM(nvl(KOLICINA,0) * faktor_planske)				 KOLICINA
			     , SUM(nvl(OPTIMALNA_ZALIHA,0) * faktor_planske)		 OPTIMALNA_ZALIHA
			     , SUM(nvl(PLANIRANA_PRODAJA,0) * faktor_planske)		 PLANIRANA_PRODAJA
			     , 1 STATUS_ID
			     , 'MEDELA' KORISNIK, '28.12.2011 10:26:36' DATUM

--			  	 , ps.PROIZVOD, p.jed_mere, p.planska_JM, p.faktor_planske
--			     , k.dobavljac
--
--			     , SUM(nvl(KOLICINA,0)) KOLICINA_SKL_JM
--
--			     , SUM(nvl(OPTIMALNA_ZALIHA,0))							 OPTIMALNA_ZALIHA_SKL_JM
--
--			     , SUM(nvl(PLANIRANA_PRODAJA,0))						 PLANIRANA_PRODAJA_SKL_JM


			From planiranje_stavka ps
			    , proizvod p
				,
				(
					Select proizvod, DOBAVLJAC, NABAVNA_SIFRA
					From
					( Select proizvod
			               , DOBAVLJAC
					       , NABAVNA_SIFRA
					  From katalog_view
					  Where dobavljac in (select SIFRA_U_INVEJU from firme where SIFRA_U_INVEJU is not null)
					    and proizvod in (Select PROIZVOD
					                     From planiranje_stavka ps
					                     Where
					                            ps.plan_tip_id			= &n_tip_id
					                       and ps.PLAN_CIKLUS_ID		= &n_ciklus_id
					                       and ps.PLAN_period_ID		= &n_period_id
					                       and ps.plan_trajanje_id		in( &n_trajanje_id )
					                       and ps.broj_dok				in (1)
					                     Group BY PROIZVOD
					                     )
                        AND TIP='K'
					  Union

					  Select proizvod
			               , DOBAVLJAC
					       , NABAVNA_SIFRA
					  From katalog_view
					  Where dobavljac in (select SIFRA_U_INVEJU from firme where SIFRA_U_INVEJU is not null)
					    and proizvod in (Select PROIZVOD
					                     From planiranje_stavka ps
					                     Where
					                            ps.plan_tip_id			= &n_tip_id
					                       and ps.PLAN_CIKLUS_ID		= &n_ciklus_id
					                       and ps.PLAN_period_ID		= &n_period_id
					                       and ps.plan_trajanje_id		in( &n_trajanje_id )
					                       and ps.broj_dok				in (2)
					                     Group BY PROIZVOD
					                     )
                        AND TIP='T'
					)
					Group by proizvod, DOBAVLJAC, NABAVNA_SIFRA
				) k
			Where

			      ps.plan_tip_id			= &n_tip_id
			  and ps.PLAN_CIKLUS_ID			= &n_ciklus_id
			  and ps.PLAN_period_ID			= &n_period_id
			  and ps.plan_trajanje_id		in( &n_trajanje_id )
			  and ps.broj_dok				in (1,2)
			  and ps.proizvod=k.proizvod    (+)
			  and k.dobavljac is not null
			  and p.sifra = ps.proizvod
              and (
                      (&cFirma is not null And k.dobavljac = Planiranje_package.Vrati_firma_od_linka(&cFirma) )
                   or (&cFirma is null     And k.dobavljac = k.dobavljac)
                  )

			Group by ps.PROIZVOD, k.dobavljac, k.nabavna_sifra, ps.BROJ_SASTAVNICE
			, p.jed_mere, p.planska_JM, p.faktor_planske

			Order by to_number(dobavljac) desc, to_number(nabavna_sifra), ps.PROIZVOD



			;
