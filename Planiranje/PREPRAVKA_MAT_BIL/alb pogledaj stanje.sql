SELECT GOD,PRO proizvod,MAG,NA_DAT,DAT_PS,UK_DOK,MES,STANJE
FROM ZAL_GOD_MAG_DAT_N
where
--stanje < 0

god=2012
--and na_dat < to_date('02.04.2012','dd.mm.yyyy')

Order by
--to_number(Pro), mag,
na_dat
--order by rowid
