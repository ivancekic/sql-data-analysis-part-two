create view zoki_os_vrednost_brisi as
select ident,sum(nabavna_vrednost-otpisana_vrednost-ostatak_vrednosti) vrednost from os_vrednost_fer
group by ident
