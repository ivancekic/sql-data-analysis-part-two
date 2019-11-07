select

NAZIV_KREDITORA,POSTANSKI_BROJ,MESTO,count (*) uk
from kreditori k
group by NAZIV_KREDITORA,POSTANSKI_BROJ,MESTO
having count (*) > 0
--order by to_number(kreditor)

order by NAZIV_KREDITORA,POSTANSKI_BROJ,MESTO
