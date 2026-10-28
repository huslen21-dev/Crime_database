CREATE TABLE [dbo].[Crimes_Raw]
(
    ID              INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    d_ID            CHAR(11) NOT NULL,
    Case_number     CHAR(10) NOT NULL,
    C_Date          DATETIME NULL,
    C_Block         VARCHAR(40) NULL,
    IUCR            CHAR(8) NULL,
    Primary_type    CHAR(40) NULL,
    C_Description   VARCHAR(100) NULL,
    Loc_description CHAR(60) NULL,

    Arrest VARCHAR(5) NOT NULL
        CHECK (Arrest IN ('TRUE', 'FALSE')),

    Domestic VARCHAR(5) NOT NULL
        CHECK (Domestic IN ('TRUE', 'FALSE')),

    Beat            CHAR(6) NULL,
    District        CHAR(3) NULL,
    Ward            CHAR(3) NULL,
    Community_Area  CHAR(3) NULL,
    FBI_code        CHAR(3) NULL,
    X_Coordinate    INT NULL,
    Y_Coordinate    INT NULL,
    C_Year          CHAR(4) NULL,
    Update_On       DATETIME NULL,
    Latitude        FLOAT NULL,
    Longitude       FLOAT NULL,
    C_Location      VARCHAR(100) NULL
);
