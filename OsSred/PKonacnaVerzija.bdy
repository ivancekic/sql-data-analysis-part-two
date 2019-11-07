CREATE OR REPLACE Package Body PKonacnaVerzija Is

   -- definise izuzetke
   Veza_Ne_Postoji Exception;          -- nije uneta veza sa veznim dokumentom
   Vezni_Dokument_Ne_Postoji Exception;-- vezni dokument ne postoji u bazi
   Vezni_Dokument_Nije_Zavrsen Exception;-- vezni dokument je u statusu 0
   Ne_Postoji_Na_Veznom Exception;     -- stavka sa polaznog ne postoji na
                                       -- veznom dokumentu
   Novi_Proizvod Exception;            -- proizvod ranije nije postojao u mag.
   Polazni_Ne_Postoji Exception;       -- polazni dokument ne postoji
   Polazni_Nije_U_Radnoj_Verziji Exception; -- polazni dokument nije u
                                            -- radnoj verziji
   Vezni_Dokument_Je_Storniran Exception;   -- vezni dokument je storniran
   Vezni_Dokument_Je_Realizovan Exception;  -- vezni dokument je
                                            -- kompletno realizovan
   Stanje_Ide_U_Minus Exception;       -- ako se javi situacija koja moze da
                                       -- odvede zalihe u minus
   Prekoracenje_Veznog Exception;      -- ako se pokusa obrada vece kolicine
                                       -- nego sto ima 'neiskorisceno' tj.
                                       -- nerealizovano na veznom dokumentu
   Prevelika_Rezervacija Exception;    -- ako se pokusa rezervacija vece
                                       -- kolicine nego sto je nerezervisano
   U_Toku_Je_Popis Exception;          -- ako se pokusa menjanje stanja

                                       -- magacina u toku popisa
   Nema_Stavki Exception;              -- za slucaj da klijent pusti dokument
                                       -- bez stavki
   Cena_Je_Nula Exception;             -- ako je cena na stavci nula
   Ne_Postoji_Planska_Cena Exception;  -- ako ne postoji planska cena
   Neazurna_Planska_Cena Exception;    -- ako planska cena nije iz godine
                                       -- na koju se odnosi dokument
   Datum_Sistemski Exception;          -- ako se sistemski datum i datum
                                       -- dokumenta razlikuju
   Nepoznata_Formula Exception;        -- ako se preracun podataka u kontrolnoj
                                       -- jm trazi po formuli koja nije podrzana

   -- ove globalne promenljive (za ovaj paket) sluze za prenos
   -- vrednosti kada se javi exception
   nExpGodina Number;
   cExpBroj VarChar2( 9 );
   cExpProizvod VarChar2( 7 );
   nExpStavka Number;

   cFormula VarChar2( 1 ); -- formula po kojoj se vrsi preracunavanje podataka
                           -- u kontrolnoj jm

   -- Vraca CHR( 10 )

   Function NewLine Return Char Is
   Begin
      Return CHR( 10 );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje dokumenta u status: konacna verzija
   Procedure KonacnaVerzija( cVrstaDok VarChar2,    -- vrsta dokumenta
                             nGodina Number,        -- godina dokumenta
                             cBroj VarChar2,        -- broj dokumenta
                             cVrstaVezDok VarChar2, -- vrsta veznog dokumenta
                             nMagacin Number,       -- magacin na koji se
                                                    -- dokument odnosi
                                       -- poslednji parametar omogucava da se
                                       -- automat. dodaju novi proizv. u mag.
                             nAutomatskiDodajProizvod Number := NULL ) Is
      lKontrola Boolean;   -- da li treba vrsiti kontrolu u odnosu na
                           -- vezni dokument ili ne
      lAzuriranjeZaliha Boolean := TRUE; -- da li dokument azurira zalihe i
                                         -- analitiku ? Ne, ako je datum
                                         -- dokumenta < datuma pocetnog stanja
      -- status, datum, godina i broj veznog dokumenta
      nStatus Number;

      dDatumDok Date;
      nGodinaVez Number;
      cBrojVez VarChar2( 9 );

      -- pri radu sa stavkama veznog dokumenta
      lPostoji Boolean;       -- da li postoji odgovaraj. stavka na vez.dokum.
      nNerealizovano Number;  -- kolicina sa stavke veznog dokumenta
                              -- koja je nerealizovana, preracunato u skl.jm
      nRealizovano Number;    -- kolicina sa stavke veznog dokumenta
                              -- koja je realizovana, preracunato u skl.jm
      nPreostalo Number;      -- preostalo za realizaciju sa polaznog dokumenta
      nRealizovati Number;    -- kolicina koju treba realizovati
      lPopisUToku Boolean;    -- da li je u toku popis

      -- za zakljucavanje polaznog dokumenta i za proveru njegovog statusa
      Cursor ZaglavljePolaznog( cVrs VarChar2, nGod Number, cBr VarChar2 ) Is
         Select Status, Datum_Dok
         From Dokument
         Where Godina = nGod And
               Broj_Dok = cBr And
               Vrsta_Dok = cVrs
         For UpDate Of Status;


      -- izvlaci sve stavke polaznog dokumenta
      Cursor StavkaPolaznog( cVrs VarChar2, nGod Number, cBr VarChar2 ) Is
         Select Stavka, Proizvod,
                Kolicina, Kolicina_Kontrolna, Jed_Mere, Faktor, Kontrola,
                Lokacija, Lot_Serija, Rok,
                K_Rez, K_Robe, K_Ocek, Cena, Valuta, Pakovanje, Cena1
         From Stavka_Dok
         Where Vrsta_Dok = cVrs AND
               Godina = nGod AND
               Broj_Dok = cBr
         Order By Stavka;  -- vazno je da bude u ovom redosledu, NE MENJAJ !!!

      -- izvlaci sa veznog dokumenta sve stavke koje se odnose na
      -- proizvod cPro
      Cursor StavkaVeznog( cVrs VarChar2,
                                 nGod Number, cBr VarChar2, cPro VarChar2 ) Is
         Select Kolicina, Realizovano, Faktor
         From Stavka_Dok
         Where Vrsta_Dok = cVrs AND
               Godina = nGod AND
               Broj_Dok = cBr AND
               Proizvod = cPro
         For UpDate Of Realizovano;


      -- trenutna zaliha odredjenog proizvoda u odredjenom magacinu
      Cursor Zaliha( nMag Number, cPro VarChar2 ) Is
         Select Stanje, Stanje_Kontrolna, U_Kontroli, Ocekivana, Rezervisana
         From Zalihe
         Where Org_Deo = nMag And
               Proizvod = cPro
         For Update Of Stanje, Stanje_Kontrolna, U_Kontroli, Ocekivana, Rezervisana;

      TrenutnaZaliha Zaliha % ROWTYPE; -- odgovarajuci slog za preuzimanje podataka

      -- za proveru da li je u toku popis
      Cursor ProveriPopis( nMag Number ) Is
         Select Status
         From Popis
         Where Org_Deo = nMag And
               Status < 1;

      lDokumentNemaStavke Boolean := TRUE; -- za kontrolu postojanja stavki
      lCenaNaStavci Boolean := TRUE;       -- da li stavke moraju da imaju cenu
      nTipDok Number; -- dodato za kompenzaciju ambalaze
      cStanjeMinus VarChar2 ( 1 ) := Null;
      lAzurirajRez Boolean := True;

      dDatumCene Date; -- zbog provere datuma planske cene tj.poslovne godine
      cUser VarChar2 (30);
      cRola VarChar2 (30);
      curRola INTEGER;
      ignore INTEGER;
      SQL_String VarChar2(1000);

   Begin

   -- 31.08.1999. Dodato za ubijanje kontrole za odlazak zaliha u minus kod
   -- magacina ambalaze kod kupca( prvo je bilo samo za otpremnice prilikom
   -- kompenzacije, ali mora za sva dokumenta koja rade sa magacinom ambalaze,
   -- jer kad jednom ode u minus onda pravi probleme )
   cStanjeMinus := Null;
   -- proveri da li se radi o magacinu ambalaze kod kupca, kasnije koristi
   -- promenljivu cStanjeMinus, tj. ako njena vrednost nije null obara kontrolu
   Begin
      Select Flag Into cStanjeMinus
      From Partner_Magacin_Flag
      Where Magacin = nMagacin;
   Exception
      When No_Data_Found Then
         cStanjeMinus := Null;
   End;

   -- na zahtev ZZ, sale
   If nMagacin = 2461 Then
      cStanjeMinus := 'A';
   End If;

      -- prvo 'pogleda' da li postoji bar neki 'otvoreni' popis za magacin
--      Open ProveriPopis( nMagacin );
--      Fetch ProveriPopis Into nStatus;

--      If ProveriPopis % NOTFOUND Then
--         lPopisUToku := FALSE;
--      Else
--         lPopisUToku := TRUE;
--      End IF;
--      Close ProveriPopis;
-- umesto prethodnog, jer je procedura promenjena tako da moze da se rade
-- dokumenti i u toku popisa
        lPopisUToku := FALSE;

      -- zatim ide zakljucavanje polaznog dokumenta i provera njegovog statusa
      Open ZaglavljePolaznog( cVrstaDok, nGodina, cBroj );
      Fetch ZaglavljePolaznog Into nStatus, dDatumDok;
      If ZaglavljePolaznog % NOTFOUND Then
         Close ZaglavljePolaznog;
         Raise Polazni_Ne_Postoji;
      End If;

      If PReport.Firma( TRUE ) = 'ZUPA' Then
         -- svi dokumenti smeju da idu iz 0 u jedan
         If nStatus != 0 Then
            Close ZaglavljePolaznog;
            Raise Polazni_Nije_U_Radnoj_Verziji;

         End If;
      Else
         -- 30.12.98 osim trebovanja, svi dokumenti idu iz 0 u jedan, a
         -- kod trebovanja (vrsta_dok = 8) ide iz -7 u 1
         If ( nStatus != 0 And cVrstaDok != '8' ) Or
            ( nStatus != -7 And cVrstaDok = '8' ) Then
