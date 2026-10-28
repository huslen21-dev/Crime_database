-- =========================================================
-- 1. ашиглах өгөгдлийн санг сонгох
-- сервертэй холбогдсон query цонхонд ажиллуулна.
-- =========================================================
use chicagocrimedb;
go

-- команд бүрийн дараах "(... rows affected)" мэдэгдлийг нуух.
-- select-ийн үр дүнг нуухгүй.
set nocount on;

-- гүйлгээний явцад runtime алдаа гарвал гүйлгээг буцаахад ашиглана.
set xact_abort on;

-- огнооны дарааллыг сар/өдөр/жил гэж тохируулах.
set dateformat mdy;


-- =========================================================
-- 2. үндсэн хүснэгтийг шалгах
-- =========================================================

-- dbo.crimes_raw гэсэн хэрэглэгчийн хүснэгт байгаа эсэх.
-- 'u' нь хэрэглэгчийн хүснэгтийг заана.
-- байхгүй бол алдаа гаргаж энэ хэсгийн ажиллагааг зогсооно.
if object_id(N'dbo.crimes_raw', N'u') is null
    throw 50001, 'crimes_raw does not exist.', 1;

-- хүснэгтэд ядаж нэг мөр байвал дахин импортлохыг хориглоно.
-- энэ нь давхардлыг мөр бүрээр шалгахгүй;
-- зөвхөн хоосон хүснэгтэд импортлох нөхцөл тавьж байна.
if exists (select 1 from dbo.crimes_raw)
    throw 50002, 'target is not empty. import stopped to prevent duplicates.', 1;


-- =========================================================
-- 3. текстэн баганын багтаамжийг нэмэх
-- csv-ийн урт утгуудыг багтаахын тулд varchar(100) болгоно.
-- null нь утга байхгүй мөрийг зөвшөөрнө.
-- эдгээр өөрчлөлт доорх begin transaction-оос өмнө хийгдэнэ.
-- =========================================================
alter table dbo.crimes_raw
    alter column [c_block] varchar(100) null;

alter table dbo.crimes_raw
    alter column [primary_type] varchar(100) null;

alter table dbo.crimes_raw
    alter column [loc_description] varchar(100) null;


-- =========================================================
-- 4. csv унших түр хүснэгт үүсгэх
-- # тэмдэгтэй нэр нь тухайн холболтын түр хүснэгт.
-- холболт хаагдахад автоматаар устна.
--
-- csv-ийн 22 баганатай ижил дараалалтай байна.
-- огноо, тоо зэрэг бүх утгыг эхлээд текстээр уншина.
-- дараа нь үндсэн хүснэгт рүү оруулахдаа төрлийг хөрвүүлнэ.
--
-- ижил холболтод #crimecsv аль хэдийн байвал
-- create table дахин ажиллахад алдаа гарна.
-- =========================================================
create table #crimecsv
(
    [d_id]            varchar(50) null,
    [case_number]     varchar(50) null,
    [c_date]          varchar(50) null,
    [c_block]         varchar(50) null,
    [iucr]            varchar(50) null,
    [primary_type]    varchar(50) null,
    [c_description]   varchar(70) null,
    [loc_description] varchar(63) null,
    [arrest]          varchar(50) null,
    [domestic]        varchar(50) null,
    [beat]            varchar(50) null,
    [district]        varchar(50) null,
    [ward]            varchar(50) null,
    [community_area]  varchar(50) null,
    [fbi_code]        varchar(50) null,
    [x_coordinate]    varchar(50) null,
    [y_coordinate]    varchar(50) null,
    [c_year]          varchar(50) null,
    [update_on]       varchar(50) null,
    [latitude]       varchar(50) null,
    [longitude]      varchar(50) null,
    [c_location]     varchar(50) null
);


