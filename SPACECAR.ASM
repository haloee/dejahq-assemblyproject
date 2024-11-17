Pila    SEGMENT PARA STACK
    db      64 DUP('DADA007 ')              ;8 * 64 =512 byte, segit nyomon kovetni, mennyit hasznal a verem.
Pila    ENDS                                 ;Ha 512 byte-nal tobb hasznalodik el, akkor a 'DADA007 ' felirat torlodik.
                                            ;A maximalis meret minden szegmensre 64 kbyte.

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;VALTOZOK SZEGMENSE
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
Dati    SEGMENT PARA
    ;karakterlancok, melyek a program futasa kozben jelennek meg a kepernyon
    ;nb: 13 -> uj sor, 10 -> sor vege
        mex1    db      '                         ----> S P A C E - C A R <----',13,10,'$' ;30 KARAKTER -> 25 HELY SZERKESZTES JOBBRA A KOZEPRE ALLITASHOZ
        mex2    db      ' Cel, hogy elkeruljuk az aszteroidakat es gyujtsunk minel tobb ermet',13,10,'$'
        mex2b   db      ' a rekord megdontesehez!',13,10,'$'
        mex3    db      ' Mozgashoz hasznalja a nyilbillentyuket (Jobbra es Balra)',13,10,'$'
        mex4    db      ' A szivek az eletek, maximum 5-ot gyujthet beloluk',13,10,'$'
        mex5    db      ' Ha elfogynak az eletek, veget er a jatek',13,10,'$'
        mex6    db      ' Nyil Fel/Le: Novel/Csokkent a szintet (sebesseg)',13,10,'$'
        mEsc    db      ' ESC:         Kilep azonnal a jatekbol',13,10,'$'
        mPausa  db      ' P:           Jatek szuneteltetese',13,10,'$'
        mInizio db      ' Nyomd az ENTER-t a jatek inditasahoz',13,10,'$'

        cInizio db      '                                   ','$'        ;mInizio torlesere, kepernyo torles nelkul
        lEsci   db      'Nyomd az ENTER-t a DOS-ba valo visszatereshez  ','$'

        lPause  db      'SZUNET                              ','$'
        lLose   db      'JATEK VEGE                          ','$'
        lWin    db      'Elerte a maximalis pontszamot!','$'

        fScore  db      'Vegso pontszam: ','$'
        fLife   db      'Maradek eletek: ','$'

        lDead   db      'UTKOZOTT EGY ASZTEROIDAVAL!','$'
        lTasto  db      'Nyomjon meg egy gombot a folytatashoz    ','$'
        lInvio  db      'Nyomja meg az ENTER-t a folytatashoz       ','$'

        mLife   db      'ELET: ','$'
        mLevel  db      'SZINT: ','$'
        mScore  db      'PONTSZAM: ','$'

        lLife   db      '+1 ELET     ','$'
        lScore  db      '+1 PONTSZAM    ','$'
        lLevelU db      '+1 SZINT    ','$'
        lLevelD db      '-1 SZINT    ','$'
        life    dw      3       ;kezdo eletek: 3
        level   dw      1       ;kezdo szint: 1
        score   dw      0H      ;kezdo pontszam: 0
        tLevel  dw      10H     ;ciklusok az elso szinten, 16=10H

        maxScore dw     1000     ;maximalis pontszam a jatek vegehez

        lVuoto  db      '                   ','$'

    ;veletlenszam generalashoz hasznalt valtozok
        PrimoIN  DB     00H           ; Elso futasi jelzo (= 0 igen; <> 0 nem)
        Rnd_Lo   DW     ?             ; veletlenszam aktualis 32 bites erteke
        Rnd_Hi   DW     ?
        Costante DW     8405H         ; Szorzo erteke

Dati    ENDS







;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;A PROGRAM SZEGMENSE
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
_prog    SEGMENT  PARA 'CODE'    ;Code Segment, Stack Segment es Data Segment foglalasa
    ASSUME  CS:_prog,        SS:Pila,        DS:Dati        ;ASSUME kikeni a megfelelo szegmenst az osszes szimbolumra a szegmensen belul
    ORG 0100H       ;szabadon hagyom az elso 100H helyet
    INIZIO: JMP     Main    ;az Main cimketol indul

    ;=========================================================================================================
    ;BILLENTYUK (KONSTANTAK)
    ;=========================================================================================================
    kESC    EQU     1bh             ;ESC billentyu
    kINVIO  EQU     0dh             ;ENTER billentyu
    kSU     EQU     4800h           ;fel nyil billentyu (mozgas felfele)
    kGIU    EQU     5000h           ;le nyil billentyu (mozgas lefele)
    kDX     EQU     4d00h           ;jobb nyil billentyu (mozgas jobbra)
    kSX     EQU     4b00h           ;bal nyil billentyu (mozgas balra)
    limDX   EQU     27              ;jobboldali hatar a hajo szamara (keret jobb oszlopa)
    limSX   EQU     2               ;baloldali hatar a hajo szamara (keret bal oszlopa)

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;MAKROK
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
setCur MACRO sor,oszlop       ;Makro, amely kivalasztja, hova helyezze a kurzort
    PUSH DX
    MOV DH,sor             ;sor
    MOV DL,oszlop          ;oszlop
    CALL posCur             ;hivja a posCur eljarast - INT10H 02H, amely pozicionalja a kurzort
    POP DX
ENDM
;=========================================================================================================
stpChrT MACRO karakter              ;nyomtatas TTY modban (frissiti a kurzort)
    PUSH AX
    MOV AL,karakter             ;kivalasztja a megadott karaktert parameterkent
    CALL writeTTY           ;hivja az eljarast
    POP AX
