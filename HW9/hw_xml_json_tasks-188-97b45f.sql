/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--OPENXML
DECLARE @xmlDocument as xml
-- Считываем xml в созаднную переменную
SET @xmlDocument = (
SELECT * FROM OPENROWSET
(BULK 'C:\Users\NEXT\Downloads\StockItems-188-1fb5df.xml', SINGLE_BLOB) as data);
-- сопоставляем документ
SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument --возвращает дескриптор, который можно использовать для доступа к созданному внутреннему представлению XML-документа

SELECT @docHandle as docHandle


SELECT * FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH (
StockItemName nvarchar(100) '@Name',
SupplierID int 'SupplierID',
UnitPackageID int 'Package/UnitPackageID',
OuterPackageID int 'Package/OuterPackageID',
QuantityPerOuter int 'Package/QuantityPerOuter',
TypicalWeightPerUnit  nvarchar(100) 'Package/TypicalWeightPerUnit',
LeadTimeDays int 'LeadTimeDays',
IsChillerStock int 'IsChillerStock',
TaxRate decimal 'TaxRate',
UnitPrice decimal 'UnitPrice'
)

DROP TABLE IF EXISTS #tmp_xml

CREATE TABLE #tmp_xml (
StockItemName nvarchar(100),
SupplierID int,
UnitPackageID int,
OuterPackageID int,
QuantityPerOuter int,
TypicalWeightPerUnit  nvarchar(100),
LeadTimeDays int,
IsChillerStock int,
TaxRate decimal,
UnitPrice decimal
)

INSERT INTO #tmp_xml
SELECT * FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH (
StockItemName nvarchar(100) '@Name',
SupplierID int 'SupplierID',
UnitPackageID int 'Package/UnitPackageID',
OuterPackageID int 'Package/OuterPackageID',
QuantityPerOuter int 'Package/QuantityPerOuter',
TypicalWeightPerUnit  nvarchar(100) 'Package/TypicalWeightPerUnit',
LeadTimeDays int 'LeadTimeDays',
IsChillerStock int 'IsChillerStock',
TaxRate decimal 'TaxRate',
UnitPrice decimal 'UnitPrice'
)

EXEC sp_xml_removedocument @docHandle --удаляем чтобы не перегружать память

SELECT * FROM #tmp_xml

MERGE Warehouse.StockItems as target
     USING #tmp_xml as source ON (target.StockItemName collate Cyrillic_General_CI_AS = source.StockItemName collate Cyrillic_General_CI_AS)
     WHEN MATCHED
     THEN UPDATE SET 
                SupplierID  =source.SupplierID,
                UnitPackageID = source.UnitPackageID,
                OuterPackageID = source.OuterPackageID,
                QuantityPerOuter = source.QuantityPerOuter,
                TypicalWeightPerUnit  = source.TypicalWeightPerUnit,
                LeadTimeDays = source.LeadTimeDays,
                IsChillerStock = source.IsChillerStock,
                TaxRate = source.TaxRate,
                UnitPrice = source.UnitPrice
    WHEN NOT MATCHED
    THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice)
         VALUES  (source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter, source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock, source.TaxRate, source.UnitPrice)
OUTPUT deleted.*, $action, inserted.*
        ;

--XQuery

DECLARE @xmlDocument2 as xml
-- Считываем xml в созаднную переменную
SET @xmlDocument2 = (
SELECT * FROM OPENROWSET (BULK 'C:\Users\NEXT\Downloads\StockItems-188-1fb5df.xml', SINGLE_BLOB) as data)

DROP TABLE IF EXISTS #tmp2_xml
CREATE TABLE #tmp2_xml (
StockItemName nvarchar(100),
SupplierID int,
UnitPackageID int,
OuterPackageID int,
QuantityPerOuter int,
TypicalWeightPerUnit  float,
LeadTimeDays int,
IsChillerStock int,
TaxRate decimal,
UnitPrice decimal
)

INSERT INTO #tmp2_xml
SELECT
q.StockItems.value('(@Name)[1]', 'nvarchar(100)') as StockItemName,
q.StockItems.value('(SupplierID)[1]','int') as SupplierID,
q.StockItems.value('(Package/UnitPackageID)[1]', 'int') as UnitPackageID,
q.StockItems.value('(Package/OuterPackageID)[1]', 'int') as OuterPackageID,
q.StockItems.value('(Package/QuantityPerOuter)[1]', 'int') as QuantityPerOuter,
q.StockItems.value('(Package/TypicalWeightPerUnit)[1]','decimal(18,3)') as TypicalWeightPerUnit,
q.StockItems.value('(LeadTimeDays)[1]','int') as LeadTimeDays,
q.StockItems.value('(IsChillerStock)[1]', 'int') as IsChillerStock,
q.StockItems.value('(TaxRate)[1]','decimal') as TaxRate,
q.StockItems.value('(UnitPrice[1]','decimal') as UnitPrice
FROM @xmlDocument2.nodes('/StockItems/Item') as q(StockItems)
SELECT * FROM #tmp2_xml;
MERGE Warehouse.StockItems as target
     USING #tmp2_xml as source ON (target.StockItemName collate Cyrillic_General_CI_AS = source.StockItemName collate Cyrillic_General_CI_AS)
     WHEN MATCHED
     THEN UPDATE SET 
                SupplierID  =source.SupplierID,
                UnitPackageID = source.UnitPackageID,
                OuterPackageID = source.OuterPackageID,
                QuantityPerOuter = source.QuantityPerOuter,
                TypicalWeightPerUnit  = source.TypicalWeightPerUnit,
                LeadTimeDays = source.LeadTimeDays,
                IsChillerStock = source.IsChillerStock,
                TaxRate = source.TaxRate,
                UnitPrice = source.UnitPrice
    WHEN NOT MATCHED
    THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice)
         VALUES  (source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter, source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock, source.TaxRate, source.UnitPrice,'1')
OUTPUT deleted.*, $action, inserted.*
        ;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

напишите здесь свое решение


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

напишите здесь свое решение

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


напишите здесь свое решение
