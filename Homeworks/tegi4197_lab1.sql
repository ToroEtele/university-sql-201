--Adjuk meg azokat az autó márkákat melyeket legalább kétszer béreltek MárkaNév,BérlésSzám formában!
--(Megj. legalább 2, nem több mint 2-re lesz csak eredmény)

SELECT Markak.MarkaNev, COUNT(Berel.BerlesID) AS BerlesSzam FROM Markak
INNER JOIN Tipusok ON Tipusok.MarkaID = Markak.MarkaID
INNER JOIN Autok ON Autok.TipusID = Tipusok.TipusID
INNER JOIN Berel ON Berel.AutoKod = Autok.AutoKod
GROUP BY Markak.MarkaNev
HAVING COUNT(Berel.BerlesID) > 1

--Keressük meg azokat az auto tipusokat, melyek kevesebb mint 500 lej bevételt hoztak(Figyeljetek arra hogy esetlegesen lehet olyan auto is melynek nincs bevétele).
SELECT t.TipusNev, SUM(b.Ar) s FROM Tipusok t
LEFT JOIN Autok a ON a.TipusID = t.TipusID
LEFT JOIN Berel b ON b.AutoKod = a.AutoKod
GROUP BY t.TipusNev
HAVING SUM(b.Ar) < 500 OR SUM(b.Ar) IS NULL

--Adjuk meg azokat a bérlőket akik csak Volkswagen Polo-t béreltek.

SELECT b.Nev FROM Berlok b
INNER JOIN Berel ON Berel.BerloID = b.BerloID
INNER JOIN Autok a ON a.AutoKod = Berel.AutoKod
INNER JOIN Tipusok t ON t.TipusID = a.TipusID
INNER JOIN Markak m ON m.MarkaID = t.MarkaID
WHERE MarkaNev = 'Volkswagen' AND TipusNev = 'Polo'

--Adjuk meg azokat a bérlőket akik extra nélküli autót béreltek.

SELECT b.Nev, a.AutoKod FROM Berlok b
INNER JOIN Berel ON Berel.BerloID = b.BerloID
INNER JOIN Autok a ON a.AutoKod = Berel.AutoKod
INNER JOIN AutoExtraja ae ON ae.AutoKod = a.AutoKod
WHERE a.AutoKod NOT IN (SELECT AutoKod FROM AutoExtraja)
GROUP BY b.Nev

--Adjuk meg a bérlők esetén hogy melyik tipusu autót átlagban hány napra béreltek.

SELECT b.Nev, t.TipusNev, AVG(DATEDIFF(day, Berel.Mikortol, Berel.Meddig)) AS NapokSzama FROM Berlok b
INNER JOIN Berel ON Berel.BerloID = b.BerloID
INNER JOIN Autok a ON a.AutoKod = Berel.AutoKod
INNER JOIN Tipusok t ON t.TipusID = a.TipusID
GROUP BY 
	b.Nev, 
	t.TipusNev


--Adjuk meg csokkenő sorrendben minden autó tipus esetén hány kulőnböző extrával van felszerelve (MárkaNév, TipusNév, ExtrákSzáma). 
--Figyeljetek arra, hogy azok az autók is megjelenjenek melyeknek nincs egyáltalán extra felszereltsége

SELECT m.MarkaNev, t.TipusNev, COUNT(ae.ExtraID) AS ExtrakSzama FROM Markak m
INNER JOIN Tipusok t ON t.MarkaID = m.MarkaID
INNER JOIN Autok a ON a.TipusID = t.TipusID
LEFT JOIN AutoExtraja ae ON ae.AutoKod = a.AutoKod
GROUP BY 
	m.MarkaNev, 
	t.TipusNev
ORDER BY
	ExtrakSzama DESC

--Halmazmúveletekkel adjuk meg azokat az autokat (MárkaNév, TipusNev, Szin, GyártásiEv) formában 
-- Melyeket 2010 után gyártottak de nem piros szinuek .

SELECT m.MarkaNev, t.TipusNev, sz.SzinNev, a.GyartasiEv FROM MARKAK m
INNER JOIN Tipusok t ON t.MarkaID = m.MarkaID
INNER JOIN Autok a ON a.TipusID = t.TipusID
INNER JOIN Szinek sz on sz.SzinKod = a.SzinKod
WHERE sz.SzinNev = 'Piros'

EXCEPT

SELECT m.MarkaNev, t.TipusNev, sz.SzinNev, a.GyartasiEv  FROM MARKAK m
INNER JOIN Tipusok t ON t.MarkaID = m.MarkaID
INNER JOIN Autok a ON a.TipusID = t.TipusID
INNER JOIN Szinek sz on sz.SzinKod = a.SzinKod
WHERE a.GyartasiEv = '2010'

-- Melyekben van Klima és van GPS is

SELECT m.MarkaNev, t.TipusNev FROM MARKAK m
INNER JOIN Tipusok t ON t.MarkaID = m.MarkaID
INNER JOIN Autok a ON a.TipusID = t.TipusID
INNER JOIN AutoExtraja ae ON ae.AutoKod = a.AutoKod
INNER JOIN Extrak e ON e.ExtraID = ae.ExtraID
WHERE e.ExtraNev = 'Klima'

INTERSECT

SELECT m.MarkaNev, t.TipusNev FROM MARKAK m
INNER JOIN Tipusok t ON t.MarkaID = m.MarkaID
INNER JOIN Autok a ON a.TipusID = t.TipusID
INNER JOIN AutoExtraja ae ON ae.AutoKod = a.AutoKod
INNER JOIN Extrak e ON e.ExtraID = ae.ExtraID
WHERE e.ExtraNev = 'GPS'

--Növeljük a napi diját az összes Volkswagen márkájú autónak 10%-al.

UPDATE Autok
SET NapiDij = NapiDij*1.1
FROM Autok
INNER JOIN Tipusok ON Tipusok.TipusID = Autok.TipusID
INNER JOIN Markak ON Markak.MarkaID = Tipusok.MarkaID
WHERE Markak.MarkaNev = 'Volkswagen'
--ellenorzes
SELECT Autok.NapiDij
FROM Autok
INNER JOIN Tipusok ON Tipusok.TipusID = Autok.TipusID
INNER JOIN Markak ON Markak.MarkaID = Tipusok.MarkaID
WHERE Markak.MarkaNev = 'Volkswagen'

--Töröljuk az összes 2000 ás 1990 között gyártott autót!

DELETE b FROM Berel b
INNER JOIN Autok a ON b.AutoKOD = a.AutoKOD
WHERE a.GyartasiEv BETWEEN 1990 AND 2000
DELETE ae FROM AutoExtraja ae
INNER JOIN Autok a ON ae.AutoKod = a.AutoKOD
WHERE a.GyartasiEv BETWEEN 1990 AND 2000
DELETE a FROM Autok a
WHERE a.GyartasiEv BETWEEN 1990 AND 2000

--Szúrd be a kedvenc autód az adatbázisba (legalább 2 extrával)

INSERT INTO Tipusok 
VALUES ('Velociraptor', '4')
INSERT INTO Autok
VALUES('CV03XOS', '9', '4', '2020', '100', '5')
INSERT INTO AutoExtraja
VALUES('16','1'),('16','2')
