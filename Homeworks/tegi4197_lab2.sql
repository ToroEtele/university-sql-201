-- Toró Etele Lab2

/*
1. Feladat: 
SELECT utasítás segítségével adjuk meg minden kocsma esetén, hogy mennyire “népszerű” (KocsmaNev, Népszerűség) formában, ahol:
ha több, mint 4 barát kedveli, akkor: Népszerűség értéke: ‘Magas’
ha 2-3 barát kedveli, akkor: Népszerűség értéke: ‘Elfogadhato’
ha kevesebb, mint 2 barát kedveli, akkor: Népszerűség értéke: ‘Alacsony’*/

SELECT Kocsmak.Nev, Nepszeruseg = 
	CASE
		WHEN COUNT(BaratID) >= 4 THEN 'Magas'
		WHEN COUNT(BaratID) < 4 and COUNT(BaratID) > 1 THEN 'Elfogadhato'
		WHEN COUNT(BaratID) < 2 THEN 'Alacsony'
	END
FROM Kocsmak
LEFT JOIN Kedvencek ON Kocsmak.KocsmaID = Kedvencek.KocsmaID
GROUP BY Kocsmak.Nev

GO

/*
2. Feladat
Írjunk tárolt eljárást, melynek bemenő paramétere egy természetes szám (@pSzam), kimeneti paramétere: @pOut-int típusú! 
Ha @pSzam<0, írjunk ki megfelelő hibaüzenetet, valamint @pOut = -1! 
Ellenkező esetben, írassuk ki azon kocsmá(ka)t (KocsmaNev), mely(ek)ben kevesebb italtípusból válogathatunk, mint a paraméterként megadott szám (0 is lehet a szám)! 
Ekkor @pOut=a feltételnek eleget tevő kocsmák száma! Ha nincs egyetlen ilyen kocsma sem, írassunk ki megfelelő figyelmeztető üzenetet is!
*/

CREATE or ALTER PROCEDURE KevesebbKinalat (@pSzam INT, @pOut INT OUTPUT)
AS
BEGIN
	IF @pSzam<0
		BEGIN
			PRINT 'Helytelen ertek a pSzam!'
			SET @pOut = -1
		END
	ELSE
		BEGIN
			SELECT @pOut = COUNT(*) FROM (
			SELECT Nev FROM Kocsmak
			LEFT JOIN Arak ON Arak.KocsmaID = Kocsmak.KocsmaID
			GROUP BY Nev
			HAVING COUNT(ItalID) < @pSzam) AS List

			IF @pOut = 0
				BEGIN
					PRINT 'Nem letezik ilyen kocsma'
				END
			ELSE
				BEGIN
					SELECT Nev FROM Kocsmak
					LEFT JOIN Arak ON Arak.KocsmaID = Kocsmak.KocsmaID
					GROUP BY Nev
					HAVING COUNT(ItalID) < @pSzam
				END
		END
END
GO

DECLARE @kocsmakSzama INT

EXEC KevesebbKinalat
	@pSzam = 0,
	@pOut = @kocsmakSzama OUTPUT

SELECT @kocsmakSzama AS KevesebbItal

GO

/*
3. Feladat
Írjunk tárolt eljárást, mely a paraméterként megadott kocsma(Kocsma.Nev) címéből és italaibol eltűnteti a szóközöket és visszatériti az eltüntetett szóközök számát!
*/

CREATE OR ALTER PROCEDURE SzokozEltunteto (@nev VARCHAR(20), @szokoz INT OUTPUT)
AS
BEGIN

	SET @szokoz = 0
	SELECT @szokoz=(LEN(Cim) - LEN(REPLACE(Cim, ' ', ''))) FROM Kocsmak WHERE Nev = @nev
	
	SELECT @szokoz+=(LEN(ItalNev) - LEN(REPLACE(ItalNev, ' ', ''))) 
	FROM Italok 
	INNER JOIN Arak ON Arak.ItalID = Italok.ItalID
	INNER JOIN Kocsmak ON Kocsmak.KocsmaID = Arak.KocsmaID
	WHERE Kocsmak.Nev = @nev

	UPDATE Kocsmak
	SET	Cim=REPLACE(Cim, ' ', '')
	WHERE Nev = @nev
	
	UPDATE Italok
	SET ItalNev = REPLACE(ItalNev, ' ', '')
	FROM Italok
	INNER JOIN Arak ON Arak.ItalID = Italok.ItalID
	INNER JOIN Kocsmak ON Kocsmak.KocsmaID = Arak.KocsmaID
	WHERE Nev = @nev
END

DECLARE @szokozokSzama INT;

EXEC SzokozEltunteto
	@nev = 'Insomnia',
	@szokoz = @szokozokSzama OUTPUT;

SELECT @szokozokSzama AS EltuntetettSzokozokSzama;

GO

