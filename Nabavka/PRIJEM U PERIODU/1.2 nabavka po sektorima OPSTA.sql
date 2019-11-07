--',113,114,115,116,117,118,'
--Select PG_NAZIV,ORG_DEO,DAT_PS,PROIZVOD,P_NAZIV PRO_NAZIV,ORG_NAZIV,JED_MERE,MIN_KOL,OPT_KOL,MAX_KOL,STANJE
--     , NAB_PER,NAB_PER_VRED,NAB_PER_VRED_RAB,NAB_PER_VRED_OSN,NAB_PER_VRED_Z_TRO,NAB_PER_VRED_OSN_Z_TRO,ZADNJA_NC
--
--     , ROUND(NAB_PER_VRED_OSN_Z_TRO / NAB_PER, 4) PROS_NAB_CENA
--     , DOBAVLJAC,REFERENT

Select PG_NAZIV,PROIZVOD,P_NAZIV PRO_NAZIV,JED_MERE,ORG_DEO,ORG_NAZIV
     , NAB_PER,NAB_PER_VRED, NAB_PER_VRED_OSN_Z_TRO,ZADNJA_NC
     , ROUND(NAB_PER_VRED_OSN_Z_TRO / NAB_PER, 4) PROS_NAB_CENA

From
(
                select * from (
                    SELECT /*+ RULE */ MAG_PR_DatPS.org_deo,
                           MAG_PR_DatPS.datum_ps dat_ps,
                           MAG_PR_DatPS.proizvod,
                           SrediNazivDok(od.naziv, NULL, 3, 20, null, null, null, null) ORG_NAZIV,
                           pg.naziv pg_naziv,
                           p.naziv p_naziv,
                           p.jed_mere,
                           (select min_kol
                              from zalihe
                             where org_deo = MAG_PR_DatPS.ORG_DEO
                               and proizvod = MAG_PR_DatPS.Proizvod) as Min_Kol,
                           (select kol_nar
                              from zalihe
                             where org_deo = MAG_PR_DatPS.ORG_DEO
                               and proizvod = MAG_PR_DatPS.Proizvod) as OPT_Kol,
                           (select max_kol
                              from zalihe
                             where org_deo = MAG_PR_DatPS.ORG_DEO
                               and proizvod = MAG_PR_DatPS.Proizvod) as Max_Kol,
                            ----------------------------------------------------------------------------
                           (Select Sum(Round(NVL(Kolicina * Faktor * K_Robe, 0), 4))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between MAG_PR_DatPS.datum_ps and &NaDan
                               And Dokument.Org_Deo = MAG_PR_DatPS.ORG_DEO
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod
                             Group By dokument.org_deo,
                                      stavka_dok.proizvod) AS Stanje,
                            ----------------------------------------------------------------------------
                            (Select sum(Round(NVL(Kolicina * Faktor * K_Robe, 0), 4))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per --NABAVLJENO_U_PERIODU
                            ----------------------------------------------------------------------------
                            ,(Select sum(Round(NVL(Kolicina * cena, 0), 2))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per_vred --NABAVLJENO_U_PERIODU
                            ----------------------------------------------------------------------------
                            ,(Select sum(Round(NVL(Kolicina * cena * nvl(stavka_dok.rabat,0)/100, 0), 2))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per_vred_rab

                            ,(Select sum(Round(NVL(Kolicina * cena * (100-nvl(stavka_dok.rabat,0))/100, 0), 2))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per_vred_osn --NABAVLJENO_U_PERIODU

                            ,(Select sum(Round(NVL(z_troskovi,0), 2))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per_vred_z_tro --NABAVLJENO_U_PERIODU

                            ,(Select sum(Round(NVL(Kolicina * cena * (100-nvl(stavka_dok.rabat,0))/100, 0)+ NVL(z_troskovi,0), 2))
                              From Dokument,
                                   Stavka_Dok
                             Where Dokument.Vrsta_Dok = Stavka_Dok.Vrsta_Dok
                               And Dokument.Broj_Dok = Stavka_Dok.Broj_Dok
                               And Dokument.Godina = Stavka_Dok.Godina
                               And (
                                        (DOKUMENT.org_deo BETWEEN 113 AND 118)
                                    or   DOKUMENT.org_deo in (100,140,168,680,690,691)
                                   )
                               and Dokument.Status > 0
                               And Stavka_Dok.K_Robe != 0
                               And Dokument.Datum_Dok Between &OdDatuma and &DoDatuma
                               and (   (Dokument.Vrsta_Dok = 3 and Dokument.Tip_Dok = 10)
                                    or Dokument.Vrsta_Dok = 73
                                   )
                               And Dokument.Org_Deo = MAG_PR_DatPS.Org_Deo
                               and stavka_dok.proizvod = MAG_PR_DatPS.Proizvod)
                             AS nab_per_vred_osn_z_tro --NABAVLJENO_U_PERIODU


                            ----------------------------------------------------------------------------
                           , (select max(round(StD2.CENA*(1-StD2.RABAT/100)+nvl(z_troskovi,0)/kolicina,4))
                              from dokument d2, stavka_dok std2
                             Where D2.Vrsta_Dok = StD2.Vrsta_Dok
                               And D2.Broj_Dok = StD2.Broj_Dok
                               And D2.Godina = StD2.Godina
                               --------------------------------
                               and d2.datum_dok between &OdDatuma and &DoDatuma
                               and (   (D2.Vrsta_Dok = 3 and D2.Tip_Dok = 10)
                                    or D2.Vrsta_Dok = 73
                                   )
                               and d2.org_deo    = MAG_PR_DatPS.Org_Deo
                               and std2.proizvod = MAG_PR_DatPS.Proizvod
                               And (
                                        (D2.org_deo BETWEEN 113 AND 118)
                                    or   D2.org_deo in (100,140,168,680,690,691)
                                   )
                               and D2.Status > 0
                               and (TO_NUMBER(TO_CHAR(D2.DATUM_DOK,'YYYYMMDD')||LPAD(d2.broj_dok,9,'0')) )=
                                                   (select MAX((TO_NUMBER(TO_CHAR(D3.DATUM_DOK,'YYYYMMDD')||LPAD(d3.broj_dok,9,'0'))))
                                                      from dokument d3, stavka_dok std3
                                                     Where D3.Vrsta_Dok = StD3.Vrsta_Dok
                                                       And D3.Broj_Dok = StD3.Broj_Dok
                                                       And D3.Godina = StD3.Godina
                                                       --------------------------------
                                                       and d3.datum_dok between &OdDatuma and &DoDatuma
                                                       and (   (D3.Vrsta_Dok = 3 and D3.Tip_Dok = 10)
                                                            or D3.Vrsta_Dok = 73
                                                           )
                                                       and d3.status > 0
                                                       --------------------------------
                                                       and d3.org_deo    = MAG_PR_DatPS.Org_Deo
                                                       and std3.proizvod = MAG_PR_DatPS.Proizvod)
                            ) AS ZADNJA_NC

                            ----------------------------------------------------------------------------
                           , (select distinct pp.naziv||'('||pp.adresa2||')'
                              from dokument d2, stavka_dok std2, poslovni_partner pp
                             Where D2.Vrsta_Dok = StD2.Vrsta_Dok
                               And D2.Broj_Dok = StD2.Broj_Dok
                               And D2.Godina = StD2.Godina
                               and d2.ppartner = pp.sifra
                               --------------------------------
                               and d2.datum_dok between &OdDatuma and &DoDatuma
                               and (   (D2.Vrsta_Dok = 3 and d2.Tip_Dok = 10)
                                    or d2.Vrsta_Dok = 73
                                   )
                               and d2.org_deo    = MAG_PR_DatPS.Org_Deo
                               and std2.proizvod = MAG_PR_DatPS.Proizvod
                               And (
                                        (D2.org_deo BETWEEN 113 AND 118)
                                    or   D2.org_deo in (100,140,168,680,690,691)
                                   )
                               and D2.Status > 0
                               and (TO_NUMBER(TO_CHAR(D2.DATUM_DOK,'YYYYMMDD')||LPAD(d2.broj_dok,9,'0')) )=
                                                   (select MAX((TO_NUMBER(TO_CHAR(D3.DATUM_DOK,'YYYYMMDD')||LPAD(d3.broj_dok,9,'0'))))
                                                      from dokument d3, stavka_dok std3
                                                     Where D3.Vrsta_Dok = StD3.Vrsta_Dok
                                                       And D3.Broj_Dok = StD3.Broj_Dok
                                                       And D3.Godina = StD3.Godina
                                                       --------------------------------
                                                       and d3.datum_dok between &OdDatuma and &DoDatuma
                                                       and (   (d3.Vrsta_Dok = 3 and d3.Tip_Dok = 10)
                                                             or d3.Vrsta_Dok = 73
                                                           )
                                                       and d3.status > 0
                                                       --------------------------------
                                                       and d3.org_deo    = MAG_PR_DatPS.Org_Deo
                                                       and std3.proizvod = MAG_PR_DatPS.Proizvod)
                            ) AS DOBAVLJAC
                            ----------------------------------------------------------------------------
                            ----------------------------------------------------------------------------
                            ----------------------------------------------------------------------------
                            ----------------------------------------------------------------------------
                      FROM (SELECT distinct D1.ORG_DEO,
                                   SD1.PROIZVOD,
                                   (SELECT nvl(MAX(DATUM_DOK), to_date('01.01.' || to_char(&NaDan, 'yyyy'), 'dd.mm.yyyy')) ---ZAMENITI SYSDATE
                                      FROM DOKUMENT D2
                                     WHERE 0 < D2.status
                                       AND 21 = D2.VRSTA_DOK
                                       AND D2.DATUM_DOK <= &NaDan
                                       and nvl(instr(&vOrgDeo, ',' || d2.org_deo || ','), 1) <> 0
                                    ) DATUM_PS
                              FROM DOKUMENT D1,
                                   STAVKA_DOK SD1
                             WHERE SD1.VRSTA_DOK = D1.VRSTA_DOK
                               AND SD1.BROJ_DOK = D1.BROJ_DOK
                               AND SD1.GODINA = D1.GODINA
                               And (
                                        (d1.org_deo BETWEEN 113 AND 118)
                                    or   D1.org_deo in (100,140,168,680,690,691)
                                   )
                               and d1.Status > 0
                               AND D1.DATUM_DOK <= &NaDan
                               and nvl(instr(&vOrgDeo, ',' || d1.org_deo || ','), 1) <> 0
                               and nvl(&vProizvod, sd1.proizvod) = sd1.proizvod
                               AND K_ROBE <> 0) MAG_PR_DatPS,
                           proizvod p,
                           posebna_grupa pg,
                           ORGANIZACIONI_DEO OD
                     WHERE p.sifra = MAG_PR_DatPS.PROIZVOD
                       AND OD.ID = MAG_PR_DatPS.ORG_DEO
                       and PG.grupa = p.posebna_grupa
                     ORDER BY MAG_PR_DatPS.ORG_DEO,p.sifra,
                              pg.naziv,
                              p_naziv
                    )
                    where nvl(nab_per,0) <> 0
)
--WHERE ZADNJA_NC <> ROUND(NAB_PER_VRED_OSN / NAB_PER, 4)
--WHERE PROIZVOD = 6770
Order by PG_NAZIV,p_naziv,org_deo;
