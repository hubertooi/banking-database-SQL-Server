DROP TABLE Balance_Change_History;
DROP TABLE Bank_Acc_Link;
DROP TABLE Wire_Transfer;
DROP TABLE Bank_Account_Type;
DROP TABLE Bank_User_Acc_Link;
DROP TABLE Bank;
DROP TABLE Purchase;
DROP TABLE Vendor;
DROP TABLE Transactions;
DROP TABLE Paid_Account;
DROP TABLE Free_Account;
DROP TABLE User_Account;

DROP SEQUENCE Balance_History_seq
DROP SEQUENCE Bank_Acc_seq;
DROP SEQUENCE Wire_Transfer_seq;
DROP SEQUENCE Bank_Account_seq;
DROP SEQUENCE Bank_User_Acc_seq;
DROP SEQUENCE Bank_seq;
DROP SEQUENCE Purchase_seq;
DROP SEQUENCE Vendor_seq;
DROP SEQUENCE Transactions_seq;
DROP SEQUENCE User_Account_seq;

-- User_Account table and sequence
CREATE TABLE User_Account(
	user_id DECIMAL(12) NOT NULL PRIMARY KEY,
	user_first_name VARCHAR(255) NOT NULL,
	user_last_name VARCHAR(255) NOT NULL,
	user_email VARCHAR(255) NOT NULL,
	user_phone_number DECIMAL(15) NOT NULL
);

CREATE SEQUENCE User_Account_seq START WITH 1;

-- Free_Account and Paid_Account table
CREATE TABLE Free_Account(
	user_id DECIMAL(12) NOT NULL PRIMARY KEY,
	free_indicator CHAR(1) NOT NULL,
	FOREIGN KEY (user_id) REFERENCES User_Account(user_id)
);

CREATE TABLE Paid_Account(
	user_id DECIMAL(12) NOT NULL PRIMARY KEY,
	paid_indicator CHAR(1) NOT NULL,
	FOREIGN KEY (user_id) REFERENCES User_Account(user_id)
);

--Transaction table and sequence
CREATE TABLE Transactions(
	transaction_id DECIMAL(12) NOT NULL PRIMARY KEY,
	user_id DECIMAL(12) NOT NULL,
	transaction_description VARCHAR(1000) NOT NULL,
	transaction_date DATE NOT NULL,
	FOREIGN KEY (user_id) REFERENCES User_Account(user_id)
);

CREATE SEQUENCE Transactions_seq START WITH 1;

-- Vendor table and sequence
CREATE TABLE Vendor(
	vendor_id DECIMAL(12) NOT NULL PRIMARY KEY,
	vendor_name VARCHAR(255) NOT NULL,
	vendor_email VARCHAR(255) NOT NULL,
	vendor_phone_number DECIMAL(15) NOT NULL
);

CREATE SEQUENCE Vendor_seq START WITH 1;

