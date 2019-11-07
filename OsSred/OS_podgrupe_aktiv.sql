SELECT podgrupa,sum(sadasnja_vrednost),sum(nabavna_vrednost),sum(otpisana_vrednost)
FROM OS_SREDSTVO
where
status='A'
group by podgrupa