ENDM
;=========================================================================================================
stpChrC MACRO karakter,db,szin      ;n karakter nyomtatasa szinesen
    PUSH AX
    PUSH CX
    MOV AL,karakter             ;kivalasztja a megadott karaktert parameterkent
    MOV CX,db
    MOV BL,szin
    CALL writeCOL           ;hivja az eljarast
    POP CX
    POP AX
ENDM
;=========================================================================================================
stpChrBN MACRO char             ;fekete-feher karakter nyomtatasa
	PUSH AX
	MOV AL,char             ;kivalasztom a parameternel atadott karaktert
	CALL writeBN            ;meghivom az eljarast
	POP AX
ENDM
;=========================================================================================================
Random  MACRO num       ;szukseges esetben ne felejts PUSH AX-ot vegezni
			;PL: num=10 a random szam 0-tol 9-ig tart
	MOV AX,num      ;beallitja az AX erteket a Random eljarashoz
	CALL rand
ENDM
;=========================================================================================================
stpMex  MACRO mex       ;egy uzenet kiirasa a memoriaban (Adat szegmens)
	PUSH AX
	PUSH BX
	PUSH DX
	MOV AX,SEG Dati
	MOV DS,AX
	MOV DX,OFFSET mex
	MOV AH,09H
	INT 21H
	POP DX
	POP BX
	POP AX
ENDM
;=========================================================================================================
Ritardo MACRO tick      ;kesleltetest hozok letre (1 tick = 0,55 ms -> 18H tick = 1 masodperc)
	PUSH CX
	MOV CX,tick
	CALL delay      ;meghivom a delay eljarast, amely az orara epul
	POP CX
ENDM
;=========================================================================================================

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;A PROGRAM KEZDETE
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================

;MEGJ:   DX-be mentem a hajocska poziciojat
;       BX-be mentem az akadaly/penz/eleterot (BL=Tipus)  x=aszteroida, v=eletero, m=penz
;       CX a ciklus szamlaloja

Main:           CALL cls        ;kepernyo torlese
		setCur 0,0
		stpMex mex1     ;utasitasok kiirasa a kepernyore
		setCur 2,0
		stpMex mex2
		stpMex mex2b
		stpMex mex3
		stpMex mex4
		stpMex mex5
		stpMex mex6
		stpMex mEsc
		stpMex mPausa
		setCur 11,1
		stpMex lTasto
		CALL outCur
		CALL waitKey    ;var egy gombnyomast a folytatashoz

Start:          ;minden alkalommal, amikor egy aszteroidanak utkozunk, innen indulunk ujra
		CALL cls        ;kepernyo torlese
		CALL wBordo     ;keret rajzolasa

	;ELETEROK KIIRASA
		setCur 4,40
		stpMex mLife
		setCur 4,50
		stpChrC 03H,life,04H    ;szivek nyomtatasa

	;SZINT KIIRASA
		setCur 6,40
		stpMex mLevel
		setCur 6,50
		stpChrC 09H,level,09H   ;pontok nyomtatasa (a szint szamat jelkepezik)

	;PONTSZAM KIIRASA
		setCur 8,40
		stpMex mScore
		setCur 8,50
		MOV AX,score
		CALL word2dec           ;pontszam nyomtatasa

	;A HAJO ELHELYEZESA LEFELE KOZEPEN
		MOV DH,20       ;sor
		MOV DL,14       ;oszlop
		CALL setCar     ;a hajo pozicionalasa

		setCur 15,40    ;UZENETEK NYOMTATASANAK ZONAJABA LEPEK
		stpMex mInizio  ;szint kezdete, var egy entert
		CALL outCur
reqINVIO:       CALL waitKey    ;az ENTER billentyut varom
		CMP AL,kINVIO
		JNE reqINVIO
		setCur 15,40
		stpMex cInizio

		;CALL outCur    ;kurzor elrejtese
		MOV BX,0000H    ;minden ciklusban inicializalom az akadaly/eletero/penz vezerlot
Ciclo:          MOV CH,BYTE PTR tLevel   ;beallitom az indulasi szintet (sebesseg)
		MOV CL,0        ;a ciklus szamlalojat inicializalom

		CMP CH,CL       ;ha szintet valtottam es
		JBE Continue3   ;CH kisebb vagy egyenlo CL-vel -> ujrainditom a ciklust
				;ha ezt az ellenorzest nem teszem meg, a program lefagyhat
				;peldául ha CL 0AH es CH elerte a 0BH-t a szintvaltasnal
				;JBE = jump below or equal

		PUSH DX
		setCur 15,40    ;interaktiv uzenet torlese
		stpMex lVuoto   ;az elozo ciklusbol
		POP DX
		CMP BL,'m'      ;ha penzt szedtem ossze, novekszik a pontszam
		 JE addMon
		CMP BL,'v'
		 JE addVita     ;ha szivet szedtem ossze, novekszik az eletero (ha meg nem 5)

Continue3:      JMP AspKey

addMon:         PUSH AX         ;penzt szedtem ossze

MOV AX,score   ;lehetne közvetlenül "INC score" is
;INC AX         ;növelem a pontszámot
ADD AX,level    ;1 egység helyett a szint értékét adom hozzá
MOV score,AX
setCur 8,50    ;a kurzort a PONTSZÁM helyére állítom
CALL word2dec  ;kiírom a score változó ASCII/decimális értékét
setCur 15,40   ;a kurzort az ÜZENETEK helyére állítom
stpMex lScore  ;kiírom: +1 PONTSZÁM
POP AX
MOV BX,0000H    ;az akadályok/életek/pénzek ellenőrzését inicializálom
JMP AspKey