--         If ( nStatus != 0 And cVrstaDok != '54' ) Or
--            ( nStatus != -2 And cVrstaDok = '54' ) Then
            Close ZaglavljePolaznog;
            Raise Polazni_Nije_U_Radnoj_Verziji;
         End If;
      End If;

      -- zatim trazi podatke o veznom dokumentu sa kojim je vezan polazni
      If NOT PVezniDok.NadjiVezu( cVrstaDok, nGodina, cBroj,
                                  cVrstaVezDok, nGodinaVez, cBrojVez ) Then

         -- 11.11.1997. dodat ovaj if za situaciju 'cVrstaVezDok Is NULL'
         If cVrstaVezDok Is NOT NULL Then -- ako je zadata vrsta veznog dok.
                                          -- proci ce kroz Raise
-- dok bude dozvoljen unos polaznog dokumenta koja nema vezni dokumenat,
-- ovo ce biti pod komentarom
--         Raise Veza_Ne_Postoji;

           Null;  -- potrebno kada je red iznad pod komentarima
         End If;

         lKontrola := FALSE;  -- veza ne postoji, ne radi kontrolu
      Else     -- ako veza postoji,
               -- proverava da li postoji vezni dokument i njegov status
         nStatus := PDokument.Status( nGodinaVez, cBrojVez, cVrstaVezDok );
         If nStatus Is NULL Then -- vezni dokument ne postoji
-- dok bude dozvoljen unos veze sa nepostojecim dokumentom,
-- ovo ce biti pod komentarom
--            nExpGodina := nGodinaVez;
--            cExpBroj := cBrojVez;
--            Raise Vezni_Dokument_Ne_Postoji;

            lKontrola := FALSE;  -- vezni ne postoji, ne radi kontrolu
         Else
            -- za sve statuse je isti komentar kao uz status 0
            If nStatus = 0 Then  -- ako vezni nije zavrsen
-- ako bude dozvoljen unos veze sa nedovrsenim dokumentom,
-- sledeca tri reda ce biti pod komentarom, a cetvrti nece, i obrnuto
               nExpGodina := nGodinaVez;
               cExpBroj := cBrojVez;
               Raise Vezni_Dokument_Nije_Zavrsen;

--               lKontrola := FALSE;  -- vezni nije gotov, ne radi kontrolu
            ElsIf nStatus In ( 4, 10, 16, 18 ) Then
               nExpGodina := nGodinaVez;
               cExpBroj := cBrojVez;
               Raise Vezni_Dokument_Je_Storniran; -- jer ako je vezni storniran
                                                  -- onda ne moze ni da bude vezni
            ElsIf nStatus In ( 8, 13 ) And
               -- pusta neke storno dokumente koji treba da azuriraju
               -- vezni dokument i kad je potpuno realizovan !!!
               cVrstaDok NOT In( '4', '12', '26', '27', '34', '62','64' ) Then
               nExpGodina := nGodinaVez;
               cExpBroj := cBrojVez;
               Raise Vezni_Dokument_Je_Realizovan;
            ElsIf nStatus = 8 Then
               -- ako je dokument potpuno realizovan, a postoji razlika izmedju kolicine
               -- i realizovane kolicine na njegovim stavkama ( odgovara slucaju kada
               -- je ukinuta rezervacija po nalogu ili profakturi ) ne treba azurirati
               -- status prema kolicini, a ni rezervisanu kolicinu u zalihama zalihe
               lAzurirajRez := PStavkaDok.KolicinaRealizovano( cVrstaVezDok,
                                                               cBrojVez,nGodinaVez );
               -- bez obzira na ukidanje rezervacije vrsi sekontrola na veznom
               -- zbog azuriranja realizovane kolicine na veznom
               lKontrola := TRUE;   -- sa veznim je sve ok, radi kontrolu

            Else
               lKontrola := TRUE;   -- sa veznim je sve ok, radi kontrolu
            End If;
         End If;
      End If;

      -- Ubijanje kontrole za storno otpremnicu ambalaze, posto se nalogom za otpremu
      -- na koji se poziva i ova storno otpremnica, ne nalaze otpremanje ambalaze
      -- tako da u ovom slucaju ne treba nista raditi sa veznim dokumentom
      If (cVrstaDok = '12' And PDokument.Tip( nGodina, cBroj, '12' ) = 201) Or
         cVrstaDok In ( '62', '64' ) Then
         lKontrola := FALSE;
      End If;

      -- Ovde ide i dodatno 'ubijanje' kontrole tj. azuriranja veznog dokumenta
      -- kada se obradjuju povratnice i storno povratnice.
      -- Naime, kod povratnica je vezni dokument prijemnica, otpremnica ili
      -- trebovanje, a pri obradi povratnice, u ovim veznim dokumentima
      -- nista ne treba azurirati.
      If cVrstaDok In ( '5', '13', '28', '30', '31', '32', '45', '46' ) Then
         lKontrola := FALSE;  -- kod povratnica se ne radi nikakvo azuriranje
                              -- veznog dokumenta (kao i da ne postoji)
      End If;


      -- da li stavke dokumenta NE podlezu kontroli cene ?
      If cVrstaDok In ( '29', '38', '42', '44', '54' ) Then
         lCenaNaStavci := FALSE;    -- stavke ne moraju da imaju cenu
      End If;

      -- u zavisnosti od parametra datum dokumenta mora da se poklapa sa
      -- sistemskim datumom
      If NVL(PConfig.Vrednost('DOKUMENTI','DATUM_DOKUMENTA'), 0) = 1 Then
         Select User Into cUser
         From Dual;

         -- Otvori dinamicki kursor
         curRola := dbms_sql.open_cursor;

         SQL_String := ' Select Role From '||cUser||
                     '.Frm45_Enabled_Roles Where Role = '||
                     '''IIS_DOKUMENT_SISTEMSKI_DATUM''';

         dbms_sql.parse(curRola, SQL_String, DBMS_SQL.native);

         -- postavi
         dbms_sql.define_column(curRola, 1,cRola,30);

         Ignore := DBMS_SQL.EXECUTE(curRola);

            If dbms_sql.fetch_rows(curRola)>0 then

               dbms_sql.column_value(curRola, 1,cRola);
            End If;

            -- zatvori kursor
         DBMS_SQL.CLOSE_CURSOR(curRola);

         -- ukoliko nije dodeljena rola ispitje, da li se datum dokumenta
         -- razlikuje od sistemskog datuma

         If cRola Is Null Then
            If To_Char(dDatumDok,'dd.mm.yyyy') != To_Char(Sysdate,'dd.mm.yyyy') Then
               Raise Datum_Sistemski;
            End If;
         End If;
      End If;

      -- dodato 16.04.1998. za sprecavanje azuriranja zaliha i analitike ako
      -- dokument koji se prevodi u konacnu verziju ima datum manji od
      -- datuma pocetnog stanja za odgovarajuci magacin
      Declare
         dDatumPS Date;       -- datum poslednjeg pocetnog stanja za magacin
      Begin
         -- trazi datum poslednjeg pocetnog stanja za magacin
         Select Max( Datum_Dok )
         Into dDatumPS
         From Dokument
         Where Vrsta_Dok = '21' And Org_Deo = nMagacin And Status > 0;

         -- ako pocetno stanje ne postoji nece biti napravljen Exception
         -- nego ce promenljiva dobiti NULL vrednost
         If dDatumPS Is NULL Then
            -- ako ne postoji pocetno stanje, slucaj se tretira kao

            -- da pocetno stanje ima datum manji od datuma dokumenta
               dDatumPS := dDatumDok - 1;
         End If;

         If dDatumDok < dDatumPS Then
            lAzuriranjeZaliha := FALSE;  -- nema azuriranja zaliha
         End If;
      End;

      -- Sada ide azuriranje zaliha i analitike zaliha, sa ili bez
      -- kontrole da li se svaki proizvod koji se javlja na
      -- polaznom pojavljuje i na veznom dokumentu
      -- Za sve stavke na polaznom
      For StavkaP In StavkaPolaznog( cVrstaDok, nGodina, cBroj ) Loop
         -- provera da li stavka ima cenu
         If lCenaNaStavci Then         -- ako dokument podleze ovoj kontroli
            If StavkaP.Cena = 0 Then   -- ako stavka nema unetu cenu
               cExpProizvod := StavkaP.Proizvod;
               nExpStavka := StavkaP.Stavka;
               Raise Cena_Je_Nula;     -- generise gresku
            End If;
         End If;


         -- da li prevodjenje u konacnu verziju zavisi od postojanja
         -- planske cene za proizvod ?
         If NVL( PConfig.Vrednost( 'DOKUMENTI', 'PLANSKA_CENA' ), 0 ) = 1 Then
            -- u nalogu za nabavku i narudzbenici ne postoje planske cene
            -- jer jos nije ni definisana sifra proizvoda, pa treba izbeci
            -- ovu kontrolu
            If cVrstaDok Not In ('38', '2') Then
               If PPlanskiCenovnik.Cena( StavkaP.Proizvod,
                                       dDatumDok,
                                       StavkaP.Valuta,
                                       StavkaP.Faktor,
                                       dDatumCene ) Is NULL Then
                  cExpProizvod := StavkaP.Proizvod;
                  nExpStavka := StavkaP.Stavka;
                  Raise Ne_Postoji_Planska_Cena;
