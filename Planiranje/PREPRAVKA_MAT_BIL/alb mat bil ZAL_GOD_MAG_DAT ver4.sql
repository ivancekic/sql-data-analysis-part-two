--GOD,MAG,DAT_PS,UK_DOK,MES,PRO,NA_DAT,STANJE
--insert into ZAL_GOD_MAG_DAT_N
select GOD,MAG,DAT_PS,UK_DOK,MES,PRO,NA_DAT
--     , PROMET_NA_DAN,STANJE_DAN_PRE
     , STANJE_DAN_PRE + PROMET_NA_DAN stanje_na_dan
from
(
	Select dp.GOD,dp.MAG,dp.DAT_PS,dp.UK_DOK,dp.MES,dp.PRO,dp.NA_DAT,dp.PROMET_NA_DAN
	     , case when dp.NA_DAT = dp.DAT_PS then
	                 0
	       else
		        nvl(
					(
		                select STANJE from ZAL_GOD_MAG_DAT_N z
		                where z.god=dp.god and z.mag=dp.mag
		                  and z.NA_DAT = dp.na_dat-1
		                  and z.pro=dp.pro
					)
		        ,0)
	       end  stanje_dan_pre
	From
	(
	         Select d.godina 																						GOD
	              , d.org_deo																						MAG
	              , nvl( d2.dat_ps, to_date('01.01.'||to_char(d.godina),'dd.mm.yyyy') )								DAT_PS
	              , 0 																								UK_DOK
	              , TO_CHAR(datum_dok,'MM') 																		MES
	              , SD.PROIZVOD                                                                                     PRO
	              , d.datum_dok 																					NA_DAT


			     , round(sum(
			                 ( case when D.Vrsta_Dok ||','||D.Tip_Dok in ('3,14','4,14') then
			                      sd.kolicina
			                   else
			                      sd.realizovano
			                   end
			                 )
			                 * case when d.vrsta_dok = '90' then 0 else K_ROBE end * sd.faktor
			                )
			             ,5
			            )																							PROMET_NA_DAN

	               From (SELECT D3.*  FROM Dokument D3)d,
	                    (SELECT  BROJ_DOK, VRSTA_DOK, GODINA,
	                             STAVKA,PROIZVOD,LOT_SERIJA,ROK,KOLICINA,JED_MERE,CENA,VALUTA,LOKACIJA,PAKOVANJE,BROJ_KOLETA,
	                             K_REZ,K_ROBE,K_OCEK,KONTROLA,FAKTOR,REALIZOVANO,RABAT,POREZ,KOLICINA_KONTROLNA,AKCIZA,TAKSA,CENA1,Z_TROSKOVI
	                     FROM STAVKA_DOK
	                    ) sd

	                 ,
	                   (
						SELECT ORG_DEO,DAT_PS FROM
						(
		                   (Select org_deo, max(d1.datum_dok) dat_ps
		                    from dokument d1
		                    Where d1.Org_Deo = nvl(&nOrgDeo,d1.Org_deo) and d1.vrsta_dok = '21'
		                      and d1.godina = &nGod and d1.status = 1
		                    Group by d1.Org_deo
		                   )
                           UNION
		                   (Select ID org_deo, TO_DATE('01.01.'||to_char(&nGod),'dd.mm.yyyy') dat_ps
		                    from Organizacioni_deo od
		                    Where ID > 0
		                      AND id = nvl(&nOrgDeo,od.id)
		                      and tip = 'MAG'
		                      AND ID NOT IN (
                                             Select org_deo
                                             from dokument d1
                                             Where d1.Org_Deo = nvl(&nOrgDeo,d1.Org_deo) and d1.vrsta_dok = '21'
                                               and d1.godina = &nGod and d1.status = 1
                                            Group by d1.Org_deo
		                                   )
		                   )
						)

	                   ) d2

	         Where d.godina = &nGod and d.Org_Deo = nvl(&nOrgDeo,d.Org_deo) And d.Status > 0
	           And d.Broj_Dok = sd.Broj_Dok And d.Vrsta_Dok = sd.Vrsta_Dok And d.Godina = sd.Godina
	           And d.Datum_Dok between nvl(d2.dat_ps, to_date('01.01.'||to_char(d.godina),'dd.mm.yyyy'))
	                               and to_date(&cKraj||to_char(&nGod),'dd.mm.yyyy')

	           And (sd.K_Robe != 0 OR d.VRSTA_DOK = '80')
	           And d.org_deo = d2.org_deo
	         Group By d.org_deo, d.godina, TO_CHAR(datum_dok,'MM'), sd.proizvod, d.datum_dok
	                , nvl( d2.dat_ps, to_date('01.01.'||to_char(d.godina),'dd.mm.yyyy') )
	) dp
)
--where mag=22
Order by to_number(Pro), mag, na_dat