-- =========================================================
-- 5. импорт болон хөрвүүлэлтийг алдаа барих хэсэгт эхлүүлэх
-- try дотор баригдах алдаа гарвал catch хэсэгт шилжинэ.
-- =========================================================
begin try

    -- =====================================================
    -- 6. csv файлыг түр хүснэгтэд унших
    -- зам нь sql server ажиллаж буй компьютер дээрх зам.
    -- sql server уг файлыг унших эрхтэй байх шаардлагатай.
    -- =====================================================
    bulk insert #crimecsv
    from 'c:\users\dell\downloads\crimes_-_2001_to_present.csv'
    with
    (
        format = 'csv',          -- csv хэлбэрээр унших.
        firstrow = 2,            -- эхний гарчгийн мөрийг алгасах.
        fieldquote = '"',        -- хашилтад буй таслалыг утгын хэсэг гэж үзэх.
        fieldterminator = ',',   -- баганууд таслалаар тусгаарлагдана.
        rowterminator = '0x0a',  -- lf тэмдэгтээр мөр төгсөнө.
        codepage = '65001',      -- utf-8 кодчиллоор унших.
        tablock,                -- импортод хүснэгтийн түвшний түгжээ ашиглах.
        maxerrors = 0           -- тоологдох импортын алдаа алгасах хязгаар 0.
    );

    -- =====================================================
    -- 7. уншигдсан мөрийн тоог шалгах
    -- count_big нь мөрийн тоог bigint төрлөөр буцаана.
    -- шалгасан csv файл 8,667,702 өгөгдлийн мөртэй.
    -- файл солигдвол энэ хүлээгдэх тоог дахин шалгах хэрэгтэй.
    -- тоо таарахгүй бол үндсэн хүснэгт рүү оруулахгүй.
    -- =====================================================
    if (select count_big(*) from #crimecsv) <> 8667702
        throw 50003, 'imported row count does not match source file.', 1;


    -- =====================================================
    -- 8. үндсэн хүснэгт рүү оруулах гүйлгээг эхлүүлэх
    -- энэ цэгээс хойших insert нь гүйлгээнд хамрагдана.
    -- өмнөх bulk insert, alter table нь энэ гүйлгээнд орохгүй.
    -- =====================================================
    begin transaction;

    -- оруулах багануудыг дарааллаар нь заана.
    -- id баганыг оруулаагүй: identity тул автоматаар үүснэ.
    -- csv-ийн эх id нь d_id баганад хадгалагдана.
    insert into dbo.crimes_raw
    (
        [d_id],
        [case_number],
        [c_date],
        [c_block],
        [iucr],
        [primary_type],
        [c_description],
        [loc_description],
        [arrest],
        [domestic],
        [beat],
        [district],
        [ward],
        [community_area],
        [fbi_code],
        [x_coordinate],
        [y_coordinate],
        [c_year],
        [update_on],
        [latitude],
        [longitude],
        [c_location]
    )

    -- =====================================================
    -- 9. утгуудыг цэвэрлэж, төрлийг хөрвүүлэх
    --
    -- rtrim: төгсгөлийн энгийн зайг арилгана.
    -- ltrim: эхлэлийн энгийн зайг арилгана.
    -- nullif(утга, ''): хоосон текстийг null болгоно.
    -- upper: үсгийг том болгоно.
    -- convert: заасан өгөгдлийн төрөл рүү хөрвүүлнэ.
    --
    -- convert хөрвүүлж чадахгүй утгатай таарвал алдаа өгнө.
    -- үндсэн хүснэгтийн not null, check нөхцөлүүд мөн шалгагдана.
    -- =====================================================
    select
        -- эх id, хэргийн дугаарын захын зайг цэвэрлэх.
        nullif(ltrim(rtrim([d_id])), ''),
        nullif(ltrim(rtrim([case_number])), ''),

        -- хэргийн огноог datetime болгох.
        -- 101 нь mm/dd/yyyy огнооны хэлбэрийг заана.
        convert(datetime, nullif(ltrim(rtrim([c_date])), ''), 101),

        -- хаяг, ангилал, тайлбарын текстийг цэвэрлэх.
        nullif(ltrim(rtrim([c_block])), ''),
        nullif(ltrim(rtrim([iucr])), ''),
        nullif(ltrim(rtrim([primary_type])), ''),
        nullif(ltrim(rtrim([c_description])), ''),
        nullif(ltrim(rtrim([loc_description])), ''),

        -- true/false утгыг true/false болгон хувиргах.
        upper(nullif(ltrim(rtrim([arrest])), '')),
        upper(nullif(ltrim(rtrim([domestic])), '')),

        -- бүс, дүүрэг болон ангиллын кодуудыг цэвэрлэх.
        -- эдгээрийг текст хэвээр хадгална.
        nullif(ltrim(rtrim([beat])), ''),
        nullif(ltrim(rtrim([district])), ''),
        nullif(ltrim(rtrim([ward])), ''),
        nullif(ltrim(rtrim([community_area])), ''),
        nullif(ltrim(rtrim([fbi_code])), ''),

        -- координатыг бүхэл тоо болгох.
        -- хоосон утга нь null хэвээр үлдэнэ.
        convert(int, nullif(ltrim(rtrim([x_coordinate])), '')),
        convert(int, nullif(ltrim(rtrim([y_coordinate])), '')),

        -- оныг үндсэн хүснэгтийн char(4) баганад оруулах.
        nullif(ltrim(rtrim([c_year])), ''),

        -- шинэчилсэн огноог datetime болгох.
        convert(datetime, nullif(ltrim(rtrim([update_on])), ''), 101),

        -- өргөрөг, уртрагыг float төрлийн тоо болгох.
        convert(float, nullif(ltrim(rtrim([latitude])), '')),
        convert(float, nullif(ltrim(rtrim([longitude])), '')),

        -- location дахь cr буюу char(13) тэмдэгтийг арилгах.
        -- координатын хосыг текстээр хадгалж, хоосныг null болгох.
        nullif(replace([c_location], char(13), ''), '')

    from #crimecsv;

    -- оруулалт амжилттай бол гүйлгээг баталгаажуулна.
    commit transaction;

end try

-- =========================================================
-- 10. алдаа гарвал гүйлгээг буцаах
-- =========================================================
begin catch

    -- идэвхтэй гүйлгээ байвал үндсэн хүснэгт рүү хийсэн
    -- тухайн гүйлгээний оруулалтыг буцаана.
    if @@trancount > 0
        rollback transaction;

    -- анхны алдааны мэдээллийг дахин гаргана.
    throw;

end catch;


-- =========================================================
-- 11. импортын үр дүнг шалгах
-- =========================================================

-- үндсэн хүснэгтийн нийт мөрийн тоо.
select count_big(*) as totalrows
from dbo.crimes_raw;

-- шалгах зорилгоор эхний 20 мөрийг харуулах.
select top (20) *
from dbo.crimes_raw
order by id;

/*Gemt hergiin turluudeer ni angilj 
tus bur burtgegdsen tohioldol-iig haruulah*/
select Primary_type, count(*) as Burtgegdsen_tohioldol
from Crimes_Raw
Group by Primary_type
Order by Burtgegdsen_tohioldol desc;

select C_Year,  count(*) as tuhain_jild_garsan_gemt_hereg
from Crimes_Raw
Group by C_Year
Order by tuhain_jild_garsan_gemt_hereg desc;

select C_Description, count(*) as ymr_gemt_hereg_ve
from Crimes_Raw
Group by C_Description
Order by ymr_gemt_hereg_ve desc;

select C_Block, count(*) as davtan
from Crimes_Raw
Group by C_Block
Order by davtan desc;