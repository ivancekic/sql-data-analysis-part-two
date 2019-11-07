SELECT  st.*,sr.*
FROM OS_DOKUMENT_STAVKA st, OS_SREDSTVO sr
where
sr.ident in (select  ident from OS_DOKUMENT_STAVKA where dokument = 33
                 and tip = 705 and godina = 2005) and
		   sr.ident = st.ident and
		   sr.status = 'A' and
	       st.godina = 2005 and
      	      st.tip = 705
order by sr.ident