-- 04.01.2001 na zahtev Borisa ( joca )
-- dodato da propusti pocetno stanje generisano na osnovu popisa u kome je
-- preuzeta planska cena za godinu za koju se pravi pocetno stanje na osnovu popisa
-- 04.01.2002 na zahtev Borisa prosireno da vazi i za prijamnice ( joca )
               ElsIf cVrstaDok = '21' And ( To_Number(To_Char(dDatumCene,'yyyy')) != PPopis.Poslovna_Godina_Default - 1 And
                                            To_Number(To_Char(dDatumCene,'yyyy')) != nGodina ) Then
                  cExpProizvod := StavkaP.Proizvod;
                  nExpStavka := StavkaP.Stavka;
                  Raise Neazurna_Planska_Cena;
               ElsIf To_Number(To_Char(dDatumCene,'yyyy')) != nGodina And cVrstaDok != '21' Then
                  cExpProizvod := StavkaP.Proizvod;
                  nExpStavka := StavkaP.Stavka;
                  Raise Neazurna_Planska_Cena;
               End If;
            End If;
         End If;



         lDokumentNemaStavke := FALSE; -- dokument ima bar jednu stavku !

         -- za dokumente koji menjaju stanje u magacinu proverava se da li
         -- se trenutno vrsi neki popis u magacinu, i ne dozvoljava se
         -- prevodjenje dokumenta u konacnu verziju ako je popis u toku
         If lPopisUToku Then
            Raise U_Toku_Je_Popis;
         End If;
       -- ovaj if je umetnut 11.11.1997. pa zato nije dobro uvucen
       -- a cilj mu je da preskoci obradu kod dokumenata kod kojih su
       -- svi koeficijenti = 0
       If StavkaP.K_Rez != 0 Or StavkaP.K_Robe != 0 Or StavkaP.K_Ocek != 0 Then
         -- prvo ide postavljanje na odgovarajuci slog zaliha proizvoda
         Open Zaliha( nMagacin, StavkaP.Proizvod );

         -- preuzme podatke, ako slog postoji
         Fetch Zaliha Into TrenutnaZaliha;

         -- ako slog ne postoji, tj. proizvod se do sada nije pojavljivao u
         -- ovom magacinu i ako je dozvoljeno azuriranje zaliha
         If Zaliha % NOTFOUND And lAzuriranjeZaliha Then
            Close Zaliha;  -- zatvori kursor

            Declare
               lGreska Boolean := FALSE;
            Begin
               -- zavisno od parametra nAutomatskiDodajProizvod i broja stavke
               -- prijavljuje gresku ili dodaje proizvod automatski
               If nAutomatskiDodajProizvod Is NULL Then
                  lGreska := TRUE;
               Else
                  If nAutomatskiDodajProizvod != 0 And
                     nAutomatskiDodajProizvod < StavkaP.Stavka Then
                     lGreska := TRUE;
                  End If;
               End If;
               If lGreska Then
                  cExpProizvod := StavkaP.Proizvod;
                  nExpStavka := StavkaP.Stavka;
                  Raise Novi_Proizvod;
               End If;
            End;

            -- dodaje novi slog i time 'inicijalizuje' proizvod u tom magacinu
            PZalihe.DodajNovi( nMagacin, StavkaP.Proizvod );


            -- sada se postavi na taj slog i preuzme podatke
            Open Zaliha( nMagacin, StavkaP.Proizvod );
            Fetch Zaliha Into TrenutnaZaliha;
            If Zaliha % NOTFOUND Then
               RAise_Application_Error( -20789, 'JOCA' );
            End If;
         End If;

         If lKontrola Then -- ako se vrsi kontrola na veznom dokumentu
            -- pocetne inicijalizacije
            lPostoji := FALSE; -- ide na TRUE ako se pronedje odgovarajuca
                               -- stavka na veznom dokumentu
            -- preostala kolicina (preracunata u skladisnu jed.mere)
            -- krece od kolicine proizvoda na stavci polaznog dokumenta
            -- tj. ovo je pocetna vrednost ove promenljive
            nPreostalo := StavkaP.Kolicina * StavkaP.Faktor;

            -- obilazi odgovarajuce stavke na veznom dokumentu koje
            -- nisu do kraja realizovane
            For StavkaV In StavkaVeznog( cVrstaVezDok,
                                         nGodinaVez,
                                         cBrojVez,
                                         StavkaP.Proizvod ) Loop
               lPostoji := TRUE; -- znak da postoji bar jedna odgovarajuca
                                 -- stavka na veznom dokumentu

               If nPreostalo = 0 Then  -- ako je 'realizovao' svu kolicinu sa
                  Exit;                -- stavke polaznog dokumenta, izlazi
               End If;

               -- Sledi kod za azuriranje veznog dokumenta i zaliha.

               -- Ako se povecava realizovana kolicina (kad polazni dokument nije
               -- 'storno') AND
               -- samo ako nije realizovana sva kolicina na stavci ONDA
               -- povecava realizovanu kolicinu na stavci veznog dokumenta i
               -- smanjuje ocekivanu ili rezervisanu u zalihama,
               -- zavisno od koeficijenata:
               If nPreostalo > 0 And StavkaV.Kolicina != StavkaV.Realizovano Then

                  -- Nerealizovana kolicina preracunata u skladisnu jed.mere
                  nNerealizovano := StavkaV.Faktor *
                                    ( StavkaV.Kolicina - StavkaV.Realizovano );

                  -- treba realizovati onoliko koliko moze od preostale kolic.
                  -- za toliko treba povecati Realizovano na stavci veznog
                  -- dokumenta, i na odgovarajuci nacin azurirati zalihe
                  If nPreostalo > nNerealizovano Then -- ako ima 'previse'
                     -- realizuje ceo nerealizovani deo kolicine

                     nRealizovati := nNerealizovano;

                     -- ovde ne preracunava nRealizovati nazad u nabavnu jm
                     -- sa stavke narudzb. pa da to doda na vec realizovani deo,
                     -- vec ovako izjednacava, zato sto se time izbegava
                     -- eventualna greska pri zaokruzivanju
                     Update Stavka_Dok
                        Set Realizovano = Kolicina
                        Where Current Of StavkaVeznog;

                  Else -- u suprotnom, realizuje svu preostalu kolicinu
                     nRealizovati := nPreostalo;

                     -- ovde preracunava u nabavnu jm.
                     Update Stavka_Dok
                        Set Realizovano = Realizovano +
                                          nRealizovati / StavkaV.Faktor
                        Where Current Of StavkaVeznog;
                  End If;

                  -- ako je dozvoljeno azuriranje zaliha:
                  -- ako roba ulazi u magacin, znaci da je bila narucena
                  -- tj. da se ocekivala, pa se pri prijemu smanjuje ocekivana

                  -- kolicina
                  If lAzuriranjeZaliha And StavkaP.K_Robe > 0 Then
                     -- ovaj if sprecava odlazak ocekivane kolicine u minus
                     -- ovo, u osnovi nekorektno 'odsecanje' sam smatrao
                     -- prihvatljivim kod ocekivane kolicine posto je to ipak
                     -- informativni podatak. uostalom, teorijski, minus ne
                     -- bi smeo ni da se javi, tj. ako postoji situacija koja
                     -- smanji ocekivanu kolicinu vise nego sto treba, ovaj if
                     -- ce u stvari da 'ispegla' gresku.
                     If TrenutnaZaliha.Ocekivana > nRealizovati Then
                        UpDate Zalihe
                           Set Ocekivana = Ocekivana - nRealizovati
                           Where Current Of Zaliha;
                     Else
                        UpDate Zalihe
                           Set Ocekivana = 0
                           Where Current Of Zaliha;
                     End If;
                  ElsIf lAzuriranjeZaliha And StavkaP.K_Robe < 0 Then
                     -- ovo sve vazi ako po veznom dokumentu nije ukinuta rezervacija
                     If lAzurirajRez Then
                        -- ako roba izlazi iz magacina, znaci da je bila nalozena otprema
                        -- tj. da je rezervisana, pa se pri otpremi smanjuje rezervisana

                        -- kolicina
                        -- za ovaj if vazi isti komentar kao gore za ocekivanu
                        If TrenutnaZaliha.Rezervisana > nRealizovati Then
                           UpDate Zalihe
                              Set Rezervisana = Rezervisana - nRealizovati
                              Where Current Of Zaliha;
                        Else
                           UpDate Zalihe
                              Set Rezervisana = 0
                              Where Current Of Zaliha;
                        End If;
                     End If;
                  End If;

                  -- za eventualnu dalju realizaciju na sledecim stavkama
                  -- veznog dokumenta ostaje jos ovoliko
                  nPreostalo := nPreostalo - nRealizovati;
               ElsIf nPreostalo < 0 And StavkaV.Realizovano > 0 Then
                  -- Ako se smanjuje realizovana kolicina (kad je polazni dokument
                  -- 'storno') AND
                  -- samo ako je realizovana bar neka kolicina na stavci ONDA
                  -- smanjuje realizovanu kolicinu na stavci veznog dokumenta i
                  -- povecava ocekivanu ili rezervisanu u zalihama,

                  -- zavisno od koeficijenata:

                  -- radi lakseg rada, prebaci znak u plus
                  nPreostalo := -nPreostalo;

                  -- Realizovana kolicina preracunata u skladisnu jed.mere
                  nRealizovano := StavkaV.Faktor * StavkaV.Realizovano;

                  -- treba smanjiti za onoliko koliko moze od preostale kolic.
                  -- tj. za toliko treba smanjiti Realizovano na stavci veznog
                  -- dokumenta, i na odgovarajuci nacin azurirati zalihe
                  If nPreostalo > nRealizovano Then -- ako ima 'previse'
                     -- smanjuje ceo realizovani deo kolicine
                     nRealizovati := nRealizovano;

                     -- ovde ne preracunava nRealizovati nazad u nabavnu jm
                     -- sa stavke narudzb. pa da to oduzme od realizovanog dela,
                     -- vec ovako izjednacava, zato sto se time izbegava
                     -- eventualna greska pri zaokruzivanju
                     Update Stavka_Dok
                        Set Realizovano = 0
                        Where Current Of StavkaVeznog;


                  Else -- u suprotnom, smanjuje za svu preostalu kolicinu
                     nRealizovati := nPreostalo;

                     -- ovde preracunava u nabavnu jm.
                     Update Stavka_Dok
                        Set Realizovano = Realizovano -
                                          nRealizovati / StavkaV.Faktor
                        Where Current Of StavkaVeznog;
                  End If;

                  -- ako je dozvoljeno azuriranje zaliha:
                  -- ovo je prica kod originalnog dokumenta:
                  -- ako roba ulazi u magacin, znaci da je bila narucena
                  -- tj. da se ocekivala, pa se pri prijemu smanjuje ocekivana
                  -- kolicina
                  -- ali ovde je sve suprotno posto se radi o storno dokumentu
                  If lAzuriranjeZaliha And StavkaP.K_Robe > 0 Then
                     UpDate Zalihe
                        Set Ocekivana = Ocekivana + nRealizovati
                        Where Current Of Zaliha;
                  ElsIf lAzuriranjeZaliha And StavkaP.K_Robe < 0 Then
                     -- ovo sve radi kada po dokumentu nije ukinuta rezervacija
                     If lAzurirajRez Then

                        -- kod originalnog dokumenta je:
                        -- ako roba izlazi iz magacina, znaci da je bila nalozena otprema
                        -- tj. da je rezervisana, pa se pri otpremi smanjuje rezervisana
                        -- kolicina
                        -- ali ovde je sve suprotno posto se radi o storno dokumentu
                        -- Ovde se ne ispituje da li ce nova rezervisana kolicina da
                        -- bude veca od trenutnog stanja jer to nije ni moguca, ako sve
                        -- radi kako treba. Naime, ako je sve kako treba, to znaci da ce u
                        -- ovom trenutku da bude maksimalno stanje=rezervisana, a
                        -- posto je ovo povecanje obavezno praceno i povecanjem stanja
                        -- dole ispod za ovu istu kolicinu, dakle na kraju transakcije
                        -- bice i dalje isti odnos stanje:rezervisano
                        UpDate Zalihe
                           Set Rezervisana = Rezervisana + nRealizovati
                           Where Current Of Zaliha;
                     End If;
                  End If;

                  -- za eventualno dalje smanjivanje na sledecim stavkama
                  -- veznog dokumenta ostaje jos ovoliko
                  nPreostalo := nPreostalo - nRealizovati;

                  -- na kraju mu vraca znak

                  nPreostalo := -nPreostalo;
               End If;
