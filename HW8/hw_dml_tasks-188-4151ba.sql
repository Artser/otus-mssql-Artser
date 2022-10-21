/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Sales].[Customers](
       [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[PrimaryContactPersonID]      
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]      
      ,[DeliveryPostalCode] 
      ,[PostalAddressLine1]
      ,[PostalPostalCode]
      ,[LastEditedBy]
)
VALUES
		('Test1', 1, 3, 1001, 3, 19586, 19586, '20130101', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0100', 'http://www.tailspintoys.com', 'Shop 38', 90410, 'PO Box 8975', 90410, 1), 
		('Test2', 1, 3, 1001, 3, 19586, 19586, '20130101', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0100', 'http://www.tailspintoys.com', 'Shop 38', 90410, 'PO Box 8975', 90410, 1),
		('Test3', 1, 3, 1001, 3, 19586, 19586, '20130101', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0100', 'http://www.tailspintoys.com', 'Shop 38', 90410, 'PO Box 8975', 90410, 1), 
		('Test4', 1, 3, 1001, 3, 19586, 19586, '20130101', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0100', 'http://www.tailspintoys.com', 'Shop 38', 90410, 'PO Box 8975', 90410, 1), 
		('Test5', 1, 3, 1001, 3, 19586, 19586, '20130101', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0100', 'http://www.tailspintoys.com', 'Shop 38', 90410, 'PO Box 8975', 90410, 1)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [Sales].[Customers]
WHERE CustomerName = 'Test5';


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE [Sales].[Customers]
SET CustomerName = 'UpdateTest4'
WHERE CustomerName = 'Test4'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

select * into Sales.CustomersNew from Sales.Customers where 0 = 1
MERGE [Sales].[Customers1] AS target
      USING Sales.CustomersNew AS source ON (target.CustomerID = source.CustomerID)
WHEN MATCHED 
      THEN UPDATE SET CustomerName = source.CustomerName,  DeliveryMethodId = source.DeliveryMethodId
WHEN NOT MATCHED
  THEN INSERT (CustomerID,
       [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[PrimaryContactPersonID]      
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]      
      ,[DeliveryPostalCode] 
      ,[PostalAddressLine1]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	  ,[ValidFrom]
	  ,[ValidTo])
VALUES (source.CustomerID,
       source.[CustomerName]
      ,source.[BillToCustomerID]
      ,source.[CustomerCategoryID]
      ,source.[PrimaryContactPersonID]      
      ,source.[DeliveryMethodID]
      ,source.[DeliveryCityID]
      ,source.[PostalCityID]
      ,source.[AccountOpenedDate]
      ,source.[StandardDiscountPercentage]
      ,source.[IsStatementSent]
      ,source.[IsOnCreditHold]
      ,source.[PaymentDays]
      ,source.[PhoneNumber]
      ,source.[FaxNumber]
      ,source.[WebsiteURL]
      ,source.[DeliveryAddressLine1]      
      ,source.[DeliveryPostalCode] 
      ,source.[PostalAddressLine1]
      ,source.[PostalPostalCode]
      ,source.[LastEditedBy]
      ,source.[ValidFrom]
	  ,source.[ValidTo]);


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
--выгрузка в файл
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "D:\downloads\Sales.Customers.txt" -T -w -t"@eu&$1&" -S DESKTOP-AVUJ959'

--загрузка из файла в новую таблицу


BULK INSERT [WideWorldImporters].[Sales].[CustomersBulk]
				   FROM "D:\downloads\Sales.Customers.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@eu&$1&',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );
