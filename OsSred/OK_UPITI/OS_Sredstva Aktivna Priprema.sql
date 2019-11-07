Select *
--update
--set status = 'P'
from os_sredstvo
where ident not in (Select distinct ident
                    From Os_Dokument , Os_Dokument_stavka
                    Where Os_Dokument.Godina (+) = Os_Dokument_Stavka.Godina
                      And Os_Dokument.Vrsta  (+) = Os_Dokument_Stavka.Vrsta
                      And Os_Dokument.Tip    (+) = Os_Dokument_Stavka.Tip
                      And Os_Dokument.Dokument = Os_Dokument_Stavka.Dokument
                      AND Os_Dokument.STATUS != 0
                    )
and status = 'A'