-- AAA ubaciti deo vezan za azuriranje kolicina na nalogu za nabavku
-- kada se izvrsi prijem ili storno prijema to azurara narudzbenicu, a ona
-- treba da azurira stavke naloga
            End Loop;  -- kraj petlje koja obilazi stavke veznog dokumenta

            If NOT lPostoji Then -- ako ne postoji nijedna odgovarajuca
                                 -- stavka na veznom dokumentu
               NULL; -- ako je sledeci Raise... stavljen pod komentare
-- ako bude dozvoljen unos stavki koje se ne pojavljuju na veznom dokumentu
-- ovo ce da bude pod komentarima
               cExpBroj := cBrojVez;
               nExpGodina := nGodinaVez;
               cExpProizvod := StavkaP.Proizvod;
               nExpStavka := StavkaP.Stavka;
               Raise Ne_Postoji_Na_Veznom;
            End If;

            -- ukoliko na veznom dokumentu ne postoji 'pokrice' za celu
            -- kolicinu na stavci, prekida obradu
            If nPreostalo != 0 Then
               -- (ne vazi za otpremnice i naloge za otpremu)

               If cVrstaDok In ( '11', '12', '61', '62','63','64' ) And cVrstaVezDok = '10' Then
                  Null;
               Else
                  Raise Prekoracenje_Veznog;
               End If;
            End If;
         End If;   -- od If lKontrola Then ...

         -- deo za azuriranje prosecnih cena
         Declare
            -- za dobijanje trenutne cene iz prosecnog cenovnika
            Cursor ProsecnaCena( nMag Number, cPro VarChar2 ) Is
               Select Cena, Vrsta_Dok, Broj_Dok, Godina, Datum
               From Prosecni_Cenovnik
               Where Org_Deo = nMag And
                     Proizvod = cPro
               Order By Datum Desc  -- na ovaj nacin je prvi slog koji se izvuce
                                    -- upravo onaj koji sadrzi poslednju cenu
               For Update;

            cTip VarChar2( 3 );     -- tip cenovnika (1=prosecni cenovnik)
            nStaraKolicina Number;  -- kolicina na zalihama (u skl.jm)
                                    -- koja je bila pre izmene zaliha

            nKolicinaNaStavci Number; -- kolicina na stavci u  skl.jm
            nStaraCena Number;      -- trenutna prosecna cena
            nCenaPoSklJM Number;    -- cena na stavci, ali za skl.jm.
            cVD VarChar2( 2 );      -- vrsta dok. iz sloga koji sadrzi poslednju cenu
            cBD VarChar2( 9 );      -- broj dok. iz sloga koji sadrzi poslednju cenu
            nGD  Number;            -- godina dok. iz sloga koji sadrzi poslednju cenu
            dDatum Date;            -- datum sloga koji sadrzi poslednju cenu
         Begin
            -- ako je dozvoljeno azuriranje zaliha:
            -- ako ce doci do 'ulaza' robe, treba da se vidi koji cenovnik
            -- vazi za proizvod
            If lAzuriranjeZaliha And StavkaP.K_Robe > 0 Then
               cTip := PTipProizvoda.Cenovnik( PProizvod.Tip( StavkaP.Proizvod ) );

               -- ako se proizvod vodi po prosecnim cenama ...
               If cTip = '1' Then
                  -- onda treba azurirati prosecni cenovnik:
                  -- treba naci njegovu trenutnu cenu ...
                  Open ProsecnaCena( nMagacin, StavkaP.Proizvod );
                  Fetch ProsecnaCena Into nStaraCena, cVD, cBD, nGD, dDatum;
                  If ProsecnaCena % NOTFOUND Then
                     nStaraCena := 0; -- ako ne postoji podatak u cenovniku
                     cVD := NULL;

                     dDatum := NULL;
                  End If;

                  -- ...i trenutnu kolicinu na zalihama
                  nStaraKolicina := TrenutnaZaliha.Stanje +
                                    TrenutnaZaliha.U_Kontroli;

                  -- kolicina na stavci u skl.jm.
                  nKolicinaNaStavci := StavkaP.Kolicina * StavkaP.Faktor;

                  -- za azuriranje prosecnog cenovnika je takodje potrebno da se
                  -- zna cena proizvoda sa stavke, ali za skladisnu jedinicu mere
                  -- i to u dinarima !
                  
                  
                  
                  --Ovo je promenio Zoran 30.01.2006 jer povr.po otpremnici nije
                  --radila dobro po prosecnim cenama
/*                  nCenaPoSklJM := PKurs.Vrednost( StavkaP.Cena,
                                                  StavkaP.Valuta,
                                                  'YUD',
                                                  dDatumDok )/StavkaP.Faktor;
*/
                  if cVrstaDok in (13) then    --Ako je povratnica po otpremnici mora
                                               --da bude uzeta cena1 iz dokumenta
                                               --a ne prodajna cena, dodao zoran 27.01.2006
                        nCenaPoSklJM := PKurs.Vrednost( StavkaP.Cena1,
                                                        StavkaP.Valuta,
                                                        'YUD',
                                                        dDatumDok )/StavkaP.Faktor;
                  else
