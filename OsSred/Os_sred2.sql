SELECT inventarski_broj
FROM OS_SREDSTVO
where NABAVNA_VREDNOST=OTPISANA_VREDNOST and
status='A' and nabavna_vrednost > 10000