addVita:        CMP life,5      ;szívet szereztem
JAE life5       ;ha az élet 5 vagy több, nem ad hozzá új életet
PUSH AX
MOV AX,life
INC AX         ;növelem az élet változót
MOV life,AX
setCur 4,50    ;a kurzort az ÉLET helyére állítom
stpChrC 03H,life,04H   ;annyi piros szívet ír ki, amennyi az élet
setCur 15,40   ;a kurzort az ÜZENETEK helyére állítom
stpMex lLife   ;kiírom: +1 ÉLET
POP AX
life5:          MOV BX,0000H    ;az akadályok/életek/pénzek ellenőrzését inicializálom
JMP AspKey

AspKey:
CMP BL,'x'      ;ellenőrzöm, hogy eltaláltam-e egy aszteroidát
JE Dead2        ;ha eltaláltam, megyek a Dead2 címkéhez
CALL setCar     ;ellenőrzöm, hogy ütköztem-e akadállyal, vagy szereztem-e érmét/életet, és pozicionálom az űrhajót
Ritardo 01H     ;másodpercenként 18 "várakozás"
INC CL          ;növelem a 18 várakozás számlálót
CMP CL,CH       ;ha CL=CH, akkor vége a ciklusnak (eltelt 18 várakozás, ha a ciklus egy másodperc)
JE Continue2    ;lejjebb lépek egy sorral
CALL pressKey   ;különben ellenőrzöm, hogy lenyomtak-e egy gombot
JZ AspKey       ;ha nem nyomták meg, tovább várok
CALL waitKey    ;különben ellenőrzöm, melyik gombot nyomták meg
CMP AL,kESC     ;megnyomom az ESC-t
JE Esci2        ;kilépek DOS-ba
CMP AL,'P'      ;megnyomom a P-t
JE I_Pause      ;megállítom a játékot
CMP AL,'p'      ;megnyomom a p-t (kisbetűs)
JE I_Pause      ;megállítom a játékot
CMP AX,kDX      ;megnyomom a Jobbra nyilat - kDX EQU 4D00H
JE Destra2
CMP AX,kSX      ;megnyomom a Balra nyilat - kSX EQU 4B00H
JE Sinistra2
CMP AX,kSU      ;megnyomom a Fel nyilat
JE Su2
CMP AX,kGIU     ;megnyomom a Le nyilat
JE Giu2
;CMP AL,'h'      ;100 pontot növel
;JE HintA2
;CMP AL,'H'      ;100 pontot csökkent
;JE HintB2
JMP Tasto2      ;megyek a lenyomott gomb kiírásához

;----------ugrás címkék túl hosszú ugrásokhoz-------------
;Win2:           JMP Win
Dead2:          JMP Dead
Destra2:        JMP Destra
Sinistra2:      JMP Sinistra
Esci2:          JMP Esci
Continue2:      JMP Continue
Tasto2:         JMP Tasto
Su2:            JMP Su
Giu2:           JMP Giu
;HintA2:         JMP HintA
;HintB2:         JMP HintB
;AspKey2:        JMP AspKey
;------------ugrás címkék túl hosszú ugrásokhoz-----------

;-----PAUSE kezelés------------------------------
I_Pause:        PUSH AX
PUSH BX
PUSH CX
PUSH DX
setCur 15,40    ;kiírom "PAUSE" az ÜZENETEK helyére
stpMex lPause
Pause:          CALL waitKey    ;várakozom egy gombnyomásra
CMP AL,kESC     ;ESC gomb
JE Esci2        ;megyek a kilépéshez
CMP AL,'P'      ;P gomb
JE F_Pause      ;befejezem a szünetet
CMP AL,'p'      ;p gomb
JE F_Pause      ;befejezem a szünetet
JMP Pause       ;különben folytatom a szünetet -> loop Pause
F_Pause:        setCur 15,40    ;törlöm a "PAUSE" kiírást
stpMex lVuoto
POP DX
POP CX
POP BX
POP AX
JMP AspKey      ;visszatérek az AspKey-hez
;-----PAUSE kezelés-------------------------------

AspKey2:        JMP AspKey

Destra:         ;az űrhajó jobbra mozgatása
CMP DL,limDX    ;ellenőrzöm, hogy az űrhajó elérte-e a jobb oldali szélét
JE AspKey2      ;ha elérte a jobb szélt és tovább mennék jobbra, a program megállít itt
INC DX         ;különben jobbra mozdítom egy karakterrel
PUSH DX
SUB DX,2       ;a kurzort oda helyezem, ahol az űrhajó előtte volt
CALL posCur
stpChrBN ' '   ;egy ' ' karaktert helyezek balra, ahol előtte az űrhajó volt
POP DX
JMP AspKey      ;várok a következő gombra

Sinistra:       ;az űrhajó balra mozgatása
CMP DL,limSX    ;ellenőrzöm, hogy az űrhajó elérte-e a bal oldali szélét
JE AspKey2      ;ha elérte a bal szélt és tovább mennék balra, a program megállít itt
DEC DX         ;különben balra mozdítom egy karakterrel
PUSH DX
ADD DX,2       ;a kurzort oda helyezem, ahol az űrhajó előtte volt
CALL posCur
stpChrBN ' '   ;egy ' ' karaktert helyezek balra, ahol előtte az űrhajó volt
POP DX
JMP AspKey      ;várok a következő gombra

Su:             ;szint felfelé
CMP level,8     ;ellenőrzöm, hogy a szint 8-e
JAE level8      ;ha a szint 8 vagy több, nem ad több szintet
PUSH AX
MOV AX,level   ;különben hozzáad egy szintet
INC AX
MOV level,AX
MOV AX,tLevel ;csökkenti a ciklus időtartamát 2 tick-kel
SUB AX,2
MOV tLevel,AX
setCur 6,50    ;a kurzort a SZINT helyére állítom
stpChrC 09H,level,09H  ;kiírja a szintek számát (kék pontok)
setCur 15,40   ;a kurzort az ÜZENETEK helyére állítom
stpMex lLevelU ;kiírja: +1 SZINT
POP AX
level8:          MOV BX,0000H    ;az akadályok/életek/pénzek ellenőrzését inicializálom
JMP aspKey

