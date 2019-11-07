select st.*,sr.*
from os_dokument_stavka st, os_sredstvo sr
where
sr.ident in (select distinct ident
             from OS_DOKUMENT_STAVKA
             where --dokument = 31 and
                        tip = 705 and
                        godina = 2006)
and
   	 	     sr.ident = st.ident and
		    sr.status = 'A' and
--         st.dokument  = 31 and
	           st.tip = 705 and
		    st.godina = 2006
order by sr.ident
