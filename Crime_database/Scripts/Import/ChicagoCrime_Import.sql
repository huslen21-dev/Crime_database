-- Сервертэй холбогдсон query цонхонд ажиллуулна.
-- CSV файлыг импортлоно. Хүснэгт өгөгдөлтэй бол зогсоно.
-- SQL Server нь CSV файлыг унших эрхтэй байх шаардлагатай.
    USE ChicagoCrimeDB;
    GO
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET DATEFORMAT mdy;
    IF OBJECT_ID(N'dbo.Crimes_Raw', N'U') IS NULL
        THROW 50001, 'Crimes_Raw does not exist.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Crimes_Raw)
        THROW 50002, 'Target is not empty. Import stopped to prevent duplicates.', 1;

    ALTER TABLE dbo.Crimes_Raw ALTER COLUMN [C_Block] VARCHAR(100) NULL;
    ALTER TABLE dbo.Crimes_Raw ALTER COLUMN [Primary_type] VARCHAR(100) NULL;
    ALTER TABLE dbo.Crimes_Raw ALTER COLUMN [Loc_description] VARCHAR(100) NULL;

    CREATE TABLE #CrimeCsv (
        [d_ID] VARCHAR(50) NULL,
        [Case_number] VARCHAR(50) NULL,
        [C_Date] VARCHAR(50) NULL,
        [C_Block] VARCHAR(50) NULL,
        [IUCR] VARCHAR(50) NULL,
        [Primary_type] VARCHAR(50) NULL,
        [C_Description] VARCHAR(70) NULL,
        [Loc_description] VARCHAR(63) NULL,
        [Arrest] VARCHAR(50) NULL,
        [Domestic] VARCHAR(50) NULL,
        [Beat] VARCHAR(50) NULL,
        [District] VARCHAR(50) NULL,
        [Ward] VARCHAR(50) NULL,
        [Community_Area] VARCHAR(50) NULL,
        [FBI_code] VARCHAR(50) NULL,
        [X_Coordinate] VARCHAR(50) NULL,
        [Y_Coordinate] VARCHAR(50) NULL,
        [C_Year] VARCHAR(50) NULL,
        [Update_On] VARCHAR(50) NULL,
        [Latitude] VARCHAR(50) NULL,
        [Longitude] VARCHAR(50) NULL,
        [C_Location] VARCHAR(50) NULL
    );

    BEGIN TRY
        BULK INSERT #CrimeCsv
        FROM 'C:\Users\Dell\Downloads\Crimes_-_2001_to_Present.csv'
        WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"',
                FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a',
                CODEPAGE = '65001', TABLOCK, MAXERRORS = 0);
        IF (SELECT COUNT_BIG(*) FROM #CrimeCsv) <> 8667702
            THROW 50003, 'Imported row count does not match source file.', 1;
        BEGIN TRANSACTION;
        INSERT INTO dbo.Crimes_Raw (
            [d_ID],         [Case_number],      [C_Date],           [C_Block], 
            [IUCR],         [Primary_type],     [C_Description],    [Loc_description], 
            [Arrest],       [Domestic],         [Beat],             [District], 
            [Ward],         [Community_Area],   [FBI_code],         [X_Coordinate], 
            [Y_Coordinate], [C_Year],           [Update_On],        [Latitude], 
            [Longitude],    [C_Location]
        )
        SELECT
            NULLIF(LTRIM(RTRIM([d_ID])), ''),
            NULLIF(LTRIM(RTRIM([Case_number])), ''),
            CONVERT(DATETIME, NULLIF(LTRIM(RTRIM([C_Date])), ''), 101),
            NULLIF(TRIM     ([C_Block]),        ''),
            NULLIF(TRIM     ([IUCR]),              ''),
            NULLIF(TRIM     ([Primary_type]),       ''),
            NULLIF(TRIM     ([C_Description]),      ''),
            NULLIF(TRIM     ([Loc_description]),    ''),
      UPPER(NULLIF(TRIM     ([Arrest]),             '')),
      UPPER(NULLIF(TRIM     ([Domestic]),           '')),
            NULLIF(TRIM     ([Beat]),               ''),
            NULLIF(TRIM     ([District]),           ''),
            NULLIF(TRIM     ([Ward]),               ''),
            NULLIF(TRIM     ([Community_Area]),     ''),
            NULLIF(TRIM     ([FBI_code]),           ''),
        CONVERT(INT,        NULLIF(     TRIM([X_Coordinate]),   '')),
        CONVERT(INT,        NULLIF(     TRIM([Y_Coordinate]),  '')),
                            NULLIF(     TRIM([C_Year]),         ''),
        CONVERT(DATETIME,   NULLIF(     TRIM([Update_On]),     ''), 101),
        CONVERT(FLOAT,      NULLIF(     TRIM([Latitude]),      '')),
        CONVERT(FLOAT,      NULLIF(     TRIM([Longitude]),     '')),
                            NULLIF(TRIM(REPLACE([C_Location], CHAR(13), '')), '')
        FROM #CrimeCsv;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    
    SELECT COUNT_BIG(*) AS TotalRows FROM dbo.Crimes_Raw;
    SELECT * FROM dbo.Crimes_Raw ORDER BY ID;