Giu:            ;szint lefelé

		CMP level,1
		JBE level1  ;ha a szint kisebb vagy egyenlo, mint 1, akkor nem csokkentem a szintet
	PUSH AX
	 MOV AX,level
	 DEC AX     ;kulonben csokkentem a szintet
	 MOV level,AX
	  MOV AX,tLevel ;noveltem a ciklus idotartamat 2 tickkel
	  ADD AX,2
	  MOV tLevel,AX
	 setCur 6,50
	 stpMex lVuoto  ;torlom az elozo szinteket, hogy kevesebb pont jelenjen meg (kulonben nem latszik a szintek csokkentese)
	 setCur 6,50    ;a kurzort a LEVEL zona helyere allitom
	 stpChrC 09H,level,09H  ;kiirja a szint szamat (kek pontok)
	 setCur 15,40   ;a kurzort a UZENETEK zonaba helyezem
	 stpMex lLevelD ;kiirja: -1 SZINT
	POP AX
level1:          MOV BX,0000H    ;inicializalom az akadaly/elet/penz vezerlot
	JMP aspKey


Tasto:          ;ha barmilyen gombot megnyomok, nem tortenik semmi
	;a cimket meghagyom, ha kesobb mas gombokat akarok hasznalni
	;vagy ha azt akarom, hogy a program csinaljon valamit altalanos gombokkal
	;kontrollkaraktereket irok ki
	;PUSH DX
	;setCur 20,35
	;stpChrBN AL
	;POP DX
	JMP AspKey


Continue:       CALL goGIU      ;egy sorral lejjebb mozgatom az akadalyokat
		;most megrajzolom az uj akadalyokat/eletet/penzt (kulonbozo valoszinusegekkel)
		Random 99      ;veletlenszam 0 es 99 kozott (100 szam osszesen)
		CMP AX,95
		 JAE Vita        ;nagyobb vagy egyenlo, mint 95 -> elet (5% valoszinuseg)
		CMP AX,25
		 JB Moneta      ;kisebb, mint 25 -> penz (25% valoszinuseg)
		CALL wOst       ;kulonben -> rajzolok egy akadalyt (a maradek 73% valoszinuseg)
		JMP Next

Vita:           CALL wLife      ;kirajzolok egy eletet
		JMP Next
Moneta:         CALL wMon       ;kirajzolok egy penzt
		JMP Next

Dead:           ;PUSH AX
		;MOV AX,life
		;DEC AX
		;MOV life,AX
		;POP AX
		DEC life        ;csokkentek egy eletet
		CMP life,0      ;ha az elet nulla -> Game Over
		JE Lose
		 CALL setCar    ;kulonben ujrainditom a jatekot egy elet kevesebbel
		 PUSH DX
		 setCur 4,50            ;a kurzort az ELET zona helyere allitom
		 stpChrC 03H,life,04H   ;frissitem a szivecskek szamat
		 setCur 15,40           ;a kurzort az UZENETEK zonaba helyezem
		 stpMex lDead           ;kiirja az uzenetet: "Nekiutkoztel egy aszteroidanak"
		 setCur 16,40
		 stpMex lInvio          ;kiirja: "Nyomj entert a folytatashoz"
		 POP DX


aspINVIO:        CALL waitKey           ;megvarom az ENTER gombot
		CMP AL,kINVIO           ;a jatek ujrainditasahoz egy elet kevesebbel
		JNE aspINVIO
		JMP Start


Next:           CALL outCur     ;elrejtem a kurzort

		PUSH AX         ;ellenorzom, hogy elertem-e a maximalis pontszamot
		MOV AX,maxScore ;nem tudok osszehasonlitast vegezni ket valtozoval
		CMP score,AX    ;ezert az egyiket AX-be teszem
		POP AX
		JAE Win

		JMP Ciclo       ;folytatom a ciklust es ugrok a Ciclo cimkere

Lose:           ;CALL cls
		PUSH DX
		setCur 15,40    ;a kurzort az UZENETEK zonaba helyezem
		stpMex lLose    ;kiirja GAME OVER
		POP DX
		CALL setCar
		JMP Exit

Win:            PUSH DX
		setCur 15,40
		stpMex lWin     ;kiirja a gyozelem uzenetet
		POP DX
		CALL setCar

Exit:           setCur 17,40
		stpMex fScore   ;kiirja a vegso pontszamot
		setCur 17,59    ;a pontszam ertekenek zonaja
		PUSH AX
		MOV AX,score
		CALL word2dec   ;a pontszam decimális erteke
		POP AX
		;POP DX
		CALL waitKey    ;megvar egy gombnyomast



Esci:           setCur 19,40
		stpMex lEsci    ;kiirja a kilepes uzenetet
waitINV:        CALL waitKey    ;megvarja az entert a kilepeshez
		CMP AL,kINVIO
		JNE waitINV
		CALL cls
		CALL tornaDOS   ;meghivja az eljarast a DOS-hoz valo visszatereshez


;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;ELJARASOK
;---------------------------------------------------------------------------------------------------------
;============================================================================
wBordo PROC NEAR        ;megrajzolja a jatek keretet
		;FELSŐ SOR KIRAJZOLÁSA
		setCur 0,0      ;kurzort a bal felso sarokba helyezi
		stpChrT 0DAH    ;kirajzolja a bal felso sarok karakteret
		MOV CX,28       ;beallitja a ciklust 28 ismetlesre (oszlopok)
