USE master;
GO

DROP DATABASE IF EXISTS ScherpInZicht;
GO

CREATE DATABASE ScherpInZicht;
GO

USE ScherpInZicht;
GO

-- Veelgebruikte aggregaties zijn COUNT, SUM, AVG, MIN en MAX.
CREATE ROLE db_opticien;
CREATE ROLE db_leverancier;
CREATE ROLE db_verkoper;
CREATE ROLE db_oogmeter;
GO

CREATE FUNCTION dbo.checkBsn (@bsn CHAR(9))
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    IF @bsn IS NULL OR LEN(@bsn) <> 9 OR @bsn LIKE '%[^0-9]%'
        RETURN 0;

    DECLARE @controlegetal INT =
        9 * CONVERT(INT, SUBSTRING(@bsn, 1, 1)) +
        8 * CONVERT(INT, SUBSTRING(@bsn, 2, 1)) +
        7 * CONVERT(INT, SUBSTRING(@bsn, 3, 1)) +
        6 * CONVERT(INT, SUBSTRING(@bsn, 4, 1)) +
        5 * CONVERT(INT, SUBSTRING(@bsn, 5, 1)) +
        4 * CONVERT(INT, SUBSTRING(@bsn, 6, 1)) +
        3 * CONVERT(INT, SUBSTRING(@bsn, 7, 1)) +
        2 * CONVERT(INT, SUBSTRING(@bsn, 8, 1)) -
        CONVERT(INT, SUBSTRING(@bsn, 9, 1));

    RETURN CASE WHEN @controlegetal <> 0 AND @controlegetal % 11 = 0 THEN 1 ELSE 0 END;
END;
GO

CREATE SCHEMA Security;
GO

CREATE TABLE Adressen (
    AdresID INT IDENTITY(1,1) PRIMARY KEY,
    Straatnaam NVARCHAR(100) NOT NULL,
    Huisnummer NVARCHAR(10) NOT NULL,
    Postcode NVARCHAR(10) NOT NULL
);

CREATE TABLE Klanten (
    KlantID INT IDENTITY(1,1) PRIMARY KEY,
    Voornaam NVARCHAR(50) NOT NULL,
    Tussenvoegsel NVARCHAR(20) NULL,
    Achternaam NVARCHAR(80) NOT NULL,
    Geboortedatum DATE NULL,
    AdresID INT NULL,
    Telefoonnummer NVARCHAR(20) NULL,
    Email NVARCHAR(150) NULL,
    BSN CHAR(9) NOT NULL,
    MedischeGeschiedenis NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Klanten_Adressen FOREIGN KEY (AdresID) REFERENCES Adressen(AdresID),
    CONSTRAINT UQ_Klanten_BSN UNIQUE (BSN),
    CONSTRAINT CK_Klanten_BSN CHECK (dbo.checkBsn(BSN) = 1),
    CONSTRAINT CK_Klanten_Contact CHECK (Email IS NOT NULL OR Telefoonnummer IS NOT NULL),
    CONSTRAINT CK_Klanten_Geboortedatum CHECK (Geboortedatum IS NULL OR Geboortedatum <= CAST(GETDATE() AS DATE))
);

CREATE TABLE Gebruikers (
    Gebruikersnaam SYSNAME PRIMARY KEY,
    Rol NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_Gebruikers_Rol CHECK (Rol IN (N'Opticien', N'Leverancier', N'Verkoper', N'Oogmeter'))
);

INSERT INTO Gebruikers (Gebruikersnaam, Rol)
VALUES
    (N'opticien', N'Opticien'),
    (N'leverancier01', N'Leverancier'),
    (N'leverancier02', N'Leverancier'),
    (N'verkoper01', N'Verkoper'),
    (N'verkoper02', N'Verkoper'),
    (N'verkoper03', N'Verkoper'),
    (N'oogmeter01', N'Oogmeter'),
    (N'oogmeter02', N'Oogmeter'),
    (N'verkoper04', N'Verkoper'),
    (N'oogmeter03', N'Oogmeter');

CREATE TABLE Medewerkers (
    MedewerkerID INT IDENTITY(1,1) PRIMARY KEY,
    Gebruikersnaam SYSNAME NOT NULL UNIQUE,
    Voornaam NVARCHAR(50) NOT NULL,
    Tussenvoegsel NVARCHAR(20) NULL,
    Achternaam NVARCHAR(80) NOT NULL,
    InDienst DATE NOT NULL,
    UitDienst DATE NULL,
    CONSTRAINT FK_Medewerkers_Gebruikers FOREIGN KEY (Gebruikersnaam) REFERENCES Gebruikers(Gebruikersnaam),
    CONSTRAINT CK_Medewerkers_Dienstverband CHECK (UitDienst IS NULL OR UitDienst >= InDienst)
);

