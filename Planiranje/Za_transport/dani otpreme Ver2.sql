SELECT DAT,DAN,WD
     , DAT + 2 DAT_2
     , TO_CHAR(DAT + 2,'D') DAT_2
     , TO_CHAR(DAT + 2,'Day') DAT_2_DAY

     , decode(TO_CHAR(DAT + 2,'D'),'7', DAT + 5
                                  ,'1', DAT + 3
                                      , DAT + 2
              ) DAT_KOR_D
     , to_char(decode(TO_CHAR(DAT + 2,'D'),7, DAT + 5
                                          ,1, DAT + 3
                                          ,DAT + 2
              ),'Day') DAT_KOR_DAY

FROM
(
	Select to_char(to_date('09.10.2011','dd.mm.yyyy'), 'D') dan
	     , to_char(to_date('09.10.2011','dd.mm.yyyy'), 'Day') WD
	     , to_date('09.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('10.10.2011','dd.mm.yyyy'), 'D') dan
	     , to_char(to_date('10.10.2011','dd.mm.yyyy'), 'Day') WD
	     , to_date('10.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('11.10.2011','dd.mm.yyyy'), 'D') dan
	    , to_char(to_date('11.10.2011','dd.mm.yyyy'), 'Day') WD
	    , to_date('11.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('12.10.2011','dd.mm.yyyy'), 'D') dan
	    , to_char(to_date('12.10.2011','dd.mm.yyyy'), 'Day') WD
	    , to_date('12.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('13.10.2011','dd.mm.yyyy'), 'D') dan
	    , to_char(to_date('13.10.2011','dd.mm.yyyy'), 'Day') WD
	    , to_date('13.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('14.10.2011','dd.mm.yyyy'), 'D') dan
	    , to_char(to_date('14.10.2011','dd.mm.yyyy'), 'Day') WD
	    , to_date('14.10.2011','dd.mm.yyyy') dat From dual
	union
	Select to_char(to_date('15.10.2011','dd.mm.yyyy'), 'D') dan
	    , to_char(to_date('15.10.2011','dd.mm.yyyy'), 'Day') WD
	    , to_date('15.10.2011','dd.mm.yyyy') dat From dual
)