CicloR1:        stpChrT 0C4H    ;kirajzolja a felso vonalat
		LOOP CicloR1    ;amig el nem eri a 29. oszlopot
		stpChrT 0BFH    ;kirajzolja a jobb felso sarok karakteret

		;BAL OLDALI OSZLOP KIRAJZOLÁSA
		MOV DH,01H      ;beallitja a sort 2-re
		MOV DL,00H      ;beallitja az oszlopot 0-ra (fix) - elso oszlop
		MOV CX,20       ;beallitja a ciklust 20 ismetlesre (sorok)
CicloC1:        CALL posCur     ;kurzort DH,DL-be helyezi (sor,oszlop)
		stpChrT 0B3H    ;kirajzolja a | karaktert a bal oldali oszlophoz
		inc DH          ;noveli a sor szamlalot (lejjebb megy)
		LOOP CicloC1    ;20 alkalommal

		;JOBB OLDALI OSZLOP KIRAJZOLÁSA
		MOV DH,01H      ;beallitja a sort 2-re
		MOV DL,29       ;beallitja az oszlopot 29-re (fix) - 30. oszlop
		MOV CX,0020     ;beallitja a ciklust 20 ismetlesre (sorok)
CicloC2:        CALL posCur     ;kurzort DH,DL-be helyezi (sor,oszlop)
		stpChrT 0B3H     ;kirajzolja a | karaktert a jobb oldali oszlophoz
		inc DH          ;noveli a sor szamlalot (lejjebb megy)
		LOOP CicloC2    ;20 alkalommal

		;ALSÓ SOR KIRAJZOLÁSA
		setCur 21,0     ;kurzort a 22. sor 0. oszlopaba helyezi
		stpChrT 0C0H     ;kirajzolja a bal also sarok karakteret
		MOV CX,28     ;beallitja a ciklust 28 ismetlesre (oszlopok)
CicloR2:        stpChrT 0C4H     ;kirajzolja a vonalat az also sorhoz
		LOOP CicloR2    ;28 alkalommal
		stpChrT 0D9H     ;kirajzolja a jobb also sarok karakteret

		;LETREHOZTAM EGY 22 SOR X 30 OSZLOP MERETU TEGALAPOT


wBordo  ENDP
;============================================================================
rand    PROC    NEAR        ;eljaras, amely veletlenszamot hoz letre 0 < n < AX tartomanyban
	OR      AX,AX           ;ha a tartomanykent megadott ertek
	JNZ     Rand_1          ;nulla, az eljaras azonnal leall (ervenytelen ertek!)
	RET                     ;visszater az eljarasbol

Rand_1: PUSH    BX          ;elmenti az eljaras altal hasznalt regisztereket
	PUSH    CX
	PUSH    DX
	PUSH    DI
	PUSH    DS
	PUSH    AX              ;elmenti a tartomany erteket, amely bemenetkent
							;erkezett (a vegen lesz felhasznalva)
	LEA     DI,PrimoIN      ;ellenorzi, hogy ez-e az elso meghivas
	CMP Byte Ptr DS:[DI],00H ;az eljaras elso meghivasakor kesleltetest general
	JNE     Rand_2          ;ha NEM ez az elso, kiszamolja az uj erteket

	MOV     AH,2CH          ;ha ez az elso meghivas, az eljaras
	INT     21H             ;a CMOS memoriabol veszi az aktualis idot veletlenszam alapnak
	MOV     DS:[Rnd_Lo],CX  ;a DOS 2CH funkcio eredmenye:
	MOV     DS:[Rnd_Hi],DX  ;   CH = ora      (0-23)
							;   CL = perc     (0-59)
							;   DH = masodperc (0-59)
							;   DL = szazadmasodperc (0-99)
	MOV Byte Ptr DS:[DI],01H ;modositja az elso bemenet byte-ot, hogy
							;ne toltse ujra az inicialis veletlen valtozokat

							;elso futas utasitasi blokkja
Rand_2: MOV     AX,DS:[Rnd_Lo]  ;AH = ora      (0-23), AL = perc    (0-59)
	MOV     BX,DS:[Rnd_Hi]  ;BH = masodperc (0-59), BL = szazadmasodperc (0-99)
	MOV     CX,AX           ;CH = ora      (0-23), CL = perc    (0-59)

	MUL     DS:[Costante]   ;AX*Costante=AX*8405H=DX,AX (32 bites szam)

	SHL     CX,1            ;algoritmus a veletlenszam szamitashoz
	SHL     CX,1
	SHL     CX,1
	ADD     CH,CL
	ADD     DX,CX
	ADD     DX,BX
	SHL     BX,1
	SHL     BX,1
	ADD     DX,BX
	ADD     DH,BL
	MOV     CL,5
	SHL     BX,CL
	ADD     AX,1
	ADC     DX,0

		MOV     DS:[Rnd_Lo],AX  ;elmenti a manipulacio eredmenyet (32 bites) 
	MOV     DS:[Rnd_Hi],DX  ;a dedikalt valtozokba

	POP     BX              ;visszatolti BX-be a tartomany erteket, amelyet 
							;AX-ben adott at bemenetkent
	XOR     AX,AX           ;elokesziti a 32 bites osztot, a 16 felso bitet
							;lenullazva
	XCHG    AX,DX           ;a felso 16 bitbe (DX) masolja a jelenlegi DX erteket,
							;mig az also 16 bit (AX) marad ures
	DIV     BX              ;AX = hanyados (DX,AX / BX)
							;DX = maradek
	XCHG    AX,DX           ;a jelenlegi veletlenszam a maradek erteke,
							;amely AX-ben marad kimenetkent
	POP     DS
	POP     DI              ;visszatolti az eljaras altal hasznalt regisztereket
	POP     DX
	POP     CX
	POP     BX
	RET