INSERT INTO Medewerkers (Gebruikersnaam, Voornaam, Tussenvoegsel, Achternaam, InDienst, UitDienst)
VALUES
    (N'opticien', N'Emma', NULL, N'Bakker', CONVERT(DATE, '20180115', 112), CONVERT(DATE, NULL)),
    (N'leverancier01', N'Noah', NULL, N'Visser', CONVERT(DATE, '20200301', 112), CONVERT(DATE, NULL)),
    (N'leverancier02', N'Sophie', N'de', N'Vries', CONVERT(DATE, '20210412', 112), CONVERT(DATE, NULL)),
    (N'verkoper01', N'Lucas', NULL, N'Smit', CONVERT(DATE, '20220502', 112), CONVERT(DATE, NULL)),
    (N'verkoper02', N'Mila', NULL, N'Meijer', CONVERT(DATE, '20230601', 112), CONVERT(DATE, NULL)),
    (N'verkoper03', N'Finn', NULL, N'Mulder', CONVERT(DATE, '20240108', 112), CONVERT(DATE, NULL)),
    (N'oogmeter01', N'Julia', NULL, N'Bos', CONVERT(DATE, '20190916', 112), CONVERT(DATE, NULL)),
    (N'oogmeter02', N'Levi', N'van', N'Dijk', CONVERT(DATE, '20200701', 112), CONVERT(DATE, NULL)),
    (N'verkoper04', N'Zoe', NULL, N'Peters', CONVERT(DATE, '20170201', 112), CONVERT(DATE, '20221231', 112)),
    (N'oogmeter03', N'James', NULL, N'Hendriks', CONVERT(DATE, '20250501', 112), CONVERT(DATE, NULL));

CREATE TABLE Leveranciers (
    LeverancierID INT IDENTITY(1,1) PRIMARY KEY,
    Naam NVARCHAR(150) NOT NULL,
    Contactpersoon NVARCHAR(100) NULL,
    Telefoonnummer NVARCHAR(20) NULL,
    Email NVARCHAR(150) NULL,
    AdresID INT NULL,
    Gebruikersnaam SYSNAME NOT NULL UNIQUE,
    CONSTRAINT FK_Leveranciers_Adressen FOREIGN KEY (AdresID) REFERENCES Adressen(AdresID),
    CONSTRAINT FK_Leveranciers_Gebruikers FOREIGN KEY (Gebruikersnaam) REFERENCES Gebruikers(Gebruikersnaam),
    CONSTRAINT CK_Leveranciers_Contact CHECK (Email IS NOT NULL OR Telefoonnummer IS NOT NULL)
);

