SELECT sum(nabavna_vrednost)
FROM OS_SREDSTVO
where  NABAVNA_VREDNOST=OTPISANA_VREDNOST and
status='A'
