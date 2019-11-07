select GOD,PROIZVOD, pproizvod.naziv(proizvod) naz
     , MAG,NA_DAT,DAT_PS,UK_DOK,MES,STANJE,ST
from
(
	Select z.GOD,z.PRO proizvod,z.MAG,z.NA_DAT,z.DAT_PS,z.UK_DOK,z.MES,z.STANJE,z1.STANJE st
	from ZAL_GOD_MAG_DAT z, ZAL_GOD_MAG_DAT_N z1
	where z.god=2012
	  and z.na_dat < to_date('03.04.2012','dd.mm.yyyy')
	  and z.god = z1.god(+)
	  and z.pro = z1.pro(+)
	  and z.mag = z1.mag(+)
	  and z.na_dat = z1.na_dat(+)
)
where stanje <> nvl(st,-999999999999)
  and mag=157 and proizvod ='100001'
Order by to_number(Proizvod), mag, na_dat