CREATE TABLE AfspraakTypen (
    AfspraakTypeID INT IDENTITY(1,1) PRIMARY KEY,
    Naam NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Afspraken (
    AfspraakID INT IDENTITY(1,1) PRIMARY KEY,
    KlantID INT NOT NULL,
    AfspraakTypeID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    Opmerking NVARCHAR(MAX) NULL,
    HerinneringVerzonden BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Afspraken_Klanten FOREIGN KEY (KlantID) REFERENCES Klanten(KlantID),
    CONSTRAINT FK_Afspraken_AfspraakTypen FOREIGN KEY (AfspraakTypeID) REFERENCES AfspraakTypen(AfspraakTypeID)
);

CREATE TABLE Oogmetingen (
    OogmetingID INT IDENTITY(1,1) PRIMARY KEY,
    KlantID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    Opmerkingen NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Oogmetingen_Klanten FOREIGN KEY (KlantID) REFERENCES Klanten(KlantID)
);

CREATE TABLE OogmetingDetails (
    OogmetingDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OogmetingID INT NOT NULL,
    Oog CHAR(1) NOT NULL CHECK (Oog IN ('L', 'R')),
    SPH DECIMAL(5,2) NULL,
    CYL DECIMAL(5,2) NULL,
    Axis INT NULL,
    [ADD] DECIMAL(5,2) NULL,
    PD DECIMAL(5,2) NULL,
    Prism DECIMAL(5,2) NULL,
    Opmerkingen NVARCHAR(MAX) NULL,
    CONSTRAINT FK_OogmetingDetails_Oogmetingen FOREIGN KEY (OogmetingID) REFERENCES Oogmetingen(OogmetingID),
    CONSTRAINT UQ_OogmetingDetails UNIQUE (OogmetingID, Oog),
    CONSTRAINT CK_OogmetingDetails_Axis CHECK (Axis IS NULL OR Axis BETWEEN 0 AND 180),
    CONSTRAINT CK_OogmetingDetails_PD CHECK (PD IS NULL OR PD > 0),
    CONSTRAINT CK_OogmetingDetails_Prism CHECK (Prism IS NULL OR Prism >= 0)
);

CREATE TABLE Recepten (
    ReceptID INT IDENTITY(1,1) PRIMARY KEY,
    KlantID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    Vervaldatum DATE NULL,
    Opmerkingen NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Recepten_Klanten FOREIGN KEY (KlantID) REFERENCES Klanten(KlantID),
    CONSTRAINT CK_Recepten_Vervaldatum CHECK (Vervaldatum IS NULL OR Vervaldatum >= CAST(DatumTijd AS DATE))
);

CREATE TABLE ReceptDetails (
    ReceptDetailID INT IDENTITY(1,1) PRIMARY KEY,
    ReceptID INT NOT NULL,
    Oog CHAR(1) NOT NULL CHECK (Oog IN ('L', 'R')),
    SPH DECIMAL(5,2) NULL,
    CYL DECIMAL(5,2) NULL,
    Axis INT NULL,
    [ADD] DECIMAL(5,2) NULL,
    PD DECIMAL(5,2) NULL,
    Prism DECIMAL(5,2) NULL,
    Opmerkingen NVARCHAR(MAX) NULL,
    CONSTRAINT FK_ReceptDetails_Recepten FOREIGN KEY (ReceptID) REFERENCES Recepten(ReceptID),
    CONSTRAINT UQ_ReceptDetails UNIQUE (ReceptID, Oog),
    CONSTRAINT CK_ReceptDetails_Axis CHECK (Axis IS NULL OR Axis BETWEEN 0 AND 180),
    CONSTRAINT CK_ReceptDetails_PD CHECK (PD IS NULL OR PD > 0),
    CONSTRAINT CK_ReceptDetails_Prism CHECK (Prism IS NULL OR Prism >= 0)
);

CREATE TABLE Producten (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Naam NVARCHAR(150) NOT NULL,
    Beschrijving NVARCHAR(MAX) NULL,
    Prijs DECIMAL(10,2) NOT NULL,
    Voorraad INT NOT NULL DEFAULT 0,
    LeverancierID INT NOT NULL,
    CONSTRAINT FK_Producten_Leveranciers FOREIGN KEY (LeverancierID) REFERENCES Leveranciers(LeverancierID),
    CONSTRAINT CK_Producten_Voorraad CHECK (Voorraad >= 0),
    CONSTRAINT CK_Producten_Prijs CHECK (Prijs >= 0)
);

CREATE TABLE Verkoop (
    VerkoopID INT IDENTITY(1,1) PRIMARY KEY,
    KlantID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    TotaalBedrag DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Verkoop_Klanten FOREIGN KEY (KlantID) REFERENCES Klanten(KlantID),
    CONSTRAINT CK_Verkoop_Totaal CHECK (TotaalBedrag >= 0)
);

CREATE TABLE VerkoopDetails (
    VerkoopDetailID INT IDENTITY(1,1) PRIMARY KEY,
    VerkoopID INT NOT NULL,
    ProductID INT NOT NULL,
    Aantal INT NOT NULL,
    Prijs DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_VerkoopDetails_Verkoop FOREIGN KEY (VerkoopID) REFERENCES Verkoop(VerkoopID),
    CONSTRAINT FK_VerkoopDetails_Producten FOREIGN KEY (ProductID) REFERENCES Producten(ProductID),
    CONSTRAINT CK_VerkoopDetails_Aantal CHECK (Aantal > 0),
    CONSTRAINT CK_VerkoopDetails_Prijs CHECK (Prijs >= 0)
);

CREATE TABLE Facturen (
    FactuurID INT IDENTITY(1,1) PRIMARY KEY,
    VerkoopID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    Betaald BIT NOT NULL DEFAULT 0,
    VerzekeringsClaimID INT NULL,
    CONSTRAINT FK_Facturen_Verkoop FOREIGN KEY (VerkoopID) REFERENCES Verkoop(VerkoopID),
    CONSTRAINT UQ_Facturen_Verkoop UNIQUE (VerkoopID)
);

CREATE TABLE VerzekeringsClaims (
    VerzekeringsClaimID INT IDENTITY(1,1) PRIMARY KEY,
    KlantID INT NOT NULL,
    VerkoopID INT NOT NULL,
    DatumTijd DATETIME2 NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_VerzekeringsClaims_Klanten FOREIGN KEY (KlantID) REFERENCES Klanten(KlantID),
    CONSTRAINT FK_VerzekeringsClaims_Verkoop FOREIGN KEY (VerkoopID) REFERENCES Verkoop(VerkoopID),
    CONSTRAINT CK_VerzekeringsClaims_Status CHECK (Status IN ('Pending', 'Approved', 'Rejected'))
);

ALTER TABLE Facturen
ADD CONSTRAINT FK_Facturen_VerzekeringsClaims
FOREIGN KEY (VerzekeringsClaimID) REFERENCES VerzekeringsClaims(VerzekeringsClaimID);
GO

CREATE FUNCTION Security.fn_LeverancierScope (@Gebruikersnaam SYSNAME)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS Toegestaan
    WHERE @Gebruikersnaam = USER_NAME()
       OR IS_ROLEMEMBER(N'db_opticien') = 1
       OR IS_ROLEMEMBER(N'db_verkoper') = 1;
GO

CREATE FUNCTION Security.fn_ProductLeverancierScope (@LeverancierID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS Toegestaan
    FROM dbo.Leveranciers AS leverancier
    WHERE leverancier.LeverancierID = @LeverancierID;
GO

CREATE SECURITY POLICY Security.LeverancierPolicy
    ADD FILTER PREDICATE Security.fn_LeverancierScope(Gebruikersnaam) ON dbo.Leveranciers,
    ADD BLOCK PREDICATE Security.fn_LeverancierScope(Gebruikersnaam) ON dbo.Leveranciers AFTER UPDATE,
    ADD FILTER PREDICATE Security.fn_ProductLeverancierScope(LeverancierID) ON dbo.Producten
WITH (STATE = ON);
GO

GRANT CONTROL ON DATABASE::ScherpInZicht TO db_opticien;

GRANT SELECT ON dbo.Leveranciers TO db_leverancier;
GRANT UPDATE (Naam, Contactpersoon, Telefoonnummer, Email, AdresID)
    ON dbo.Leveranciers TO db_leverancier;
GRANT SELECT ON dbo.Producten TO db_leverancier;
GRANT SELECT ON OBJECT::Security.fn_LeverancierScope TO db_leverancier;
GRANT SELECT ON OBJECT::Security.fn_ProductLeverancierScope TO db_leverancier;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Verkoop TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.VerkoopDetails TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Facturen TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.VerzekeringsClaims TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Klanten TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Afspraken TO db_verkoper;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Adressen TO db_verkoper;
GRANT SELECT ON dbo.Producten TO db_verkoper;
GRANT EXECUTE ON OBJECT::dbo.checkBsn TO db_verkoper;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Oogmetingen TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.OogmetingDetails TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Recepten TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ReceptDetails TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Klanten TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Afspraken TO db_oogmeter;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Adressen TO db_oogmeter;
GRANT EXECUTE ON OBJECT::dbo.checkBsn TO db_oogmeter;
GO

/*
Koppel echte SQL Server-databasegebruikers handmatig aan de databaserollen.
De databaseprincipalnaam moet overeenkomen met Gebruikers.Gebruikersnaam,
omdat de leveranciers-RLS USER_NAME() gebruikt.

Voorbeeld:
CREATE USER [verkoper01] FOR LOGIN [verkoper01];
ALTER ROLE db_verkoper ADD MEMBER [verkoper01];

-- Gebruik db_opticien, db_leverancier of db_oogmeter voor de overige gebruikers.
-- De gebruikersnaam in Gebruikers moet steeds gelijk zijn aan de databaseprincipalnaam.
*/

/*
Voorbeeld: voeg een verkoop met een verkoopdetail atomair toe.
Vul eerst bestaande KlantID- en ProductID-waarden in. Voer dit voorbeeld
los uit nadat het databasescript is uitgevoerd.

DECLARE @KlantID INT = NULL;
DECLARE @ProductID INT = NULL;
DECLARE @Aantal INT = 1;
DECLARE @Prijs DECIMAL(10,2);
DECLARE @VerkoopID INT;

IF @KlantID IS NULL OR @ProductID IS NULL
    THROW 50001, 'Vul een bestaande KlantID en ProductID in.', 1;

SELECT @Prijs = Prijs
FROM Producten
WHERE ProductID = @ProductID;

IF @Prijs IS NULL
    THROW 50002, 'Het opgegeven ProductID bestaat niet.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO Verkoop (KlantID, DatumTijd, TotaalBedrag)
    VALUES (@KlantID, SYSDATETIME(), @Prijs * @Aantal);

    SET @VerkoopID = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO VerkoopDetails (VerkoopID, ProductID, Aantal, Prijs)
    VALUES (@VerkoopID, @ProductID, @Aantal, @Prijs);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
*/