rand  ENDP
;============================================================================
delay PROC NEAR         ;CX=18, hogy 0,55ms*18 = 1 masodperc legyen a kesleltetes
	PUSH AX         ;elmentem a regisztereket
	PUSH BX
	PUSH DX

	PUSH CX         ;CX erteket atmasolom BX-be
	POP BX          ;BX-ben van a valasztott kesleltetesi ertek
	CALL clock      ;visszaadja CX,DX-ben a rendszerido-t (32 bites)
	ADD DX,BX       ;hozzaadok egy adott szamu TICK-et (CX) DX-hez (ido also resze)
	JNC Delay_0     ;ha nincs carry, ugrik Delay_0-ra
	INC CX          ;kulonben carry-t hozzaadom CX-hez
Delay_0: PUSH CX        ;AX,BX-be masolom a kezdokor idoerteket
	PUSH DX         ;FRISSITVE a kivant kesleltetes szerinti ertekkel
	POP BX          ;gyakorlatilag AX,BX-ben van a jovobeli ido, amit el kell erni
	POP AX
Delay_1: PUSH AX        ;elmentem AX,BX adatait (a celidot)
	PUSH BX
	CALL clock      ;elmentem az UJ olvasas eredmenyet CX,DX-be
	POP BX          ;es AX,BX-ben mindig a celido adatai maradnak
	POP AX

	CMP AX,CX       ;osszehasonlitom a ket ido felso reszet
	JZ Delay_2      ;ha azonosak, ellenorizem az also reszt (Delay_2)
			;kulonben altalaban carry miatt elternek
	PUSH AX         ;elmentem a felso reszt
	SUB AX,CX       ;ellenorzom, hogy elteres van-e, esetleg nem csak 1 a carry
	CMP AX,18H      ;ha az elteres 18H, akkor ejfel elmult
	POP AX
	JNZ Delay_1     ;ha nem mult ejfel, akkor visszater Delay_1-re folytatni az varakozast

	PUSH BX         ;ha ejfel elmult (az elteres 18H)
	SUB BX,00B0H    ;CX,DX attert 0018-00AFH-rol 0000-0000H-ra
	CMP BX,DX       ;az also reszt is igazitanom kell az uj helyzethez
	POP BX
	JG Delay_1      ;ha BX meg mindig nagyobb DX-nel, folytatom a varakozast
	JMP Delay_3     ;kulonben nincs tobb varakozas - kesleltetes vege!

Delay_2: CMP BX,DX      ;ha a felso resz azonos, es az also resz (BX>DX)
	JG Delay_1      ;folytatom az varakozast

Delay_3: POP DX         ;kesleltetes befejezve!
	POP BX
	POP AX

	RET             ;visszater

delay ENDP
;=========================================================================================================
wLife PROC NEAR         ;random szivecske kirajzolasa
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	Random 27       ;random oszlop kivalasztasa 0 es 27 kozott (AX-be menti az erteket)
	INC AX          ;random oszlop 1 es 28 kozott (kereten belul)
	setCur 1,AL     ;a random szam also reszet hasznalom (felso resz nulla)
	MOV BH,0        ;video oldal 0
	MOV CX,1        ;egy karakter kivalasztasa
	MOV AL,03H      ;karakter kivalasztasa (Szivecske)
	MOV BL,04H      ;piros szin fekete hatteren
	CALL scrivi     ;karakter kirajzolasa
	POP AX
	POP BX
	POP CX
	POP DX
	RET
wLife ENDP
;=========================================================================================================
wMon PROC NEAR       ;random erme kirajzolasa
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	Random 27       ;random oszlop kivalasztasa 0 es 27 kozott (AX-be menti az erteket)
	INC AX          ;random oszlop 1 es 28 kozott (kereten belul)
	setCur 1,AL     ;a random szam also reszet hasznalom (felso resz nulla)
	MOV BH,0        ;video oldal 0
	MOV CX,1        ;egy karakter kivalasztasa
	MOV AL,0FH      ;karakter kivalasztasa (Erme - Nap)
	MOV BL,0EH      ;sarga szin fekete hatteren
	CALL scrivi     ;karakter kirajzolasa
	POP AX
	POP BX
	POP CX
	POP DX
	RET
wMon ENDP
;=========================================================================================================
wOst PROC NEAR       ;random akadaly kirajzolasa
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	Random 27       ;random oszlop kivalasztasa 0 es 27 kozott (AX-be menti az erteket)
	INC AX          ;random oszlop 1 es 28 kozott (kereten belul)
	setCur 1,AL     ;a random szam also reszet hasznalom (felso resz nulla)
	MOV BH,0        ;video oldal 0
	MOV CX,1        ;egy karakter kivalasztasa
	MOV AL,0B1H     ;karakter kivalasztasa (egy "szikla")
	MOV BL,08H      ;szurke szin fekete hatteren
	CALL scrivi     ;karakter kirajzolasa
	POP AX
	POP BX
	POP CX
	POP DX
	RET             ;visszater
wOst ENDP
;============================================================================
goGIU PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	MOV AH,07H      ;a kepernyo egy reszenek lefele mozgatasa funkcio
MOV AL,01H      ;sorok szama
MOV CH,1        ;bal felso sarok sora
MOV CL,1        ;bal felso sarok oszlopa
MOV DH,20       ;jobb also sarok sora
MOV DL,28       ;jobb also sarok oszlopa
                ;1,1-tol 28,20-ig (0. es 22. sorban keret van)