/*                        nCenaPoSklJM := PKurs.Vrednost( StavkaP.Cena,
                                                        StavkaP.Valuta,
                                                        'YUD',
                                                        dDatumDok )/StavkaP.Faktor;
*/                        
                          -- ovo sam ponovo promeni jer izgleda da sve mora
                          -- da ide po ceni1
                          nCenaPoSklJM := PKurs.Vrednost( StavkaP.Cena1,
                                                        StavkaP.Valuta,
                                                        'YUD',
                                                        dDatumDok )/StavkaP.Faktor;
                  end if;


                                                  

                  If cVD Is NULL Or       -- ako ne postoji slog u cenovniku
                     cVrstaDok != cVD Or  -- ili se ne radi o istom dokumentu
                     cBroj != cBD Or      -- (ovo je ok, jer je u kursoru vec
                     nGodina != nGD Then  -- stavljeno izdvajanje po proizvodu)


                     Close ProsecnaCena;  -- kursor ovde nije potreban

                     -- e, sad, ako se bas desi da se istovremeno pokrene
                     -- prevodjenje razlicitih dokumenata koji azuriraju
                     -- prosecni cenovnik (npr. na vise klijenata) i bas se
                     -- desi situacija da stavke sa tih dokumenata koje se
                     -- odnose na isti proizvod bas u istom trenutku izazovu
                     -- azuriranje prosecnog cenovnika (sto bi dovelo do
                     -- narusavanja primarnog kljuca, u tom slucaju se prolazi
                     -- kroz ovaj if koji unosi malu pauzu kojom se to sprecava
                     If dDatum Is NOT NULL Then
                        Loop
                           Exit When SysDate > dDatum;
                        End Loop;
                     End If;

                     -- Sada dodaje slog sa novom prosecnom cenom
                     -- Ovaj if treba da spreci deljenje s nulom
                     -- (kada je nova kolicina = 0, sto je moguce
                     -- npr. pri storniranju)
                     If nStaraKolicina + nKolicinaNaStavci != 0 Then
                        Insert Into Prosecni_Cenovnik
                        Values( nMagacin, StavkaP.Proizvod, SysDate, SysDate,

                                nStaraKolicina + nKolicinaNaStavci,
                                NVL(( nStaraKolicina * nStaraCena +
                                  nKolicinaNaStavci * nCenaPoSklJM ) /
                                ( nStaraKolicina + nKolicinaNaStavci ),0),
                                  nStaraKolicina, NVL(nStaraCena,0),
                                cVrstaDok, cBroj, nGodina, StavkaP.Stavka );
                     Else
                        Insert Into Prosecni_Cenovnik
                        Values( nMagacin, StavkaP.Proizvod, SysDate, SysDate,
                                0, NVL(nStaraCena,0), -- kada je nova kolicina 0, cena ostaje stara
                                nStaraKolicina, NVL(nStaraCena,0),
                                cVrstaDok, cBroj, nGodina, StavkaP.Stavka );
                     End If;
                  Else -- ako slog postoji i nastao je zbog neke ranije stavke na ovom
                       -- istom dokumentu koji se obradjuje, onda se ne dodaje novi
                       -- slog vec se postojeci azurira, ali samo neka polja !
                     -- ovaj if sprecava deljenje sa nulom
                     If nStaraKolicina + nKolicinaNaStavci != 0 Then
                        Update Prosecni_Cenovnik
                        Set Datum = SysDate, Datum_Unosa = SysDate,
                           Kolicina = nStaraKolicina + nKolicinaNaStavci,
                           Cena = NVL(( nStaraKolicina * nStaraCena +
                                    nKolicinaNaStavci * nCenaPoSklJM ) /

                                  ( nStaraKolicina + nKolicinaNaStavci ),0),
                           Stavka_Dok = StavkaP.Stavka
                        Where Current Of ProsecnaCena;
                     Else
                        Update Prosecni_Cenovnik
                        Set Datum = SysDate, Datum_Unosa = SysDate,
                           Kolicina = 0,
                           Cena = NVL(nStaraCena,0),
                           Stavka_Dok = StavkaP.Stavka
                        Where Current Of ProsecnaCena;
                     End If;

                     Close ProsecnaCena;
                  End If;
               End If;
            End If;
         End;

         -- azuriranje zaliha, ako je dozvoljeno:
         -- i kod otpreme i kod prijema, ako treba kontrola, kolicina
         -- u kontroli se POVECAVA, pa kad se izvrsi kontrola, u zavisnosti
         -- od vrste dokumenta, Stanje se povecava (ako je dokument prijemni)
         -- ili ne menja (ako je dokument otpremni)

         -- razlika je sto kod prijema Stanje ostaje isto kad se prima roba
         -- koja trazi kontrolu pri ulazu, a kod otpreme se Stanje uvek
         -- smanjuje bez obzira da li roba trazi kontrolu pri otpremi
         -- kratko receno uvek treba da bude
         -- Stanje + U_Kontroli = kolicina koja fizicki postoji u magacinu
         If lAzuriranjeZaliha Then
            If StavkaP.K_Robe != 0 And StavkaP.Kontrola = 0 Then  -- ako treba kontrola
               UpDate Zalihe
                  Set U_Kontroli = U_Kontroli + StavkaP.Kolicina * StavkaP.Faktor
                  Where Current Of Zaliha;
            End If;
            -- ako je prijem robe i ako kontrola nije potrebna ili ...
            If StavkaP.K_Robe > 0 And StavkaP.Kontrola = 1 Or
                              StavkaP.K_Robe < 0 Then  -- ... ako je otprema robe

               -- dozvoljava odlazak zaliha u minus kod magacina ambalaze
               If cStanjeMinus Is Null Then
                  -- sprecava odlazak stanja zaliha u minus
                  If TrenutnaZaliha.Stanje +
                     StavkaP.K_Robe * StavkaP.Kolicina * StavkaP.Faktor < 0 Then
                     Raise Stanje_Ide_U_Minus;
                  End If;
               End If;


               UpDate Zalihe
                  Set Stanje = Stanje +
                              StavkaP.K_Robe * StavkaP.Kolicina * StavkaP.Faktor
                  Where Current Of Zaliha;

               -- ako je kolicina izrazena i u kontrolnoj kolicini
               -- vrsi se i njeno azuriranje
               If StavkaP.Kolicina_Kontrolna Is NOT NULL Then

                  -- dozvoljava odlazak zaliha u minus kod magacina ambalaze
                  If cStanjeMinus Is Null Then
                     -- sprecava odlazak stanja zaliha u minus
                     If TrenutnaZaliha.Stanje_Kontrolna +
                        StavkaP.K_Robe * StavkaP.Kolicina_Kontrolna < 0 Then
                        Raise Stanje_Ide_U_Minus;
                     End If;
                  End If;

                  UpDate Zalihe
                     Set Stanje_Kontrolna = Stanje_Kontrolna +
                                 StavkaP.K_Robe * StavkaP.Kolicina_Kontrolna
                     Where Current Of Zaliha;

               End If;

               -- kad se menja Stanje, odmah se azurira i tabela Zalihe_Analitika
               -- 31.08.1999. dodat parametar cStanjeMinus koji dozvoljava
               -- odlazak u minuz zalihe_analitika kod magacina ambalaze
               -- reseno OVERLOADING-om, moglo je i preko null parametara
               -- ali sigurnije je ovako zbog eventualonog poziva sa klijenta
               If StavkaP.K_Robe > 0 Then
                  PZaliheAnalitika.Dodaj( nMagacin, StavkaP.Proizvod,
                           StavkaP.Lokacija, StavkaP.Lot_Serija, StavkaP.Rok,
                           StavkaP.Kolicina * StavkaP.Faktor,
                           StavkaP.Kolicina_Kontrolna, cStanjeMinus );
               ElsIf StavkaP.K_Robe < 0 Then
                  PZaliheAnalitika.Oduzmi( nMagacin, StavkaP.Proizvod,
                           StavkaP.Lokacija, StavkaP.Lot_Serija, StavkaP.Rok,
                           StavkaP.Kolicina * StavkaP.Faktor,
                           StavkaP.Kolicina_Kontrolna, cStanjeMinus );
               End If;
            End If;
         End If;

         -- kroz if ne prolazi samo nalog za otpremu radjen po profakturi
         -- jer on ne treba da menja rezervisanu kolicinu, posto je ona

         -- vec rezervisana profakturom
         -- dakle, ako nije nalog za otpremu ili (ako i jeste), ako nije
         -- radjen po profakturi (tada je lKontrola = FALSE) prolazi kroz if
         If lAzuriranjeZaliha Then

            -- u zavisnosti od parametra profaktura ne rezervise robu,
            -- zbog toga jos jedan Or za taj parametar,
            -- da bi nalog za otpremu prosao kroz if i azurirao rezervisane
            -- kolicine ukoliko je to potrebno ( tj. ako parametar kaze da
            -- profaktura ne rezervise robu )

            If cVrstaDok != 10 Or NOT lKontrola Or
               NVL( PConfig.Vrednost( 'DOKUMENTI', 'PROFAKTURA_REZERVACIJA' ), '0' ) = '0' Then
               -- ocekivane kolicine
               If StavkaP.K_Ocek != 0 Then
                  -- azuriranje ocekivanih kolicina se ne radi za
                  -- '0' fiktivne sifre proizvoda 17.11.1999. S.Stefanovic
                  If StavkaP.Proizvod != '0' Then
                     -- sprecava odlazak ocekivanih kolicina u minus
                     -- mada su trenutno (13.11.1997) na svim dokumentima K_OCEK >= 0
                     -- neka stoji ova kontrola
                     If TrenutnaZaliha.Ocekivana +
                           StavkaP.K_Ocek * StavkaP.Kolicina * StavkaP.Faktor > 0 Then

                        UpDate Zalihe
                           Set Ocekivana = Ocekivana +
                                    StavkaP.K_Ocek * StavkaP.Kolicina * StavkaP.Faktor
                           Where Current Of Zaliha;
                     Else
                        UpDate Zalihe
                           Set Ocekivana = 0
                           Where Current Of Zaliha;
                     End If;
                  End If;
               End If;
               -- rezervisane kolicine
               If StavkaP.K_Rez != 0 Then
                  -- sprecava odlazak rezervisanih kolicina u minus
                  -- mada su trenutno (13.11.1997) na svim dokumentima K_REZ >= 0
                  -- neka stoji ova kontrola
                  If TrenutnaZaliha.Rezervisana +
                        StavkaP.K_Rez * StavkaP.Kolicina * StavkaP.Faktor > 0 Then

                     -- ovaj if je umetnut 05.12.97 i sprecava da se rezervise
                     -- vise od onog sto ima na zalihama
                     If TrenutnaZaliha.Rezervisana + StavkaP.K_Rez *
                                    StavkaP.Kolicina * StavkaP.Faktor >

                                                      TrenutnaZaliha.Stanje Then
                        Raise Prevelika_Rezervacija;
                     Else
                        UpDate Zalihe
                           Set Rezervisana = Rezervisana +
                                    StavkaP.K_Rez * StavkaP.Kolicina * StavkaP.Faktor
                           Where Current Of Zaliha;
                     End If;
                  Else
                     UpDate Zalihe
                        Set Rezervisana = 0
                        Where Current Of Zaliha;
                  End If;
               End If;
            End If;
         End If;

         Close Zaliha;        -- zatvori kursor zaliha

       ElsIf cVrstaDok = '44' Then -- dokument 44 (promena lokacije) se tretira posebno
         -- prvo ide postavljanje na odgovarajuci slog zaliha proizvoda
         Open Zaliha( nMagacin, StavkaP.Proizvod );


         -- preuzme podatke, ako slog postoji (to bi moralo uvek da bude)
         Fetch Zaliha Into TrenutnaZaliha;

         -- ako slog ne postoji, tj. proizvod se do sada nije pojavljivao u
         -- ovom magacinu, znaci da postoji greska na klijentu koji to nije
         -- smeo da pusti
         If Zaliha % NOTFOUND And lAzuriranjeZaliha Then
            Close Zaliha;  -- zatvori kursor

            Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  StavkaP.Proizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Obavestite nadle`no lice !' );

         End If;

         -- samo ako je dozvoljeno azuriranje zaliha
         If lAzuriranjeZaliha Then
            -- azuriranje zaliha: azurira se samo analitika zaliha
            -- smanjuje kolicinu na jednoj lokaciji
            PZaliheAnalitika.Oduzmi( nMagacin, StavkaP.Proizvod,
                     SubStr( StavkaP.Pakovanje, 1, 6 ),
                     StavkaP.Lot_Serija, StavkaP.Rok,
                     StavkaP.Kolicina * StavkaP.Faktor,
                     StavkaP.Kolicina_Kontrolna );

            -- povecava kolicinu na drugoj lokaciji
            PZaliheAnalitika.Dodaj( nMagacin, StavkaP.Proizvod,
                     StavkaP.Lokacija, StavkaP.Lot_Serija, StavkaP.Rok,
                     StavkaP.Kolicina * StavkaP.Faktor,
                     StavkaP.Kolicina_Kontrolna );
         End If;

         Close Zaliha;        -- zatvori kursor zaliha
       End If;    -- umetnuti if, odmah ispod pocetka petlje
      End Loop;  -- petlja za stavke polaznog dokumenta

      -- zatvara cursor zaglavlje polaznog dokumenta
      Close ZaglavljePolaznog;

      -- ako dokument nema nijednu stavku,
      -- sprecava prevodjenje u konacnu verziju
      If lDokumentNemaStavke Then
         Raise Nema_Stavki;
      End If;


--      -- odredi status veznog dokumenta
--      nStatus := PDokument.Status( nGodinaVez, cBrojVez, cVrstaVezDok );
--
--      -- ako je dokument potpuno realizovan, a postoji razlika izmedju kolicine
--      -- i realizovane kolicine na njegovim stavkama ( odgovara slucaju kada
--      -- je ukinuta rezervacija po nalogu ili profakturi ) ne treba azurirati
--      -- status prema kolicini
--      If nStatus = 8 And
--         Not PStavkaDok.KolicinaRealizovano( cVrstaVezDok,cBrojVez,nGodinaVez ) Then
--            lKontrola := False;
--      End If;

      -- na kraju sledi usaglasavenje statusa veznih dokumenata
      If lKontrola And lAzurirajRez Then -- usaglasavenje prema realizaciji
         -- azurira status veznog dokumenta, ukoliko je to dozvoljeno za
         -- vrstu dokumenta cVrstaVezDok, a ako nije, ne radi nista, ali
         -- ne prijavljuje ni gresku (4 parametar postavljen na FALSE)
         PDokument.PostaviStatusPremaRealizaciji( cVrstaVezDok,
                                                  nGodinaVez,
                                                  cBrojVez );
      ElsIf cVrstaDok In ( '5', '13', '28', '30', '31', '32', '45', '46' ) Then
         -- usaglasavanje statusa veznog dokumenta prema povratnicama

         PDokument.PostaviStatusPremaPovratnicama( cVrstaVezDok,
                                                   nGodinaVez,
                                                   cBrojVez );
      End If;

   Exception
      When Prekoracenje_Veznog Then
         Raise_Application_Error( -20100, 'Koli~ine na dokumentu su ve}e' ||
                                  NewLine || 'od raspolo`ivih na veznom !' ||
                                  NewLine || 'Proverite stanje veznog dokumenta !' );

      When Stanje_Ide_U_Minus Then
         Raise_Application_Error( -20101, 'Na zalihama ne postoje' ||
                                  NewLine || 'dovoljne koli~ine proizvoda !' ||
                                  NewLine || 'Proverite trenutno stanje zaliha !' );

      When Prevelika_Rezervacija Then
         Raise_Application_Error( -20102, 'Nije dozvoljeno da rezervi{ete ve}u ' ||
                                  NewLine || 'koli~inu od raspolo`ive  !' ||
                                  NewLine || 'Proverite trenutno stanje zaliha !' );
      When U_Toku_Je_Popis Then
         Raise_Application_Error( -20103, 'Trenutno nije mogu}e prevo|enje ' ||
                                  'ovog dokumenta u kona~nu verziju !' ||

                                  NewLine || 'U toku je popis u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' );
      When Nema_Stavki Then
         Raise_Application_Error( -20104, 'Dokument mora da ima bar jednu stavku' ||
                                          NewLine || 'da bi mogao da se prevede u ' ||
                                          NewLine || 'kona~nu verziju !' );

      When Cena_Je_Nula Then
         Raise_Application_Error( -20105, 'Ne postoji cena za' || NewLine ||
                                          'proizvod pod {ifrom ' || cExpProizvod || ' !' ||
                                          NewLine || '(pogledajte stavku br. ' ||
                                          To_Char( nExpStavka ) || ')' );

      When Nepoznata_Formula Then
         If cFormula Is NULL Then
            Raise_Application_Error( -20106, 'Rad sa kontrolnom jedinicom mere ' ||
                                             'po formuli ' || cFormula ||
                                             ' nije podr`an !  Obavestite nadle`no lice !' );
         Else
            Raise_Application_Error( -20107, 'Nije zadata formula za rad sa kontrolnom jedinicom ' ||
                                             'mere !  Obavestite nadle`no lice !' );
         End If;


      When Ne_Postoji_Planska_Cena Then
         Raise_Application_Error( -20108, 'Ne postoji planska cena za' || NewLine ||
                                          'proizvod pod {ifrom ' || cExpProizvod || ' !' ||
                                          NewLine || '(pogledajte stavku br. ' ||
                                          To_Char( nExpStavka ) || ')' );
      When Neazurna_Planska_Cena Then
         Raise_Application_Error( -20109, 'Planska cena za proizvod' || NewLine ||
                                          'pod {ifrom ' || cExpProizvod ||
                                          ' nije iz navedene poslovne godine!' ||
                                          NewLine || '(pogledajte stavku br. ' ||
                                          To_Char( nExpStavka ) || ')' );
      When Datum_Sistemski Then
         Raise_Application_Error( -20110, 'Gre{ka !'|| NewLine ||
                                          'Datum dokumenta mora da bude' || NewLine ||
                                          To_Char(SysDate,'dd.mm.yyyy')||'.' );
   End;

   -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
   -- pre prevodjenja dokumenta u konacnu verziju
   -- ova procedura je bitna za otpremnicu, profakturu i nalogza otpremu
   Procedure Uslovi( nGodina Number, cBroj VarChar2, cVrstaDok VarChar2 ) Is

      -- kursor izdvaja porez za svaku stavku iz tabele Stavka_Dok

      Cursor Porez_Cur( nGodina In Number, cBroj In VarChar2,
                                                   cVrstaDok In VarChar2 ) Is
            Select Porez
            From Stavka_Dok
            Where Broj_Dok = cBroj And
                  Vrsta_Dok = cVrstaDok And
                  Godina = nGodina;

      -- kursor izdvaja rabat za svaku stavku iz tabele Stavka_Dok
      Cursor Rabat_Cur( nGodina In Number, cBroj In VarChar2,
                                                   cVrstaDok In VarChar2 ) Is
            Select Rabat
            From Stavka_Dok
            Where Broj_Dok = cBroj And
                  Vrsta_Dok = cVrstaDok And
                  Godina = nGodina;

      nPorez Number;
      nVrstaIzjave Number;
      nRabat Number;
      nSpecRabat Number;
      nRabatStavka Number;
      nRabatZaglavlje Number := Null;  -- po defaultu je null, ako postoji

                                       -- kasnije se setuje

   Begin

      -- provera da li postoji porez na svim stavkama dokumenta
      Open Porez_Cur( nGodina, cBroj, cVrstaDok );

      Loop
         Fetch Porez_Cur Into nPorez;
         Exit When Porez_Cur%NOTFOUND;

         -- ako porez na stavci nije definisan, raise
         If nPorez Is Null Then
            Raise_Application_Error(   -20200, 'Porez na stavci mora biti '||
                                       'definisan !' );
         End If;

      End Loop;

      Close Porez_Cur;

      -- provera da li je u zaglavlju dokumenta uneta vrsta izjave
      Begin

         Select Vrsta_Izjave
         Into nVrstaIzjave
         From Dokument
         Where Broj_Dok = cBroj And
               Vrsta_Dok = cVrstaDok And
               Godina = nGodina;
      Exception
         When NO_DATA_FOUND Then
            Raise_Application_Error(   -20201, 'Ne postoje}i dokument !' );
      End;

      -- ako vrsta izjave ne postoji, raise
      If nVrstaIzjave Is Null Then
         Raise_Application_Error(   -20202, 'Nije definisana vrsta '||
                                    'izjave !' );
      End If;

      -- provera da li je u zaglavlju dokumenta postoji rabat i spec_rabat
      -- dozvoljeno je da postoji samo jedna od ove dve vrste rabata
      Begin
         Select Rabat, Spec_Rabat
         Into nRabat, nSpecRabat
         From Dokument

         Where Broj_Dok = cBroj And
               Vrsta_Dok = cVrstaDok And
               Godina = nGodina;
      Exception
         When NO_DATA_FOUND Then
            Raise_Application_Error(   -20208, 'Dokument nije registrovan!' );
      End;

      -- ako ne prodje kroz raise, onda postavi vrednost za rabat na zaglavlju
      -- koja je potrebna za sledecu proveru( rabat na stavkama je isti kao i
      -- rabat na zaglavlju )
      If nRabat Is Not Null And nSpecRabat Is Not Null Then
            Raise_Application_Error(   -20204, 'Na dokumentu ne mogu '||
                                       'isovremeno da postoje obe vrste rabata !' );
      ElsIf nRabat Is Null And nSpecRabat Is Not Null Then
         nRabatZaglavlje := nSpecRabat;
      ElsIf nRabat Is Not Null And nSpecRabat Is Null Then
         nRabatZaglavlje := nRabat;
      End If;

      -- sada provera da li se rabat na stavkama slaze sa rabatom na zaglavlju
      Open Rabat_Cur( nGodina, cBroj, cVrstaDok );


      Loop
         Fetch Rabat_Cur Into nRabatStavka;
         Exit When Rabat_Cur%NOTFOUND;

         -- provera da li je definisan rabat na zaglavlju
         If nRabatZaglavlje Is Not Null Then
            -- ova provera samo ukoliko postoji rabat na zaglavlju
            -- ako se rabat na stavci razlikuje od rabata na zaglavlju
            If nRabatStavka != nRabatZaglavlje Then
               Raise_Application_Error(   -20205, 'Rabat na stavci mora biti '||
                                          'isti kao na zaglavlju !' );
            End If;
         End If;

      End Loop;

      Close Rabat_Cur;

   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje prijemnice u status: konacna verzija
   Procedure Prijemnica( nGodina Number, cBroj VarChar2, nMagacin Number,

                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '3', nGodina, cBroj, '2', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa narud`benicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji narud`benica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Narud`benicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno naru~ivanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||

                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||

                                  ''' je stornirana !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovana !' );
   End;
----------------------------------------------------------------------------
  -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje prijemnice u status: konacna verzija
   Procedure MedjuskladUl( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '71', nGodina, cBroj, NULL , nMagacin, nAutomatskiDodajProizvod );

   Exception
/*
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa narud`benicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji narud`benica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Narud`benicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno naru~ivanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||

                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );
