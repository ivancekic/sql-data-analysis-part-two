SELECT REV_GRUPA,ident,inventarski_broj,naziv,NABAVNA_VREDNOST,otpisana_vrednost
FROM OS_SREDSTVO
where
NABAVNA_VREDNOST=OTPISANA_VREDNOST and
status='A' AND
ident='1882'
