--Datum_Unosa - 0.00001

		select t.DATUM,m.ul02,t.FIRMA,t.KRATAK_NAZIV,t.KUPAC_SIFRA,t.NAZIV_KUPCA,t.KUPAC_MI,t.NAZIV_KORISNIKA,t.ADRESA,t.ADRESA2,t.MESTO_KRACE,t.MESTO_KRACE_BR
		     , t.PR_POS_GR,t.GRUPNI_NAZIV,t.KOLICINA,t.PAL,t.PAK_UK,t.PAK_NETO_UK,t.PAK_BRUTO_UK
		from
		(
				Select

				       kon.DATUM
				     , kon.FIRMA,kon.KRATAK_NAZIV
				     , kon.KUPAC_SIFRA,kon.NAZIV_KUPCA,kon.KUPAC_MI,kon.NAZIV_KORISNIKA
				     , kon.adresa, kon.adresa2, kon.mesto_krace, kon.mesto_krace_br
				     , kon.pr_pos_gr		PR_POS_GR
				     , nvl(pgg.grupni_naziv,'NIJE DEF.') 	GRUPNI_NAZIV

				     , round(SUM(kon.KOLICINA),3)			KOLICINA
				     , CEIL(SUM(kon.PAL))					PAL
				     , CEIL(SUM(kon.PAK_UK))				PAK_UK
				     , CEIL(SUM(kon.PAK_NETO_UK))			PAK_NETO_UK
				     , CEIL(SUM(kon.PAK_BRUTO_UK))			PAK_BRUTO_UK

				From
				(
				       SELECT
				              k.datum, KUPAC_SIFRA, pp.naziv naziv_kupca
				            , KUPAC_MI, mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1 									mesto_krace
				            , case when mi.polje1 is null Then 0 else 1 end 													mesto_krace_br
				            , p.POSEBNA_GRUPA pr_pos_gr, k.PROIZVOD
				            , SUM(k.KOLICINA)																					KOLICINA
				            , SUM(case when nvl(a.za_kolicinu,0)= 0 then 0 else (k.kolicina/a.za_kolicinu) End)					PAL
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu) End)				PAK_UK
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu*pak.neto) End)	PAK_NETO_UK
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu*pak.bruto)End)	PAK_BRUTO_UK
				            , kv.firma, kv.kratak_naziv
				       From poslovni_partner pp, mesto_isporuke mi
				          , (select proizvod, za_kolicinu from ambalaza where ambalaza=399) a
				          , (Select k.firma, f.kratak_naziv, k.dobavljac, k.proizvod
				             From katalog_view K, firme f Where f.id=k.firma
				             Group by k.firma, k.dobavljac, k.proizvod,f.kratak_naziv
				            ) kv
				          , proizvod p, (select proizvod, za_kolicinu, BRUTO, NETO from PAKOVANJE) pak
				          , komerc_plan_prodaje@konsolid k
				       WHERE

				             pp.sifra = k.KUPAC_SIFRA
				         and mi.ppartner=pp.sifra and mi.sifra_mesta=k.KUPAC_MI

				         and k.proizvod=a.proizvod (+) and k.proizvod=pak.proizvod (+) and k.proizvod=kv.proizvod (+)
				         and p.sifra = k.proizvod
				         and K.DATUM BETWEEN to_date('20.10.2011','dd.mm.yyyy') and to_date('31.10.2011','dd.mm.yyyy')
				    GROUP BY k.datum, k.KUPAC_SIFRA, k.KUPAC_MI, p.POSEBNA_GRUPA, k.PROIZVOD, pp.naziv
				           , mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1
				           , kv.firma, kv.kratak_naziv
				    ORDER BY k.datum, kv.kratak_naziv, to_number(KUPAC_SIFRA), to_number(KUPAC_MI), p.POSEBNA_GRUPA, to_number(k.PROIZVOD)
				) kon, (select * from POSEBNA_GRUPA_GRUPNO where firma = 1) pgg
				where
				      kon.pr_pos_gr = pgg.grupa (+)
				  ---------------------------------
				  AND pgg.grupni_naziv IS NULL
				  ---------------------------------

				Group BY kon.DATUM, kon.FIRMA,kon.KRATAK_NAZIV, kon.pr_pos_gr, pgg.grupni_naziv
				       , kon.KUPAC_SIFRA,kon.NAZIV_KUPCA,kon.KUPAC_MI,kon.NAZIV_KORISNIKA, kon.adresa, kon.adresa2, kon.mesto_krace, kon.mesto_krace_br

				UNION

				Select

				       kon.DATUM
				     , kon.FIRMA,kon.KRATAK_NAZIV
				     , kon.KUPAC_SIFRA,kon.NAZIV_KUPCA,kon.KUPAC_MI,kon.NAZIV_KORISNIKA
				     , kon.adresa, kon.adresa2, kon.mesto_krace, kon.mesto_krace_br
				     , null		PR_POS_GR
				     , nvl(pgg.grupni_naziv,'NIJE DEF.') 	GRUPNI_NAZIV

				     , round(SUM(kon.KOLICINA),3)			KOLICINA
				     , CEIL(SUM(kon.PAL))					PAL
				     , CEIL(SUM(kon.PAK_UK))				PAK_UK
				     , CEIL(SUM(kon.PAK_NETO_UK))			PAK_NETO_UK
				     , CEIL(SUM(kon.PAK_BRUTO_UK))			PAK_BRUTO_UK

				From
				(
				       SELECT
				              k.datum, KUPAC_SIFRA, pp.naziv naziv_kupca, KUPAC_MI, mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1 mesto_krace
				            , case when mi.polje1 is null Then 0 else 1 end mesto_krace_br
				            , p.POSEBNA_GRUPA pr_pos_gr, k.PROIZVOD
				            , SUM(k.KOLICINA) 																					KOLICINA
				            , SUM(case when nvl(a.za_kolicinu,0)= 0 then 0 else (k.kolicina/a.za_kolicinu) End)					PAL
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu) End)				PAK_UK
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu*pak.neto)End)		PAK_NETO_UK
				            , SUM(case when nvl(pak.za_kolicinu,0)= 0 then 0 else (k.kolicina/pak.za_kolicinu*pak.bruto)End)	PAK_BRUTO_UK
				            , kv.firma, kv.kratak_naziv
				       From poslovni_partner pp, mesto_isporuke mi
				          , (select proizvod, za_kolicinu from ambalaza where ambalaza=399) a
				          , (Select k.firma, f.kratak_naziv, k.dobavljac, k.proizvod
				             From katalog_view K, firme f Where f.id=k.firma
				             Group by k.firma, k.dobavljac, k.proizvod,f.kratak_naziv
				            ) kv
				          , proizvod p
				          , (select proizvod, za_kolicinu, BRUTO, NETO from PAKOVANJE) pak
				          , komerc_plan_prodaje@konsolid k
				       WHERE

				             pp.sifra = k.KUPAC_SIFRA
				         and mi.ppartner=pp.sifra
				         and mi.sifra_mesta=k.KUPAC_MI

				         and k.proizvod=a.proizvod (+) and k.proizvod=pak.proizvod (+) and k.proizvod=kv.proizvod (+)
				         and p.sifra = k.proizvod
				         and K.DATUM BETWEEN  to_date('20.10.2011','dd.mm.yyyy') and to_date('31.10.2011','dd.mm.yyyy')


				    GROUP BY
				             k.datum, k.KUPAC_SIFRA, k.KUPAC_MI, p.POSEBNA_GRUPA, k.PROIZVOD, pp.naziv
				           , mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1, kv.firma, kv.kratak_naziv
				    ORDER BY k.datum, kv.kratak_naziv
				           , to_number(KUPAC_SIFRA), to_number(KUPAC_MI), p.POSEBNA_GRUPA, to_number(k.PROIZVOD)
				) kon
				, (select * from POSEBNA_GRUPA_GRUPNO where firma = 1) pgg
				where
				      kon.pr_pos_gr = pgg.grupa (+)
				  ---------------------------------
				  AND pgg.grupni_naziv IS NOT NULL

				  ---------------------------------
				Group BY kon.DATUM
				       , kon.FIRMA,kon.KRATAK_NAZIV
				       , pgg.grupni_naziv
				       , kon.KUPAC_SIFRA,kon.NAZIV_KUPCA,kon.KUPAC_MI,kon.NAZIV_KORISNIKA
				       , kon.adresa, kon.adresa2, kon.mesto_krace, kon.mesto_krace_br
		) t
		,
		(Select * from mapiranje
		 where modul='DB_LINKOVI'
		 ORDER BY TO_NUMBER(UL02)
		) m
		where t.firma=m.ul01

        order by datum, ul02, mesto_krace_br, pr_pos_gr