*/
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
/*
      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||

                                  ''' je stornirana !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovana !' );
*/
   End;

----------------------------------------------------------------------------
   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje predatnice u status: konacna verzija
   Procedure Predatnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '1', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa radnim nalogom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji radni nalog ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );


      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Radnim nalogom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`ena predaja ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then

         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure Otpremnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is

      nTipDok Number ;
   Begin

      -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
      -- pre prevodjenja dokumenta u konacnu verziju
      -- ova procedura je bitna za otpremnicu, profakturu i nalogza otpremu

      -- kod interne otpremnice ( Tip_Dok = 23 ) ne postoji izjava, i nisu
      -- potrebne provere za rabat i porez ( jer su uvek 0 ), pa se preskace provera

      Select Tip_Dok
      Into nTipDok
      From Dokument
      Where Godina = nGodina And Broj_Dok = cBroj And Vrsta_Dok = 11 ;

      If nTipDok Not In (23, 203) Then
         Uslovi( nGodina, cBroj, '11' );
      End If;

      KonacnaVerzija( '11', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||

                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );

   End;
----------------------------------------------------------------------
-- 25.10.2006 Deja
  -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure MedjuskladIzl( nGodina Number, cBroj VarChar2, nMagacin Number,
                           nAutomatskiDodajProizvod Number := NULL ) Is

      nTipDok Number ;
   Begin

      -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
      -- pre prevodjenja dokumenta u konacnu verziju
      -- ova procedura je bitna za otpremnicu, profakturu i nalogza otpremu

      -- kod interne otpremnice ( Tip_Dok = 23 ) ne postoji izjava, i nisu
      -- potrebne provere za rabat i porez ( jer su uvek 0 ), pa se preskace provera

      Select Tip_Dok
      Into nTipDok
      From Dokument
      Where Godina = nGodina And Broj_Dok = cBroj And Vrsta_Dok = 71 ;

/*
      If nTipDok Not In (23, 203) Then
         Uslovi( nGodina, cBroj, '71' );
      End If;
*/
      KonacnaVerzija( '70', nGodina, cBroj, NULL , nMagacin, nAutomatskiDodajProizvod );

   Exception
/*
     When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||

                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

*/
      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
/*
      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
*/
   End;
----------------------------------------------------------------------
   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure OtpremnicaAmbalaze( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is

   Begin

      KonacnaVerzija( '61', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||

                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );

   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure OtpremnicaAmbalazeKupac( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is

   Begin

      KonacnaVerzija( '63', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||

                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );

   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za trebovanje u status: konacna verzija
   Procedure NalogZaTrebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                                nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '54', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate nabavku ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );


      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje trebovanja u status: konacna verzija
   Procedure Trebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '8', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa radnim nalogom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji radni nalog ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then

         Raise_Application_Error( -20002, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Radnim nalogom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno trebovanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||

                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je storniran !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Radni nalog ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje pocetnog stanja u status: konacna verzija
   -- uz izbor da li se magacin inicijalizuje ili ne
   Procedure PocetnoStanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL,
                            lInicijalizacija Boolean := TRUE ) Is

   Begin
      If lInicijalizacija Then  -- ako treba inicijalizacija magacina:
         -- prvo treba postaviti na nulu stanje svih proizvoda u magacinu za
         -- koji se radi pocetno stanje
         -- Rezervisana, Ocekivana i kolicina U_Kontroli se ne diraju. Zasto ?
         -- Mozda nije korektna logika, ali stvar je posmatrana ovako:
         -- Ocekivana i kolicina U_Kontroli se odnose na robu koja uslovno nije
         -- ni usla u magacin, pa te vrednosti ne bi trebalo da mogu naknadno
         -- nesto da poremete. Sto se rezervisane kolicine tice, ona ce, ako
         -- po prevodjenju pocetnog stanja u konacnu verziju, stanje bude manje
         -- od nje, da se postavi na istu vrednost kao stanje, sto nije bas
         -- korektno, ali bar u izvestajima nece da se pojavljuje da je
         -- rezervisano vise nego sto ima.
         -- U svakom slucaju, sve ovo nije bas detaljno razmotreno, i sigurno je
         -- da nije bas 'cisto'. Ali nekakav automatizam je morao da bude
         -- obezbedjen za slucaj da rucno nije sve bilo rascisceno (sto se tice
         -- ostalih dokumenata) pre formiranja pocetnog stanja
         Update Zalihe
         Set Stanje = 0, Stanje_Kontrolna = 0
         Where Org_Deo = nMagacin;
         -- Sva analitika se brise jer se stanje postavlja na nulu. Ne smeta sto
         -- su ocekivana i rezervisana kolicina ostale neizmenjene jer u
         -- dokumentima koji uticu na ove vrednosti ne figurise analitika.

         -- Sto se tice kolicine u_kontroli, ove kolicine se ionako ne vode
         -- analiticki dok ne prodju kontrolu, tako da ni one nisu problem
         Delete From Zalihe_Analitika
         Where Org_Deo = nMagacin;
      End If;

      -- sada prevede dokument u konacno stanje
      KonacnaVerzija( '21', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

      If lInicijalizacija Then  -- ako treba inicijalizacija magacina:
         -- sada iz magacina ukloni sve proizvode cije stanje je nula, ne
         -- ocekuju se niti su u kontroli, a ne pojavljuju se na dokumentu za
         -- pocetno stanje koji se obradjuje
         Delete From Zalihe
         Where Org_Deo = nMagacin And
               Stanje = 0 And Ocekivana = 0 And U_Kontroli = 0 And
               Proizvod NOT IN ( Select Distinct Proizvod
                                 From Stavka_Dok
                                 Where Vrsta_Dok = '21' AND
                                       Godina = nGodina AND
                                       Broj_Dok = cBroj );
         -- na kraju izjednacava rezervisanu kolicinu sa stanjem, tamo gde
         -- je ona veca od stanja

         Update Zalihe
         Set Rezervisana = Stanje
         Where Org_Deo = nMagacin And
               Rezervisana > Stanje;
      End If;

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje pocetnog stanja u status: konacna verzija
   -- uz obaveznu inicijalizaciju magacina
   Procedure PocetnoStanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      PKonacnaVerzija.PocetnoStanje( nGodina, cBroj, nMagacin,
                                     nAutomatskiDodajProizvod, TRUE );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje rashoda u status: konacna verzija
   Procedure Rashod( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '33', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
--      When Novi_Proizvod Then
--         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||

--                                  cExpProizvod || '''' || NewLine ||
--                                  'se prvi put javlja u magacinu ''' ||
--                                  To_Char( nMagacin ) || ''' !' || NewLine ||
--                                  'Da li dozvoljavate ulaz ?' ||
--                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po otpremnici u status: konacna verzija
   Procedure PovratnicaPoOtpremnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '13', nGodina, cBroj, '11', nMagacin, nAutomatskiDodajProizvod );


   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa otpremnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji otpremnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Otpremnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Otpremnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );


      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Otpremnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
      When Novi_proizvod Then
         Raise_Application_Error( -20008, 'Ne postoji proizvod''' || cExpProizvod ||
                                  ''' u magacinu !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po prijemnici u status: konacna verzija
   Procedure PovratnicaPoPrijemnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '5', nGodina, cBroj, '3', nMagacin, nAutomatskiDodajProizvod );


   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa prijemnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji prijemnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Prijemnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Prijemnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno dopremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );



      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Prijemnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po trebovanju u status: konacna verzija
   Procedure PovratnicaPoTrebovanju( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '28', nGodina, cBroj, '8', nMagacin, nAutomatskiDodajProizvod );

   Exception

      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa trebovanjem !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji trebovanje ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
        Raise_Application_Error( -20002, 'Trebovanje ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{eno !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Trebovanjem ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno trebovanje ' ||
                                  'materijala' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||

                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Trebovanje ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirano !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po predatnici u status: konacna verzija
   Procedure PovratnicaPoPredatnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '45', nGodina, cBroj, '1', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa predatnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji predatnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
        Raise_Application_Error( -20002, 'Predatnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Predatnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{ena predaja ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||

                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Predatnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje viska po popisu u status: konacna verzija
   Procedure VisakPoPopisu( nGodina Number, cBroj VarChar2, nMagacin Number ) Is

   Begin
      KonacnaVerzija( '19', nGodina, cBroj, NULL, nMagacin, 0 );


   Exception
      When Polazni_Ne_Postoji Then

         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje manjka po popisu u status: konacna verzija
   Procedure ManjakPoPopisu( nGodina Number, cBroj VarChar2, nMagacin Number ) Is

   Begin
      KonacnaVerzija( '20', nGodina, cBroj, NULL, nMagacin, 0 );

   Exception
      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then

         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno prijemnice u status: konacna verzija
   Procedure StornoPrijemnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '4', nGodina, cBroj, '2', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa narud`benicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji narud`benica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Narud`benica ''' || cExpBroj ||

                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Narud`benicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno naru~ivanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );


      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Narud`benica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno predatnice u status: konacna verzija
   Procedure StornoPredatnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '26', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||

                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtpremnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '12', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When  Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||

                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtpremnicaAmbalaze( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '62', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When  Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||

                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtprAmbalazeKupac( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '64', nGodina, cBroj, '10', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then

         Raise_Application_Error( -20000, 'Ne postoji veza sa nalogom za otpremu !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji nalog za otpremu ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{en !' );

      When  Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Nalogom za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije nalo`eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||

                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Nalog za otpremu ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovan !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno trebovanja u status: konacna verzija
   Procedure StornoTrebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL ) Is

   Begin
      KonacnaVerzija( '27', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'ne postoji u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Dozvoljavate odlazak u minus ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika

   -- kao pripremu za prevodjenje storno povratnice po otpremnici u status: konacna verzija
   Procedure StornoPovratnicaPoOtpremnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '31', nGodina, cBroj, '11', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa otpremnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji otpremnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Otpremnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Otpremnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||

                                  NewLine || 'nije izvr{eno otpremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Otpremnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po prijemnici u status: konacna verzija
   Procedure StornoPovratnicaPoPrijemnici( nGodina Number, cBroj VarChar2, nMagacin Number,

                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '30', nGodina, cBroj, '3', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa prijemnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji prijemnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Prijemnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Prijemnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno dopremanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||

                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Prijemnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po trebovanju u status: konacna verzija
   Procedure StornoPovratnicaPoTrebovanju( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin

      KonacnaVerzija( '32', nGodina, cBroj, '8', nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa trebovanjem !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji trebovanje ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
        Raise_Application_Error( -20002, 'Trebovanje ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{eno !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Trebovanjem ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno trebovanje ' ||
                                  'materijala' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );


      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );


      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Trebovanje ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirano !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po predatnici u status: konacna verzija
   Procedure StornoPovratnicaPoPredatnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '46', nGodina, cBroj, '1', nMagacin, nAutomatskiDodajProizvod );


   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa predatnicom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji predatnica ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
        Raise_Application_Error( -20002, 'Predatnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Predatnicom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{ena predaja ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );


      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Storniran Then
         Raise_Application_Error( -20007, 'Predatnica ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je stornirana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno rashoda u status: konacna verzija
   Procedure StornoRashod( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '34', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception

      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate ulaz ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za nabavku u status: konacna verzija
   Procedure NalogZaNabavku( nGodina Number, cBroj VarChar2, nMagacin Number,
                             nAutomatskiDodajProizvod Number := NULL ) Is
   Begin

      KonacnaVerzija( '38', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate nabavku ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje narudzbenica u status: konacna verzija

   Procedure Narudzbenica( nGodina Number, cBroj VarChar2, nMagacin Number,
                           nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '2', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate nabavku ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje profaktura u status: konacna verzija
   Procedure Profaktura( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL ) Is
   Begin

      -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
      -- pre prevodjenja dokumenta u konacnu verziju
      -- ova procedura je bitna za otpremnicu, profakturu i nalogza otpremu
      Uslovi( nGodina, cBroj, '9' );

      KonacnaVerzija( '9', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Novi_Proizvod Then
         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate izlaz ?' ||
                                  To_Char( nExpStavka ) );


      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za otpremu u status: konacna verzija
   Procedure NalogZaOtpremu( nGodina Number, cBroj VarChar2, nMagacin Number,
                             nAutomatskiDodajProizvod Number := NULL ) Is
   Begin

      -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
      -- pre prevodjenja dokumenta u konacnu verziju
      -- ova procedura je bitna za otpremnicu, profakturu i nalogza otpremu
      Uslovi( nGodina, cBroj, '10' );

      KonacnaVerzija( '10', nGodina, cBroj, '9', nMagacin, nAutomatskiDodajProizvod );


   Exception
      When Veza_Ne_Postoji Then
         Raise_Application_Error( -20000, 'Ne postoji veza sa profakturom !' );

      When Vezni_Dokument_Ne_Postoji Then
         Raise_Application_Error( -20001, 'Ne postoji profaktura ''' ||
                                  cExpBroj || '/' || To_Char( nExpGodina ) ||
                                  '''!' );

      When Vezni_Dokument_Nije_Zavrsen Then
         Raise_Application_Error( -20002, 'Profaktura ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' nije potpuno zavr{ena !' );

      When Ne_Postoji_Na_Veznom Then
         Raise_Application_Error( -20003, 'Profakturom ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) || '''' ||
                                  NewLine || 'nije izvr{eno rezervisanje ' ||
                                  'proizvoda' || NewLine || 'pod {ifrom ''' ||
                                  cExpProizvod || ''' !' ||
                                  To_Char( nExpStavka ) );

      When Novi_Proizvod Then

         Raise_Application_Error( -20004, 'Proizvod pod {ifrom ''' ||
                                  cExpProizvod || '''' || NewLine ||
                                  'se prvi put javlja u magacinu ''' ||
                                  To_Char( nMagacin ) || ''' !' || NewLine ||
                                  'Da li dozvoljavate otpremu ?' ||
                                  To_Char( nExpStavka ) );

      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );

      When Vezni_Dokument_Je_Realizovan Then
         Raise_Application_Error( -20008, 'Profaktura ''' || cExpBroj ||
                                  '/' || To_Char( nExpGodina ) ||
                                  ''' je ve} potpuno realizovana !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika

   -- kao pripremu za prevodjenje radnih naloga u status: konacna verzija
   Procedure RadniNalog( nGodina Number, cBroj VarChar2 ) Is
      -- za zakljucavanje polaznog dokumenta i za proveru njegovog statusa
      Cursor ZaglavljePolaznog( nGod Number, cBr VarChar2 ) Is
         Select Status
         From Radni_Nalog
         Where Godina = nGod And
               Broj_Dok = cBr
         For UpDate Of Status;

      nStatus Number;
   Begin
      -- prvo ide zakljucavanje polaznog dokumenta i provera njegovog statusa
      Open ZaglavljePolaznog( nGodina, cBroj );
      Fetch ZaglavljePolaznog Into nStatus;

      If ZaglavljePolaznog % NOTFOUND Then
         Close ZaglavljePolaznog;
         Raise Polazni_Ne_Postoji;
      End If;
      If nStatus != 0 Then
         Close ZaglavljePolaznog;
         Raise Polazni_Nije_U_Radnoj_Verziji;

      End If;

      -- zatvara cursor zaglavlje polaznog dokumenta
      Close ZaglavljePolaznog;
   Exception
      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje sastavnica u status: konacna verzija
   Procedure Sastavnica( nGodina Number, cBroj VarChar2 ) Is
      -- za zakljucavanje polaznog dokumenta i za proveru njegovog statusa
      Cursor ZaglavljePolaznog( nGod Number, cBr VarChar2 ) Is
         Select Status
         From Sastavnica_Zag
         Where Godina = nGod And

               Broj_Dok = cBr
         For UpDate Of Status;

      nStatus Number;
   Begin
      -- prvo ide zakljucavanje polaznog dokumenta i provera njegovog statusa
      Open ZaglavljePolaznog( nGodina, cBroj );
      Fetch ZaglavljePolaznog Into nStatus;

      If ZaglavljePolaznog % NOTFOUND Then
         Close ZaglavljePolaznog;
         Raise Polazni_Ne_Postoji;
      End If;
      If nStatus != 0 Then
         Close ZaglavljePolaznog;
         Raise Polazni_Nije_U_Radnoj_Verziji;
      End If;

      -- zatvara cursor zaglavlje polaznog dokumenta
      Close ZaglavljePolaznog;
   Exception
      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||

                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then
         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje dokumenta za promenu lokacije
   -- u status: konacna verzija
   Procedure PromenaLokacije( nGodina Number, cBroj VarChar2, nMagacin Number,
                              nAutomatskiDodajProizvod Number := NULL ) Is
   Begin
      KonacnaVerzija( '44', nGodina, cBroj, NULL, nMagacin, nAutomatskiDodajProizvod );

   Exception
      When Polazni_Ne_Postoji Then
         Raise_Application_Error( -20005, 'Dokument ne postoji ! ' ||
                                          'Mogu}e je da je neki drugi korisnik u ' ||
                                          'me|uvremenu obrisao dokument.' );

      When Polazni_Nije_U_Radnoj_Verziji Then

         Raise_Application_Error( -20006, 'Dokument je ve} preveden ' ||
                                          'u kona~nu verziju !' );
   End;

End;
/