MOV BH,07H      ;ures sorok szine fekete (DEFAULT 07H)
INT 10H
POP DX
POP CX
POP BX
POP AX
RET             ;visszater
goGIU ENDP
;=========================================================================================================
writeTTY PROC Near      ;AL=karakter, CX=ismetles szama
PUSH BX
MOV BH,00H      ;0. oldal
MOV BL,70H      ;Feher feketen
MOV AH,0EH      ;INT 10H 0EH funkcioja (szines karakter(ek) megjelenitese a kepernyon)
INT 10H
POP BX
RET             ;visszater
writeTTY ENDP
;=========================================================================================================
writeCOL PROC Near      ;AL=karakter, CX=ismetles szama, BL=szin
MOV BH,00H      ;0. oldal
MOV AH,09H      ;INT 10H 09H funkcioja (szines karakter(ek) megjelenitese a kepernyon)
INT 10H
RET             ;visszater
writeCOL ENDP
;=========================================================================================================
writeBN PROC Near      ;AL=karakter, CX=ismetles szama
PUSH BX
PUSH CX
MOV BH,00H      ;0. oldal
MOV BL,70H      ;Feher feketen
MOV CX,1        ;EGY karaktert jelenit meg
MOV AH,0AH      ;INT 10H 0AH funkcioja (karakterek megjelenitese a kepernyon)
INT 10H
POP CX
POP BX
RET             ;visszater
writeBN ENDP
;=========================================================================================================
scrivi PROC Near      ;AL=karakter, CX=ismetles szama, BL=szin
MOV AH,09H      ;INT 10H 09H funkcioja (CX darab szines karakter megjelenitese a kepernyon)
INT 10H
RET             ;visszater
scrivi ENDP
;=========================================================================================================
clock PROC Near         ;beteszi a regiszterekbe az aktualis idot:
MOV AH,00H      ;CX=ora magas resze
INT 1AH         ;DX=ora alacsony resze
RET
clock ENDP
;=========================================================================================================
waitKey PROC Near       ;var egy billentyut
MOV AH,00H      ;INT 16H 00H funkcioja, amely var egy billentyure
INT 16H
                ;AL=ASCII kod, AH=scan kod
RET             ;visszater
waitKey ENDP
;============================================================================
pressKey PROC Near
MOV AH,01H      ;ha egy billentyut lenyomtak, a ZERO FLAG-et modositja
INT 16H
RET
pressKey ENDP
;============================================================================
posCur PROC Near       ;Procedura a kurzor pozicionalasara
PUSH AX
PUSH BX
PUSH DX
MOV BH,00H      ;0. video oldal (ami lathato)
MOV AH,02H      ;INT 10H 02H funkcioja, amely a kurzort a DH,DL (sor,oszlop) pozicioba helyezi
INT 10H
POP DX
POP BX
POP AX
RET             ;visszater
posCur ENDP
;============================================================================
setCar PROC NEAR        ;DH=sor, DL=oszlop
PUSH AX
PUSH CX
PUSH DX
MOV CX,0000H

CALL posCur     ;kurzor pozicionalasa
CMP BX,0000H    ;ha BX nulla, akkor meg nem erintett semmit
JNE asd1        ;ugrok a kovetkezo ellenorzesre
CALL checkCar   ;ellenorzes, hogy erintett-e valamit
asd1: CALL posCur
stpChrBN 1EH    ;megjelenitem a kozepso karaktert

INC DX          ;jobbra lepek
CALL posCur
CMP BX,0000H    ;ha BX nulla, akkor meg nem erintett semmit
JNE asd2        ;ugrok a kovetkezo ellenorzesre
CALL checkCar
asd2: CALL posCur
stpChrBN '>'    ;megjelenitem a jobb oldali karaktert

SUB DX,2        ;balra lepek 2-t
CALL posCur
CMP BX,0000H    ;ha BX nulla, akkor meg nem erintett semmit
JNE asd3        ;ugrok a kovetkezo ellenorzesre
CALL checkCar
asd3: CALL posCur
stpChrBN '<'    ;megjelenitem a bal oldali karaktert

;KARAKTER MEGJELENITETESE ELLENORZESRE
;PUSH DX
;setCur 18,60    ;megjelenitem az akadaly karakteret, amit erintettem
;stpChrBN CH
;POP DX

CMP CH,'M'      ;egy ermet talaltam
JE Moneta_2
CMP CH,'X'      ;egy kovet talaltam
JE Masso_2
CMP CH,'V'      ;egy eletet talaltam
JE Vita_2
JMP CONT_2

Moneta_2: JMP CONT_2    ;itt hagyom a kodot, ha kesobb modositasokat kene eszkozolnom

Masso_2:  JMP CONT_2

Vita_2:   JMP CONT_2


CONT_2: INC DX
	CALL posCur

	POP DX
	POP CX
	POP AX
	RET                     ;visszateres
setCar ENDP
;============================================================================
checkCar PROC NEAR ;DH=sor,DL=oszlop
    CMP CL,01H      ;CL ellenorzi, hogy mar felvettunk-e valamit
    JE CONT_1       ;ha CL=1, kihagyja az ellenorzest, es a vegehez ugrik

    CALL readCur    ;ellenorzi az ASCII karaktert, amit a kurzor mutat AL=karakter, AH=szin
    CMP AH,08H      ;ha szurke -> ko
     JE Masso_1
    CMP AH,0EH      ;ha sarga -> penz
     JE Moneta_1
    CMP AH,04H
     JE Vita_1      ;ha piros -> elet
    CMP AH,07H
     JE Niente_1    ;nem vesz fel semmit
    JMP CONT_1

Masso_1: MOV CL,01H     ;CL erteke 1, jelezve, hogy valamit felvettunk
         MOV CH,'X'     ;CH-ben eltarolja az akadaly tipusat (CH egy tickig tart)
         MOV BL,'x'     ;BL-ben eltarolja az akadaly tipusat (BL egy ciklusig tart)
         JMP CONT_1

