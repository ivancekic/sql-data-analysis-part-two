CREATE OR REPLACE Package PKonacnaVerzija Is

   -- Procedura proverava uslove vezane za porez, rabat, vrstu izjave
   -- pre prevodjenja dokumenta u konacnu verziju
   Procedure Uslovi( nGodina Number, cBroj VarChar2, cVrstaDok VarChar2 );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje prijemnice u status: konacna verzija
   Procedure Prijemnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

--------------------------------------------------------------------------------------
   -- 25.10.2006 DEJA
   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje MEDJUSKLADISNICE IZLAZNE u status: konacna verzija
   Procedure MedjuskladIzl( nGodina Number, cBroj VarChar2, nMagacin Number,
                          nAutomatskiDodajProizvod Number := NULL );                  

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje MEDJUSKLADISNICE ULAZNE u status: konacna verzija
   Procedure MedjuskladUl( nGodina Number, cBroj VarChar2, nMagacin Number,
                          nAutomatskiDodajProizvod Number := NULL );
                          
--------------------------------------------------------------------------------------
   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje predatnice u status: konacna verzija
   Procedure Predatnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure Otpremnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure OtpremnicaAmbalaze( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje otpremnice u status: konacna verzija
   Procedure OtpremnicaAmbalazeKupac( nGodina Number, cBroj VarChar2, nMagacin Number,
                                      nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za trebovanje u status: konacna verzija
   Procedure NalogZaTrebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                                nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje trebovanja u status: konacna verzija
   Procedure Trebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje pocetnog stanja u status: konacna verzija
   -- uz izbor da li se magacin inicijalizuje ili ne
   Procedure PocetnoStanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL,
                            lInicijalizacija Boolean := TRUE );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje pocetnog stanja u status: konacna verzija
   -- uz obaveznu inicijalizaciju magacina
   Procedure PocetnoStanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL );


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje rashoda u status: konacna verzija
   Procedure Rashod( nGodina Number, cBroj VarChar2, nMagacin Number,
                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po otpremnici u status: konacna verzija
   Procedure PovratnicaPoOtpremnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po prijemnici u status: konacna verzija
   Procedure PovratnicaPoPrijemnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po trebovanju u status: konacna verzija
   Procedure PovratnicaPoTrebovanju( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje povratnice po predatnici u status: konacna verzija
   Procedure PovratnicaPoPredatnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje viska po popisu u status: konacna verzija
   Procedure VisakPoPopisu( nGodina Number, cBroj VarChar2, nMagacin Number );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje manjka po popisu u status: konacna verzija
   Procedure ManjakPoPopisu( nGodina Number, cBroj VarChar2, nMagacin Number );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno prijemnice u status: konacna verzija
   Procedure StornoPrijemnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno predatnice u status: konacna verzija
   Procedure StornoPredatnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtpremnica( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtpremnicaAmbalaze( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno otpremnice u status: konacna verzija
   Procedure StornoOtprAmbalazeKupac( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );


   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno trebovanja u status: konacna verzija
   Procedure StornoTrebovanje( nGodina Number, cBroj VarChar2, nMagacin Number,
                         nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po prijemnici u status: konacna verzija
   Procedure StornoPovratnicaPoPrijemnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po otpremnici u status: konacna verzija
   Procedure StornoPovratnicaPoOtpremnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po trebovanju u status: konacna verzija
   Procedure StornoPovratnicaPoTrebovanju( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno povratnice po predatnici u status: konacna verzija
   Procedure StornoPovratnicaPoPredatnici( nGodina Number, cBroj VarChar2, nMagacin Number,
                                     nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje storno rashoda u status: konacna verzija
   Procedure StornoRashod( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za nabavku u status: konacna verzija
   Procedure NalogZaNabavku( nGodina Number, cBroj VarChar2, nMagacin Number,
                             nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje narudzbenica u status: konacna verzija
   Procedure Narudzbenica( nGodina Number, cBroj VarChar2, nMagacin Number,
                           nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje profaktura u status: konacna verzija
   Procedure Profaktura( nGodina Number, cBroj VarChar2, nMagacin Number,
                            nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje naloga za otpremu u status: konacna verzija
   Procedure NalogZaOtpremu( nGodina Number, cBroj VarChar2, nMagacin Number,
                             nAutomatskiDodajProizvod Number := NULL );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje radnih naloga u status: konacna verzija
   Procedure RadniNalog( nGodina Number, cBroj VarChar2 );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje sastavnica u status: konacna verzija
   Procedure Sastavnica( nGodina Number, cBroj VarChar2 );

   -- Procedura azurira tabele Zalihe i Zalihe_Analitika
   -- kao pripremu za prevodjenje dokumenta za promenu lokacije
   -- u status: konacna verzija
   Procedure PromenaLokacije( nGodina Number, cBroj VarChar2, nMagacin Number,
                              nAutomatskiDodajProizvod Number := NULL );
End;
/
