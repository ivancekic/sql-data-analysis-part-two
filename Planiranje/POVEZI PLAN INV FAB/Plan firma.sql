SELECT
PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID,STAVKA_ID
     , proizvod
--     , PPROIZVOD.NAZIV@ALBUS(PROIZVOD) NAZ_PRO
--     , PPROIZVOD.TIP@ALBUS(PROIZVOD)   TIP_PRO
--     , PTipProizvoda.NAZIV@ALBUS(PPROIZVOD.TIP@ALBUS(PROIZVOD))   TIP_NAZ
     , BROJ_SASTAVNICE,KOLICINA,status_id,OPTIMALNA_ZALIHA,PLANIRANA_PRODAJA,KORISNIK,DATUM
FROM PLANIRANJE_STAVKA@ALBUS PS
Where
      ps.plan_tip_id			= &n_tip_id
  and ps.PLAN_CIKLUS_ID			= &n_ciklus_id
  and ps.PLAN_period_ID			= &n_period_id
  and ps.plan_trajanje_id		= &n_trajanje_id

--  AND PROIZVOD IN ('370231','370241','370285')
--  AND PPROIZVOD.TIP@ALBUS(PROIZVOD) = 1
--  and ps.broj_dok				in (1,2)

--AND KOLICINA > 0
--and proizvod in ('340003',
--'340007',
--'340030',
--'340037',
--'340038',
--'340044',
--'340049',
--'340057',
--'340058',
--'340061',
--'340067',
--'340075',
--'340077',
--'340078',
--'340079',
--'340080',
--'340083',
--'340084',
--'340086',
--'340088',
--'340094',
--'340095',
--'340096',
--'340097',
--'340098',
--'340100',
--'340107',
--'340109',
--'340112',
--'340113',
--'340117',
--'340118',
--'340120',
--'340125',
--'340126',
--'350005',
--'350006',
--'350014',
--'350017',
--'350018',
--'350023',
--'350064',
--'350066',
--'350069',
--'350071',
--'350072',
--'350075',
--'350076',
--'350081',
--'350085',
--'350087',
--'350088',
--'350092',
--'350093',
--'350095',
--'350106',
--'350108',
--'350109',
--'350110',
--'350111',
--'350112',
--'350113',
--'350114',
--'350115',
--'350120',
--'350121',
--'350124',
--'350128',
--'350129',
--'350130',
--'350131',
--'350134',
--'350136',
--'350140',
--'350141',
--'350143',
--'350144',
--'350145',
--'350152',
--'350153',
--'350155',
--'350156',
--'350157',
--'350161',
--'350162',
--'350164',
--'350166',
--'350167',
--'350168',
--'350169',
--'350170',
--'350173',
--'350174',
--'350175',
--'350176',
--'350177',
--'350178',
--'350190',
--'350191',
--'350192',
--'350193',
--'360011',
--'360032',
--'360078',
--'360079',
--'360080',
--'360081',
--'360121',
--'360135',
--'360136',
--'360137',
--'360138',
--'360146',
--'360148',
--'360151',
--'360154',
--'360155',
--'360156',
--'360157',
--'360158',
--'360159',
--'360160',
--'360161',
--'360165',
--'360167',
--'360170',
--'360171',
--'360175',
--'360177',
--'360178',
--'360179',
--'360184',
--'360185',
--'360186',
--'360187',
--'360188',
--'360190',
--'360192',
--'360193',
--'360196',
--'360197',
--'360199',
--'360201',
--'360205',
--'360206',
--'360207',
--'360208',
--'360210',
--'360218',
--'360221',
--'360229',
--'360231',
--'360232',
--'360233',
--'360234',
--'360235',
--'360236',
--'360238',
--'360240',
--'370002',
--'370025',
--'370043',
--'370044',
--'370045',
--'370046',
--'370047',
--'370068',
--'370110',
--'370212',
--'370218',
--'370221',
--'370234',
--'370240',
--'370241',
--'370242',
--'370243',
--'370244',
--'370258',
--'370259',
--'370270',
--'370279',
--'370284',
--'370285',
--'370286',
--'370287',
--'370295',
--'370296',
--'370297',
--'370298',
--'370315',
--'370316',
--'370317',
--'370319',
--'370320',
--'370321',
--'370324',
--'370325',
--'370328')

--and '%'|| upper(PPROIZVOD.NAZIV@ALBUS(PROIZVOD))||'%' like '%TKANIN%'
ORDER BY TO_NUMBER(PROIZVOD)