-- Purchase table and sequence
CREATE TABLE Purchase(
	purchase_id DECIMAL(12) NOT NULL PRIMARY KEY,
	vendor_id DECIMAL(12) NOT NULL,
	transaction_id DECIMAL(12) NOT NULL,
	product_name VARCHAR(255) NOT NULL,
	product_price DECIMAL(6,2) NOT NULL,
	FOREIGN KEY (vendor_id) REFERENCES Vendor(vendor_id),
	FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

CREATE SEQUENCE Purchase_seq START WITH 1;

--Bank table and sequence
CREATE TABLE Bank(
	bank_id DECIMAL(12) NOT NULL PRIMARY KEY,
	bank_name VARCHAR(255) NOT NULL,
	bank_phone_number DECIMAL(15) NOT NULL	
);

CREATE SEQUENCE Bank_seq START WITH 1;

--Bank_User_Acc_Link Table and sequence
CREATE TABLE Bank_User_Acc_Link(
	bank_user_link_id DECIMAL(12) NOT NULL PRIMARY KEY,
	user_id DECIMAL(12) NOT NULL,
	bank_id DECIMAL(12) NOT NULL,
	FOREIGN KEY (user_id) REFERENCES User_Account(user_id),
	FOREIGN KEY (bank_id) REFERENCES Bank(bank_id)
);

CREATE SEQUENCE Bank_User_Acc_seq START WITH 1;

-- Bank_Account_Type table and sequence
CREATE TABLE Bank_Account_Type(
	bank_account_id DECIMAL(12) NOT NULL PRIMARY KEY,
	account_name VARCHAR(255) NOT NULL,
	balance_amount DECIMAL(7,2) NOT NULL
);

CREATE SEQUENCE Bank_Account_seq START WITH 1;

-- Wire_Transfer table and sequence
CREATE TABLE Wire_Transfer(
	wire_transfer_id DECIMAL(12) NOT NULL PRIMARY KEY,
	bank_account_id DECIMAL(12) NOT NULL,
	transfer_amount DECIMAL(7,2) NOT NULL,
	transfer_date DATE NOT NULL,
);

CREATE SEQUENCE Wire_Transfer_seq START WITH 1;

-- Bank_Acc_Link table and sequence
CREATE TABLE Bank_Acc_Link(
	bank_account_link_id DECIMAL(12) NOT NULL PRIMARY KEY,
	bank_id DECIMAL(12) NOT NULL,
	bank_account_id DECIMAL(12) NOT NULL,
	FOREIGN KEY (bank_account_id) REFERENCES Bank_Account_Type(bank_account_id),
	FOREIGN KEY (bank_id) REFERENCES Bank(bank_id)
);

CREATE SEQUENCE Bank_Acc_seq START WITH 1;

-- Balance_Change_History table and sequence
CREATE TABLE Balance_Change_History(
	balance_history_id DECIMAL(12) NOT NULL PRIMARY KEY,
	bank_account_id DECIMAL(12) NOT NULL,
	old_balance DECIMAL(7,2) NOT NULL,
	new_balance DECIMAL(7,2) NOT NULL,
	change_date DATE
);

CREATE SEQUENCE Balance_History_seq START WITH 1;

GO
-- Balance_History_trigger
CREATE OR ALTER TRIGGER Balance_History_Trigger
ON Bank_Account_Type
AFTER UPDATE
AS
BEGIN
	DECLARE @old_balance_arg DECIMAL(7,2) = (SELECT balance_amount FROM DELETED);
	DECLARE @new_balance_arg DECIMAL(7,2) = (SELECT balance_amount FROM INSERTED);

	IF @old_balance_arg != @new_balance_arg
		INSERT INTO Balance_Change_History(balance_history_id,bank_account_id,old_balance,new_balance,change_date)
		VALUES(NEXT VALUE FOR Balance_History_seq,(SELECT bank_account_id FROM INSERTED), 
		@old_balance_arg, @new_balance_arg, GETDATE());

END;
GO

-- Trigger test
-- insert values into bank_account_type
--INSERT INTO Bank_Account_Type(bank_account_id,account_name,balance_amount)
--VALUES(NEXT VALUE FOR  Bank_Account_seq,'Chase Checking',2000);

--SELECT *
--FROM Bank_Account_Type;

--UPDATE Bank_Account_Type
--SET balance_amount = 1285.83
--WHERE bank_account_id = 1;

--SELECT *
--FROM Balance_Change_History;

-- First index creation
CREATE INDEX Transactions_Date_idx
ON Transactions(transaction_date);

-- Second index creation
CREATE INDEX Wire_Transfer_Date_idx
ON Wire_Transfer(transfer_date);

-- Thire index creation
CREATE INDEX Vendor_Name_idx
ON Vendor(vendor_name);

GO
-- Create procedure to insert user account with free account
CREATE OR ALTER PROCEDURE Add_User_Free_Acc @First_name VARCHAR(255), @Last_name VARCHAR(255), @Email VARCHAR(255),
@Phone_number DECIMAL(15)
AS
BEGIN
	DECLARE @User_id DECIMAL (12);
	SET @User_id = NEXT VALUE FOR User_Account_seq;
	INSERT INTO User_Account(user_id, user_first_name,user_last_name,user_email,user_phone_number)
	VALUES(@User_id,@First_name,@Last_name,@Email,@Phone_number);

	INSERT INTO Free_Account(user_id,free_indicator)
	VALUES(@User_id, 'F');
END;
GO

BEGIN TRANSACTION Add_User_Free_Acc;
EXECUTE Add_User_Free_Acc 'Hubert','Ooi','hubert96@gmail.com',5637566767;
COMMIT TRANSACTION Add_User_Free_Acc;

GO
-- Create procedure to insert user account with paid account
CREATE OR ALTER PROCEDURE Add_User_Paid_Acc @First_name VARCHAR(255), @Last_name VARCHAR(255), @Email VARCHAR(255),
@Phone_number DECIMAL(15)
AS
BEGIN
	DECLARE @User_id DECIMAL (12);
	SET @User_id = NEXT VALUE FOR User_Account_seq;
	INSERT INTO User_Account(user_id, user_first_name,user_last_name,user_email,user_phone_number)
	VALUES(@User_id,@First_name,@Last_name,@Email,@Phone_number);

	INSERT INTO Paid_Account(user_id,paid_indicator)
	VALUES(@User_id, 'P');
END;
GO

BEGIN TRANSACTION Add_User_Paid_Acc;
EXECUTE Add_User_Paid_Acc 'Shirley','He','shirley97@gmail.com',5157458073;
COMMIT TRANSACTION Add_User_Paid_Acc;

SELECT*
FROM User_Account;

SELECT*
FROM Free_Account;

SELECT*
FROM Paid_Account;

GO
-- Create procedure to insert Vendor info
CREATE OR ALTER PROCEDURE Add_Vendor @Vendor_name VARCHAR(255), @Vendor_email VARCHAR(255), 
@Vendor_phone_number DECIMAL(15)
AS
BEGIN
	DECLARE @Vendor_id DECIMAL (12);
	SET @Vendor_id = NEXT VALUE FOR Vendor_seq;
	INSERT INTO Vendor(vendor_id,vendor_name,vendor_email,vendor_phone_number)
	VALUES(@Vendor_id,@Vendor_name,@Vendor_email,@Vendor_phone_number);
END;
GO

BEGIN TRANSACTION Add_Vendor;
EXECUTE Add_Vendor 'IKEA','IKEA@IKEA.com',8888884532;
COMMIT TRANSACTION Add_Vendor;

SELECT *
FROM VENDOR;

GO
-- Create procedure to insert bank name and bank phone number
CREATE OR ALTER PROCEDURE Add_Bank @Bank_name VARCHAR(255), @Bank_phone_number DECIMAL(15)
AS
BEGIN
	DECLARE @Bank_id DECIMAL (12);
	SET @Bank_id = NEXT VALUE FOR Bank_seq;
	INSERT INTO Bank(bank_id,bank_name,bank_phone_number)
	VALUES(@Bank_id,@Bank_name,@Bank_phone_number);
END;
GO

GO
-- CREATE procedure to add Transactions and purchase 
CREATE OR ALTER PROCEDURE Add_Transactions_Purchase
@User_first_name VARCHAR(255),
@Transaction_description VARCHAR(1000), 
@Transaction_date DATE,
@Product_name VARCHAR(255),
@Vendor_name VARCHAR(255),
@Product_price DECIMAL(6,2)
AS
BEGIN
	DECLARE @Transaction_id DECIMAL(12), @User_id DECIMAL(12), @Purchase_id DECIMAL(12),
	@Vendor_id DECIMAL(12);
	SET @Transaction_id = NEXT VALUE FOR Transactions_seq;
	SET @User_id = (SELECT user_id FROM User_Account WHERE user_first_name = @User_first_name);
	SET @Purchase_id = NEXT VALUE FOR Purchase_seq;
	SET @Vendor_id = (SELECT vendor_id FROM Vendor WHERE vendor_name = @Vendor_name);

	INSERT INTO Transactions(transaction_id,user_id,transaction_description,transaction_date)
	VALUES(@Transaction_id,@User_id,@Transaction_description,@Transaction_date);

	INSERT INTO Purchase(purchase_id, vendor_id, transaction_id, product_name,product_price)
	VALUES(@Purchase_id,@Vendor_id,@Transaction_id,@Product_name,@Product_price);
END;
GO

GO
-- Create procedure to add banking info
CREATE OR ALTER PROCEDURE Add_Banking_Info
@User_first_name VARCHAR(255),
@User_bank_name VARCHAR(255),
@Account_name VARCHAR(255),
@Balance_amount DECIMAL(7,2)
AS 
BEGIN
	DECLARE @Bank_user_link_id DECIMAL(12), @User_id DECIMAL(12), @Bank_id DECIMAL(12),
	@Bank_account_id DECIMAL(12), @Bank_account_link_id DECIMAL(12)

	SET @Bank_user_link_id = NEXT VALUE FOR Bank_User_Acc_seq;
	SET @User_id = (SELECT user_id FROM User_Account WHERE user_first_name = @User_first_name);
	SET @Bank_id = (SELECT bank_id FROM Bank WHERE bank_name = @User_bank_name)
	SET @Bank_account_id = NEXT VALUE FOR Bank_Account_seq;
	SET @Bank_account_link_id = NEXT VALUE FOR Bank_Acc_seq;

	INSERT INTO Bank_User_Acc_Link(bank_user_link_id,user_id,bank_id)
	VALUES(@Bank_user_link_id, @User_id, @Bank_id);

	INSERT INTO Bank_Account_Type(bank_account_id,account_name,balance_amount)
	VALUES(@Bank_account_id,@Account_name,@Balance_amount);

	INSERT INTO Bank_Acc_Link(bank_account_link_id,bank_id,bank_account_id)
	VALUES(@Bank_account_link_id,@Bank_id,@Bank_account_id);
END;
GO

GO
CREATE OR ALTER PROCEDURE Add_Wire_Transfer
@Bank_account_id DECIMAL(12), @Transfer_amount DECIMAL(7,2), @Transfer_date DATE
AS
BEGIN
	DECLARE @Wire_Transfer_id DECIMAL(12);
	SET @Wire_Transfer_id = NEXT VALUE FOR Wire_Transfer_seq;

	INSERT INTO Wire_Transfer(wire_transfer_id,bank_account_id,transfer_amount,transfer_date)
	VALUES(@Wire_Transfer_id,@Bank_account_id,@Transfer_amount,@Transfer_date);
END;
GO


--Insert Bank name and phone number 
BEGIN TRANSACTION Add_Bank;
EXECUTE Add_Bank 'JP Morgan Chase',8009359935;
COMMIT TRANSACTION Add_Bank;

SELECT*
FROM Bank;

-- Adding more user with free account
BEGIN TRANSACTION Add_User_Free_Acc;
EXECUTE Add_User_Free_Acc 'Vincent','Choi','vincents@gmail.com',8915238383;
EXECUTE Add_User_Free_Acc 'Sophia','Long','long98@gmail.com',5438239021;
EXECUTE Add_User_Free_Acc 'Annika','Park','Annip@gmail.com',6325418396;
EXECUTE Add_User_Free_Acc 'Zack','Hansen','hansenz@gmail.com',9302001367;
EXECUTE Add_User_Free_Acc 'Devan','Goodwin','goodwin23@.com',7459035612;
COMMIT TRANSACTION Add_User_Free_Acc;

-- Adding more user with paid account
BEGIN TRANSACTION Add_User_Paid_Acc;
EXECUTE Add_User_Paid_Acc 'Percy','Spears','spears88@gmail.com',3456702301;
EXECUTE Add_User_Paid_Acc 'Rachel','Chang','rachel97@gmail.com',9035031032;
EXECUTE Add_User_Paid_Acc 'Carol','Morris','carol65@gmail.com',5958389203;
COMMIT TRANSACTION Add_User_Paid_Acc;

-- Adding more vendor
BEGIN TRANSACTION Add_Vendor;
EXECUTE Add_Vendor 'Stop&Shop','ss@shop.com',7813970006;
EXECUTE Add_Vendor 'CVS','cvs@customerservice.com',8007467287;
EXECUTE Add_Vendor 'Target','target@service.com',8004400680;
EXECUTE Add_Vendor 'Starbucks','starbucks@coffee.com',8005336705;
EXECUTE Add_Vendor 'Trader Joe','tj@joe.com',8008312703;
EXECUTE Add_Vendor 'Tj Max','tjmax@tjx',8005348578;
EXECUTE Add_Vendor 'Mcdonalds','Mc@donalds.com',800858535;
EXECUTE Add_Vendor 'Walmart','mart@walmart.com',8004400302;
EXECUTE Add_Vendor 'Gap','gap@gap.com',8005006329;
COMMIT TRANSACTION Add_Vendor;

-- Adding more banks
BEGIN TRANSACTION Add_Bank;
EXECUTE Add_Bank 'Wells Fargo',8008693557;
EXECUTE Add_Bank 'US bank',8008722657;
EXECUTE Add_Bank 'Bank of America',8004321000;
EXECUTE Add_Bank 'Capital One',8773834802;
EXECUTE Add_Bank 'American Express',8005284800;
EXECUTE Add_Bank 'Discover Financial',8003472683;
EXECUTE Add_Bank 'USAA',8005318722;
EXECUTE Add_Bank 'HSBC Bank',8009754722;
EXECUTE Add_Bank 'TIAA',8008422252;
COMMIT TRANSACTION Add_Bank;

-- Adding transactions
BEGIN TRANSACTION Add_Transactions_Purchase;
EXECUTE Add_Transactions_Purchase'Hubert','Beverage','02/01/2021','Mocha','Starbucks',3.99;
EXECUTE Add_Transactions_Purchase'Hubert','Furniture','02/14/2021','Sofa','IKEA',500.00;
EXECUTE Add_Transactions_Purchase'Shirley','Grocery','01/31/2021','Meat','Trader Joe',50.00;
EXECUTE Add_Transactions_Purchase'Shirley','Apparel','02/12/2021','Pink Dress','Gap',60.00;
EXECUTE Add_Transactions_Purchase'Vincent','Food','02/04/2021','Big Mac meal','Mcdonalds',9.86;
EXECUTE Add_Transactions_Purchase'Sophia','Pharmacy','02/08/2021','First Aid Kit','CVS',24.89;
EXECUTE Add_Transactions_Purchase'Annika','Apparel','01/28/2021','Winter Coat','Tj Max',70.56;
EXECUTE Add_Transactions_Purchase'Zack','Food','01/20/2021','Big Fries','Mcdonalds',3.97;
EXECUTE Add_Transactions_Purchase'Zack','Grocery','01/31/2021','5lb Potatoes','Walmart',2.50;
EXECUTE Add_Transactions_Purchase'Devan','Grocery','02/18/2021','Red Velvet Cake','Target',29.92;
EXECUTE Add_Transactions_Purchase'Percy','Beverage','01/18/2021','Pink Drink','Starbucks',5.24;
EXECUTE Add_Transactions_Purchase'Rachel','Apparel','02/02/2021','Denim Jeans','Gap',45.23;
EXECUTE Add_Transactions_Purchase'Rachel','Grocery','02/07/2021','Frozen Pizza','Trader Joe',20.86;
EXECUTE Add_Transactions_Purchase'Carol','Grocery','02/10/2021','Vegetables','Trader Joe',35.78;
COMMIT TRANSACTION Add_Transactions_Purchase;

-- Adding banking info
BEGIN TRANSACTION Add_Banking_Info;
EXECUTE Add_Banking_Info'Hubert','US Bank','US bank Checking',2000;
EXECUTE Add_Banking_Info 'Shirley','TIAA','TIAA Savings',3500;
EXECUTE Add_Banking_Info'Vincent','Wells Fargo','Wells Fargo Checking',1000;
EXECUTE Add_Banking_Info'Sophia','JP Morgan Chase','Chase Savings', 1567.90;
EXECUTE Add_Banking_Info'Annika','American Express','America Express Checking', 1200.00;
EXECUTE Add_Banking_Info 'Zack','Bank of America','Bank of America Checking',4230;
EXECUTE Add_Banking_Info'Devan','Capital One','Capital One Savings',3000;
EXECUTE Add_Banking_Info'Percy','USAA','USAA Savings',1004.50;
EXECUTE Add_Banking_Info 'Rachel','Discover Financial','Discover Savings',3040;
EXECUTE Add_Banking_Info 'Carol','HSBC Bank','HSBC Savings',1402.50;
COMMIT TRANSACTION Add_Banking_Info;

-- Adding Transition info
BEGIN TRANSACTION Add_Wire_Transfer;
EXECUTE Add_Wire_Transfer 1,20,'02/10/2021';
EXECUTE Add_Wire_Transfer 2,200,'01/03/2021';
EXECUTE Add_Wire_Transfer 3,100,'02/04/2021';
EXECUTE Add_Wire_Transfer 4,60,'01/06/2021';
EXECUTE Add_Wire_Transfer 5,400,'01/25/2021';
EXECUTE Add_Wire_Transfer 6,70,'02/15/2021';
EXECUTE Add_Wire_Transfer 7,100.45,'02/19/2021';
EXECUTE Add_Wire_Transfer 8,530,'01/20/2021';
EXECUTE Add_Wire_Transfer 9,400,'02/02/2021';
EXECUTE Add_Wire_Transfer 10,1000,'01/29/2021';
COMMIT TRANSACTION Add_Wire_Transfer;

-- Update after one wire transfer
Update Bank_Account_Type
SET balance_amount = 2020.00
WHERE bank_account_id = 1;

Update Bank_Account_Type
SET balance_amount = 3700.00
WHERE bank_account_id = 2;

Update Bank_Account_Type
SET balance_amount = 1100.00
WHERE bank_account_id = 3;

Update Bank_Account_Type
SET balance_amount = 1627.90
WHERE bank_account_id = 4;

Update Bank_Account_Type
SET balance_amount = 1700.00
WHERE bank_account_id = 5;

Update Bank_Account_Type
SET balance_amount = 4300.00
WHERE bank_account_id = 6;

Update Bank_Account_Type
SET balance_amount = 3100.45
WHERE bank_account_id = 7;

Update Bank_Account_Type
SET balance_amount = 1534.50
WHERE bank_account_id = 8;

Update Bank_Account_Type
SET balance_amount = 3440.00
WHERE bank_account_id = 9;

Update Bank_Account_Type
SET balance_amount = 2402.50
WHERE bank_account_id = 10;

-- Query quetion 1
-- Show all user balance history old and new balance with user name and banking information
SELECT User_Account.user_first_name, User_Account.user_last_name, Balance_Change_History.old_balance,
Balance_Change_History.new_balance, Bank.bank_name, Bank_Account_Type.account_name, Balance_Change_History.change_date
FROM User_Account
JOIN Bank_User_Acc_Link ON User_Account.user_id = Bank_User_Acc_Link.user_id
JOIN Bank ON Bank_User_Acc_Link.bank_id = Bank.bank_id
JOIN Bank_Acc_Link ON Bank.bank_id = Bank_Acc_Link.bank_id
JOIN Bank_Account_Type ON Bank_Acc_Link.bank_account_id = Bank_Account_Type.bank_account_id
JOIN Balance_Change_History ON Bank_Account_Type.bank_account_id = Balance_Change_History.bank_account_id;

-- Show the greatest balance differences as of today (02/24/2021) for all users
SELECT MAX(new_balance - old_balance) AS Difference_new_old_highest
FROM Balance_Change_History
WHERE change_date = '02/24/2021';

-- Query question 2
-- Show all users with paid or free account
-- F is free; P is paid
SELECT User_Account.user_first_name, User_Account.user_last_name,
User_Account.user_email,
User_Account.user_phone_number,
Free_Account.free_indicator,
Paid_Account.paid_indicator 
FROM User_Account
LEFT JOIN Free_Account ON User_Account.user_id = Free_Account.user_id
LEFT JOIN Paid_Account ON User_Account.user_id = Paid_Account.user_id;

-- Number of free and paid accounts number
SELECT COUNT(Free_Account.free_indicator) AS Free_Acc_User_Num,
COUNT(Paid_Account.paid_indicator) AS Paid_Acc_User_Num 
FROM User_Account
LEFT JOIN Free_Account ON User_Account.user_id = Free_Account.user_id
LEFT JOIN Paid_Account ON User_Account.user_id = Paid_Account.user_id;

-- Query question 3
-- Show all user_accounts purchases along vendor names associated with their purchase order by Last names
SELECT User_Account.user_first_name, User_Account.user_last_name,
Transactions.transaction_description, Purchase.product_name, Purchase.product_price, Vendor.vendor_name
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
ORDER BY User_Account.user_last_name;

-- Show all user_accounts purchases along vendor names associated with their purchase less than 25 usd
SELECT User_Account.user_first_name, User_Account.user_last_name,
Transactions.transaction_description, Purchase.product_name, Purchase.product_price, Vendor.vendor_name
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
WHERE Purchase.product_price <25;

-- Query question 4
-- Show total amount spend on each transaction description 
SELECT Transactions.transaction_description, SUM (Purchase.product_price) AS Sum_of_category
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
GROUP BY Transactions.transaction_description;

-- Find Average spending of all different transaction_descriptions of all users below 100 USD
SELECT Transactions.transaction_description, AVG (Purchase.product_price) AS Sum_of_category
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
GROUP BY Transactions.transaction_description
HAVING AVG (Purchase.product_price)<100;

-- Data used for pie chart one
-- Show total amount spend on each transaction description 
SELECT Transactions.transaction_description, SUM (Purchase.product_price) AS Sum_of_category
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
GROUP BY Transactions.transaction_description;

-- Find Average spending of all different transaction_descriptions of all users
SELECT Transactions.transaction_description, AVG (Purchase.product_price) AS Sum_of_category
FROM User_Account
JOIN Transactions ON User_Account.user_id = Transactions.user_id
JOIN Purchase ON Transactions.transaction_id = Purchase.transaction_id
JOIN Vendor ON Vendor.vendor_id = Purchase.vendor_id
GROUP BY Transactions.transaction_description;