Moneta_1: MOV CL,01H    ;CL erteke 1, jelezve, hogy valamit felvettunk
          MOV CH,'M'    ;CH-ben eltarolja az akadaly tipusat (CH egy tickig tart)
          MOV BL,'m'    ;BL-ben eltarolja az akadaly tipusat (BL egy ciklusig tart)
          JMP CONT_1

Vita_1:   MOV CL,01H    ;CL erteke 1, jelezve, hogy valamit felvettunk
          MOV CH,'V'    ;CH-ben eltarolja az akadaly tipusat (CH egy tickig tart)
          MOV BL,'v'    ;BL-ben eltarolja az akadaly tipusat (BL egy ciklusig tart)
          JMP CONT_1

Niente_1: MOV CH,'_'    ;ellenorzo karakter
          JMP CONT_1

CONT_1:   RET

checkCar ENDP

Word2Dec PROC NEAR      ;atalakitja az AX-ben kapott hexadecimális szot a megfelelo ASCII karakterekre
    PUSH    AX
    PUSH    BX
    PUSH    DX
    CMP     AX,10000        ;ha a hexadecimális szam kisebb
    JC      Wor2_0          ;mint 10000, a kovetkezo osztas elmarad
    MOV     DX,0000H        ;(DX,AX=0000XXXX):(BX=10000)=AX, maradek DX
    MOV     BX,10000        ;10000-re allitja az osztot
    DIV     BX              ;osztas vegrehajtasa
    CALL    STAasci         ;kivalasztja a Tizezresek erteket
    MOV     AX,DX           ;AX-be helyezi a maradekot
    JMP     SHORT Wor2_1    ;a kovetkezo lepesben folytatva az osztast
Wor2_0: CMP     AX,1000     ;ha a hexadecimális szam kisebb
    JC      Byt2_0          ;mint 1000, a kovetkezo osztas elmarad
Wor2_1: MOV     DX,0000H    ;(DX,AX=0000XXXX):(BX=1000)=AX, maradek DX
    MOV     BX,1000         ;1000-re allitja az osztot
    DIV     BX              ;osztas vegrehajtasa
    CALL    STAasci         ;kivalasztja az Ezresek erteket
    MOV     AX,DX           ;AX-be helyezi a maradekot
    JMP     SHORT Byt2_1    ;a kovetkezo lepesben folytatva az osztast

;Byte2Dec
    PUSH    AX              ;menti a hasznalt regisztereket, valamint
    PUSH    BX              ;az atadott erteket, ami AL-ben erkezett
    PUSH    DX
    MOV     AH,00H          ;formatalja a szamitasi eredmenyt AX=00XX
Byt2_0: CMP     AX,100      ;ha a hexadecimális szam kisebb
    JC      Byt2_2          ;mint 100, a kovetkezo osztas elmarad
Byt2_1: MOV     BL,100      ;100-ra allitja az osztot
    DIV     BL              ;AX=00XX osztva BL=100 (AX:BL=AL, maradek AH)
    CALL    STAasci         ;kivalasztja a Szazak erteket
    MOV     AL,AH           ;AL-be helyezi a maradekot
    MOV     AH,00H          ;elokesziti a kovetkezo osztashoz
    JMP     SHORT Byt2_3    ;formatalja az eredmenyt AX=00RR
Byt2_2: CMP     AX,10       ;ha a hexadecimális szam kisebb
    JC      Byt2_4          ;mint 10, a kovetkezo osztas elmarad
Byt2_3: MOV     BL,10       ;10-re allitja az osztot
    DIV     BL              ;AX=00XX osztva BL=10 (AX:BL=AL, maradek AH)
    CALL    STAasci         ;kivalasztja a Tizek erteket
    MOV     AL,AH           ;elokesziti AL-ben az Egysegeket
Byt2_4: CALL    STAasci     ;kivalasztja az Egysegek erteket
    POP     DX
    POP     BX
    POP     AX
    RET
Word2Dec ENDP
;========================================================================================================
STAasci PROC NEAR             ;kiirja az AL-ben levo szam ASCII erteket
    PUSH    AX
    ADD     AL,30H        ;hozzaad 30-at, hogy megkapja a szam ASCII karakteret
    stpChrT AL
    POP     AX
    RET
STAasci ENDP
;=========================================================================================================
readCur PROC NEAR             ;olvassa az ASCII karaktert, amire a kurzor mutat
    MOV AH,08H
    MOV BH,00H
    INT 10H               ;visszaadja AH=szin, AL=karakter
    RET
readCur ENDP
;=========================================================================================================
outCur PROC    Near             ;eljaras, amely eltunteti a kurzort a kepernyorol
    PUSH CX                 ;a kurzormagassag allitasara alapozva
    PUSH AX                 ;(ha CH 5. bitje 1, akkor a kurzor eltunik)
    MOV CH,20H              ;kezdosor a keppontok kozott
    MOV CL,00H              ;vegsor a keppontok kozott
    MOV AH,01H
    INT 10H
    POP AX
    POP CX
    RET                     ;visszateres
outCur ENDP
;============================================================================
cls PROC Near
    MOV AL,03H              ;80 oszlop x 24 sor mod
    MOV AH,00H              ;ezzel letrehoz egy kepernyotisztiatast is
    INT 10H
    RET
cls ENDP
;============================================================================
tornaDOS PROC NEAR
    MOV AH,4CH
    INT 21H
tornaDOS ENDP
;============================================================================

_prog    ENDS                   ;SZEGMENS PROGRAM VEGE
    END     INIZIO          ;Program vege, minden utana levo resz ignoralt!
