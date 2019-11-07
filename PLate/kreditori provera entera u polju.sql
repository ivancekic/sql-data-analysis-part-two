select

instr(poziv_na_broj,chr(10)) en,
substr(poziv_na_broj,1,17) ennn,
instr(substr(poziv_na_broj,1,17),chr(10)) eee,
k.*

from kreditori k
where


--      instr(kreditor,chr(10)) > 0 or instr(kreditor,chr(13)) > 0
--   or
--instr(NAZIV_KREDITORA,chr(10)) > 0 or instr(NAZIV_KREDITORA,chr(13)) > 0
--   or instr(postanski_broj,chr(10)) > 0 or instr(postanski_broj,chr(13)) > 0
--   or
instr(poziv_na_broj,chr(10)) > 0 or instr(poziv_na_broj,chr(13)) > 0
--   or instr(SVRHA_DOZNAKE,chr(10)) > 0 or instr(SVRHA_DOZNAKE,chr(13)) > 0


order by to_number(kreditor)