/*
	4. Feladat
	Írjunk tárolt eljárást, melynek bemenő paramétere @pAtlagAr - int típusú. 
	A tárolt eljárás azon kocsmák bevételét (Kocsmak.Bevetel) megnöveli (UPDATE) 10%-kal, ahol az italok átlagára <=@pAtlagAr! 
	Kimeneti paraméter: @pmodkt (int) - módosított kocsmák száma.
	Megj. Ha van olyan kocsma, melynek bevétele eleve 49999 EURO feletti, ezek esetén ne végezze el a módosítást!
*/

CREATE OR ALTER PROCEDURE BevetelNoveles (@pAtlagAr INT, @pmodkt INT OUTPUT)
AS
BEGIN
	SELECT @pmodkt=COUNT(*) FROM (
	SELECT * FROM Arak
	WHERE AVG(Arak.Ar) <= @pAtlagAr
	GROUP BY KocsmaID ) AS List

	UPDATE Kocsmak
	SET Bevetel = Bevetel * 1.1
	FROM Kocsmak
	WHERE KocsmaID IN (
		SELECT KocsmaID
		FROM Arak
		GROUP BY KocsmaID
		HAVING AVG(Arak.Ar) <= @pAtlagAr 
	) and Bevetel < 49999
END

DECLARE @modositott INT

EXEC BevetelNoveles
	@pAtlagAr = 4.25,
	@pmodkt = @modositott OUTPUT

SELECT @modositott as ModositottKocsmakSzama


GO

/*
 5. Feladat
 Írj tárolt eljárást amely frissiti egy kocsma(Parameter: @pKocsmaNev) árait egy bizonyos ital tipusban(@pItalTipus), 
 a piacon legalacsonyabb értékekkel vagyis minden ital ára a legkisebb legyen az illető kategóriából. 
*/

/*!! Én úgy értelmeztem a feladatot, hogy a pKocsmaNev kocsmaban frissitjuk a pItalTipus típusú italok árát, a piacon található legalacsonyabb 
pItalTipus típusú árral, tehát nem márka szerit. Remelem jól, értelmeztem, nem egyértelmű.*/

CREATE OR ALTER PROCEDURE ItallapFrissitese( @pKocsmaNev VARCHAR(20), @pItalTipus VARCHAR(20))
AS
BEGIN
	UPDATE Arak
	SET Arak.Ar = (
		SELECT TOP 1 Arak.Ar FROM ARAK
		INNER JOIN Italok ON Italok.ItalID = Arak.ItalID
		INNER JOIN ItalTipusok ON ItalTipusok.TipusID = Italok.TipusID
		WHERE TipusNev = @pItalTipus
		ORDER BY Arak.Ar ASC
		)
	FROM Arak
	INNER JOIN Kocsmak ON Kocsmak.KocsmaID = Arak.KocsmaID
	INNER JOIN Italok ON Italok.ItalID = Arak.ItalID
	INNER JOIN ItalTipusok ON ItalTipusok.TipusID = Italok.TipusID
	WHERE Kocsmak.Nev = @pKocsmaNev and ItalTipusok.TipusNev = @pItalTipus
END

EXEC ItallapFrissitese
	@pKocsmaNev = 'Bleriot',
	@pItalTipus = 'sor'
	
GO

/*
	6. Feladat
	Írjunk függvényt, mely visszatéríti, hogy a paraméterként megadott nevű barát (@pBaratNev,@pTel) hány koncsmát kedvel azok közül,
	amelyekben árulnak @pItalNev nevű italt (@pItalNev-bemeneti paraméter)! 
	Megj. Ellenőrizzük le, hogy az adott barát, ital létezik-e az adatbázisban (ha nem, térítsünk vissza -3-t).
*/

CREATE OR ALTER PROCEDURE KedveltKocsmakSzama (@BaratNev VARCHAR(30), @pTel VARCHAR(10), @pItalNev VARCHAR(20), @db INT OUTPUT)
AS
BEGIN
	IF EXISTS (SELECT * FROM Baratok WHERE Nev=@BaratNev and Tel=@pTel)
	BEGIN
		IF EXISTS (SELECT * FROM Italok WHERE ItalNev=@pItalNev)
		BEGIN
			SELECT	@db = COUNT(*) FROM Kocsmak
			INNER JOIN Kedvencek on Kedvencek.KocsmaID = Kocsmak.KocsmaID
			INNER JOIN Baratok on Baratok.BaratID = Kedvencek.BaratID
			INNER JOIN Arak on Arak.KocsmaID = Kocsmak.KocsmaID
			INNER JOIN Italok on Italok.ItalID = Arak.ItalID
			WHERE Baratok.Nev = @BaratNev and Baratok.Tel = @pTel and Italok.ItalNev = @pItalNev
		END
		ELSE
		BEGIN
			PRINT 'Ez az ital kategoria nem letezik!'
			SET @db=-3
		END
	END
	ELSE
	BEGIN
		PRINT 'Ez a barat nem letezik!'
		SET @db=-3
	END
	RETURN
END

GO

DECLARE @kedveltKocsmak INT

EXEC KedveltKocsmakSzama
	@BaratNev = 'David',
	@pTel = '0743565678',
	@pItalNev = 'Hargita',
	@db = @kedveltKocsmak OUTPUT

SELECT @kedveltKocsmak AS KedveltKocsmakSzama