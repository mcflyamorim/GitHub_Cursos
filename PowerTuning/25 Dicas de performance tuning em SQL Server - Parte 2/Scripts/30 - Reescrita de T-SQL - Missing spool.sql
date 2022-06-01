/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

IF OBJECT_ID('TabOrders') IS NOT NULL
  DROP TABLE TabOrders
GO
CREATE TABLE [dbo].[TabOrders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL, 
 [Col1] VARCHAR(250)
) ON [PRIMARY]
GO
INSERT INTO [TabOrders] WITH (TABLOCK) ([CustomerID], OrderDate, Value, Col1) 
SELECT TOP 100000
       ABS(CHECKSUM(NEWID())) / 1000000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VARCHAR(250), NEWID()) AS Col1
  FROM master.dbo.sysobjects A
 CROSS JOIN master.dbo.sysobjects B
 CROSS JOIN master.dbo.sysobjects C
 CROSS JOIN master.dbo.sysobjects D
GO
ALTER TABLE TabOrders ADD CONSTRAINT xpk_TabOrders PRIMARY KEY(OrderID)
GO

IF OBJECT_ID('TabCustomers') IS NOT NULL
  DROP TABLE TabCustomers
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS CustomerID,
       ABS(CHECKSUM(NEWID())) / 100000000 AS CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO TabCustomers
  FROM master.dbo.sysobjects A
 CROSS JOIN master.dbo.sysobjects B
 CROSS JOIN master.dbo.sysobjects C
 CROSS JOIN master.dbo.sysobjects D
GO
ALTER TABLE TabCustomers ADD CONSTRAINT xpk_TabCustomers PRIMARY KEY(CustomerID)
GO

IF OBJECT_ID('TabCities') IS NOT NULL
  DROP TABLE TabCities
GO
CREATE TABLE [dbo].TabCities(
	[CityID] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](200) NULL,
	[Col1] [varchar](250) NULL,
	[Col2] [CHAR](7000) NULL,
 CONSTRAINT [xpl_TabCities] PRIMARY KEY CLUSTERED 
(
	[CityID] ASC
)
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[TabCities] ON 
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (1, N'Aachen', N'3E41114F-9105-41F5-9A13-E9FECBCF6CF8', N'A8FA7492-1AEF-4D57-BF69-1CA89C187389')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (2, N'Albuquerque', N'FA86DB36-2F81-4351-B034-240E557849EF', N'EA10FE0F-289A-4E61-9A5B-CF289C92BAB9')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (3, N'Anchorage', N'DD0382B5-948F-41BF-A283-C25A1DB7A136', N'FA2D6AB6-AD58-4E27-8F0B-7CC827D21912')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (4, N'Århus', N'B666BABD-FB63-4131-89B3-A86470DCF523', N'6421197F-3ECD-40EB-992D-2EAEEA279580')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (5, N'Barcelona', N'4C758261-7E83-4F55-BC23-B1EA002CD0AC', N'28BD3BB8-12D5-4E33-80CD-3932046A7840')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (6, N'Barquisimeto', N'140D57EF-FA2A-4C9C-9EEF-EACD508595EB', N'72B6B87F-7B13-4CE6-BB98-2A59137D7A8D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (7, N'Bergamo', N'F5F0C862-E972-4C87-AC55-A18CF3032B03', N'3E6D52DD-0DA8-43BC-928C-3C253D1BC211')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (8, N'Berlin', N'49AAF7C8-60CA-4750-BDAC-F46F1CCE1D95', N'27890E7E-2487-462F-8FC4-75B39F4798A2')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (9, N'Bern', N'C1A9B29F-2013-4FEE-A2F3-7038A8FC7560', N'62964FA3-CC82-44DA-BFA2-79989CDD655F')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (10, N'Boise', N'A7FE5283-6D1C-4C81-8C11-A9E3331DF86C', N'80E746A5-EDC8-4630-B413-98F5D1C55F3C')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (11, N'Bräcke', N'859FFF5B-6AB6-4486-92B8-E3A236A080D9', N'65928A14-6CF1-4257-9254-0EABAA36DE18')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (12, N'Brandenburg', N'75FEE37D-53EE-4662-B1A5-E400508C01D8', N'64E1C521-BAE0-4BF6-B5CC-1EB5BE587A86')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (13, N'Bruxelles', N'405A3794-58E2-4A0E-9E16-2E7EB0F547B8', N'3DBDE2E6-7E30-46D9-8807-AC6BAD873127')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (14, N'Buenos Aires', N'AC284463-7715-48BD-B0F0-72C505D44C72', N'7A83A77B-635E-4D23-8F97-E6F77454E984')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (15, N'Butte', N'3FB6EEFC-2344-438C-AA1B-E6CB251853E3', N'67CE0237-B3F9-4EDA-963A-88DCDFFC4108')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (16, N'Campinas', N'A338C907-ABCD-4B19-A932-EC4841EDF72F', N'7268ED67-B6A2-486E-969C-D3395F71F038')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (17, N'Caracas', N'83FF2FE5-941A-47AD-93FA-37BB07DFA141', N'4B84BA1E-4ECA-4024-A81C-280B2B192468')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (18, N'Charleroi', N'41AB0797-280B-47CB-B782-C92294EDFD14', N'197EB28B-E979-477B-AF35-A600ED4EDEB2')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (19, N'Cork', N'008D305F-351C-4BA8-A862-63AAA468F120', N'AA130E3F-69D5-40BE-AD03-3C6F7E71BB61')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (20, N'Cowes', N'62CC762F-ECD6-4880-9224-84D1395ED9FC', N'5DB757BF-9782-4944-886A-67695AE909A8')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (21, N'Cunewalde', N'AF7639BD-2206-475D-995F-94E567170968', N'8EE2E272-C5AC-4ABB-8EB2-6261BB84F082')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (22, N'Elgin', N'2910EAB9-3B75-4199-8CC3-26EA49988B84', N'A3472E1C-9F83-48EC-BB48-6A332D1BED5D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (23, N'Eugene', N'AA9D28C4-C5E4-46E7-94DE-B9E7A7E5DBA0', N'6DA3AC70-5811-4099-AE5A-C5527BEADCC4')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (24, N'Frankfurt a.M.', N'C084EB93-66BB-42BA-A3EF-CFC3FBBEE76F', N'4F44A6A4-DCF2-42DA-B9BB-297724D54C9B')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (25, N'Genève', N'B0ED8995-5E13-47B8-A8F7-8C9F85452FAD', N'AD55912B-3B1F-4BF9-9393-7CCE5A63330D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (26, N'Graz', N'B81AF3BE-4795-4E94-B12D-90D8297A7334', N'2929A389-20C3-41D9-927F-D73C148B824F')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (27, N'Helsinki', N'A6E98A3C-F53F-47D2-85A1-427746C384A5', N'9DB25A4C-9A40-43DE-9B99-C7B795548AE7')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (28, N'I. de Margarita', N'413A063D-B4EA-459C-8970-EB5B856E3BF1', N'66F3B5E5-F617-4E86-9019-85FA03F0FB1D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (29, N'Kirkland', N'5D80791A-4FC4-46E3-BDBB-833C94235B5D', N'49C2BE2C-35F2-4D37-AD21-B0D8E2172A7F')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (30, N'Kobenhavn', N'C9B115CD-CFE3-4BCB-864B-B2C7406399F9', N'1EDBE7B4-9730-4E42-8E68-54E57821729D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (31, N'Köln', N'DD798AA1-BF6F-4ADE-B55D-192D356C2DD7', N'37954448-CB2E-41A0-846A-2BC20686989C')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (32, N'Lander', N'14AE0D37-19B9-4089-92E1-DE7FD9DD81A9', N'D44D048B-46F6-4032-A299-CB199C265198')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (33, N'Leipzig', N'2357ADCA-DA2B-46DC-B5D7-7D8FCAD61D0F', N'1243B9C6-B20E-41B5-82AF-16634C42FBBD')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (34, N'Lille', N'FA589502-6054-4E1D-9511-57A2B658E0B2', N'5CF8B23F-5A38-42EF-A120-61ECD3E10883')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (35, N'Lisboa', N'48EA985C-637E-40AB-97D2-41F44F063676', N'A81E158A-C04B-4788-9A7F-3D6834A2083B')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (36, N'London', N'2E48A370-4E18-439E-AC34-44F13AD3866D', N'12D0F02D-B742-44B2-BF82-93AA76F1B9C3')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (37, N'Luleå', N'2118FBBB-2E45-4430-8598-BCEB882C9833', N'9B5D43BE-51D9-462E-A19A-0B4CE54B4D6E')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (38, N'Lyon', N'3963D904-2B3E-4F9F-90AD-14DEE0B25E2B', N'0CE5CFEC-C5A3-47C2-8C0B-02C908556C2A')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (39, N'Madrid', N'2066E931-CFE7-4CC4-B7DD-EEB496F2B7CF', N'3D0DE896-6233-4807-B556-69F216A78012')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (40, N'Mannheim', N'1DC99A12-B0AB-4C2E-B23D-3F2414EAC28B', N'D240E880-208D-48B8-8AD7-CFB816A1CA0D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (41, N'Marseille', N'CE836511-AEA6-4637-BF88-50214BB8BDB7', N'6EC69505-CA0D-4E1B-A464-1274316A5812')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (42, N'México D.F.', N'656C7233-1F85-4456-8C72-6F99ABF3E099', N'D78D8AC3-1A8C-431E-BE6B-4EA861B9371E')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (43, N'Montréal', N'9A137E8C-C5B8-410C-BA09-3B0A64F69198', N'22D63451-A265-4337-A340-A5C7BB070209')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (44, N'München', N'6E68F767-71A7-42D6-B5FE-39DFA46F01DA', N'07B6A303-857B-47EC-866E-65F47EF3FAE9')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (45, N'Münster', N'304BBF73-AD24-41DB-BD9C-10A8099C2216', N'1AAF229C-0AA4-4AA8-BF74-029166E4A01E')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (46, N'Nantes', N'A155F638-F612-44AA-8BD6-79A4D048C80F', N'61980547-B087-41AB-8E52-8D28BF2AB0E8')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (47, N'Oulu', N'31D3DE37-CBF3-4444-857E-383DAB8D439D', N'5164D0F4-D1A9-42A7-97BE-C5FE14E0EA22')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (48, N'Paris', N'EEB626FC-BB90-4D2C-987B-316729888646', N'664FD2F0-A3B0-4C27-9FD0-F1B79B3B8194')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (49, N'Portland', N'B75025A8-D5C5-498D-BF15-CC8242A139FF', N'8B95B2AA-D257-4C55-A89F-CA00FE2023F0')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (50, N'Reggio Emilia', N'BDDACF41-8F51-4B87-9EF5-6B49AE289A41', N'3F1ADBD1-AF64-4FF1-A535-B0308C6761BC')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (51, N'Reims', N'EFB7294D-BA37-4A03-BF0B-B0A6222E50B7', N'3A6F03C1-42A1-47DE-96BB-6745A13CDB1C')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (52, N'Resende', N'9A98C103-C9C3-4EE1-A104-9E2A47C6800B', N'85C0A0FF-EF98-4717-B476-3BFDA131ADA1')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (53, N'Rio de Janeiro', N'8C7E3928-CB2A-42EE-892F-A5A8D348052D', N'36792526-57EC-472D-8DA6-C9BDAB56382E')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (54, N'Salzburg', N'8EB377B0-46D3-4130-8165-6865AB0D5128', N'40C9F6D0-AD5C-4829-B9F3-B288BE6CA3CE')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (55, N'San Cristóbal', N'28A68F1D-CCB9-4FD4-9057-877876273671', N'503C052E-AB74-4F1C-9FF5-8BBC8771FED0')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (56, N'San Francisco', N'6581650C-CD74-4C74-AD7D-4513F3C8F9A9', N'E19DFD43-EB89-4319-A825-BB489A83FCE6')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (57, N'Sao Paulo', N'2635A1BA-38EA-47FB-8149-E6F49A086F7D', N'64EE8011-15A7-4BD1-8445-9F425F681301')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (58, N'Seattle', N'C5AAB67A-FD2D-4D9B-9B4A-82A62AB0BE56', N'97EF91CC-080F-4134-B963-6BDD3E26FF78')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (59, N'Sevilla', N'7DA8940B-CA37-45DD-9973-D0FCDC9AAB1A', N'71D018E1-27DF-4F71-B91B-F20AAE8EBF2A')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (60, N'Stavern', N'612DA443-E660-4717-901E-758464C09D03', N'7D91298D-F24E-4C76-9D99-C06F672353C8')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (61, N'Strasbourg', N'A99AC10A-4A5A-4285-BD45-3D485912AF5F', N'0032B4F8-8F92-4521-A133-098A53058602')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (62, N'Stuttgart', N'9A7CC203-6A3E-4AFD-BB72-61DC5ABD0F8B', N'54D1563C-BC90-4FEE-B926-9545541AC655')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (63, N'Torino', N'9A6CB716-4B94-4749-BEFA-91C233F601FC', N'84CA93A8-463C-4D0A-8DCB-0ACCCFC0E45D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (64, N'Toulouse', N'C18A59EF-83DA-4C97-80BF-47F703C1ECF1', N'63DD9FE4-353A-4A29-8CBE-4F8D1589FCA4')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (65, N'Tsawassen', N'A18938C4-851F-4254-A4C0-093CD6ACEA41', N'1620C17A-1A85-4D92-88FE-3751F27B9F4D')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (66, N'Vancouver', N'FF753E75-7CD7-434D-94FE-481AE1D8F8EF', N'BE42954E-A197-4401-B02C-C40FBC52260F')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (67, N'Versailles', N'F5CFE1ED-3F1B-40B3-9DE5-CF886CD1792D', N'2C26A395-F43B-405D-9153-AB2DD13EFD3A')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (68, N'Walla Walla', N'09F4EF6D-A48D-481C-8A7E-0FB07FBA5232', N'9659BA00-959E-4CC9-BDC7-39BF16474AD9')
INSERT [dbo].[TabCities] ([CityID], [CityName], [Col1], [Col2]) VALUES (69, N'Warszawa', N'92D2AA44-0C71-428C-8496-8A5EE291F7CA', N'D684C811-97E4-4DAD-923F-282B42E32A4F')
SET IDENTITY_INSERT [dbo].[TabCities] OFF
GO



-- Query com problema
SET STATISTICS IO ON
SELECT TabOrders.*,
       ISNULL((SELECT Col1 
                 FROM TabCities 
                WHERE TabCities.CityName = 'Berlin'), '') + CASE TabOrders.Col1
                                                              WHEN 'RD' THEN 'a/'
                                                              WHEN 'SD' THEN 'a/'
                                                              WHEN 'WD' THEN 'a/'
                                                              WHEN 'XD' THEN 'a/'
                                                              ELSE ''
                                                            END + ISNULL(TabOrders.Col1, '') AS ColBerlin,
       ISNULL((SELECT Col1 
                 FROM TabCities 
                WHERE TabCities.CityName = 'Barcelona'), '') + CASE TabOrders.Col1
                                                                 WHEN 'RD' THEN 'a/'
                                                                 WHEN 'SD' THEN 'a/'
                                                                 WHEN 'WD' THEN 'a/'
                                                                 WHEN 'XD' THEN 'a/'
                                                                 ELSE ''
                                                               END + ISNULL(TabOrders.Col1, '') AS ColBarcelona,
       ISNULL((SELECT Col1 
                 FROM TabCities 
                WHERE TabCities.CityName = 'London'), '') + CASE TabOrders.Col1
                                                              WHEN 'RD' THEN 'a/'
                                                              WHEN 'SD' THEN 'a/'
                                                              WHEN 'WD' THEN 'a/'
                                                              WHEN 'XD' THEN 'a/'
                                                              ELSE ''
                                                            END + ISNULL(TabOrders.Col1, '') AS ColLondon,
       ISNULL((SELECT Col1 
                 FROM TabCities 
                WHERE TabCities.CityName = 'Lisboa'), '') + CASE TabOrders.Col1
                                                              WHEN 'RD' THEN 'a/'
                                                              WHEN 'SD' THEN 'a/'
                                                              WHEN 'WD' THEN 'a/'
                                                              WHEN 'XD' THEN 'a/'
                                                              ELSE ''
                                                            END + ISNULL(TabOrders.Col1, '') AS ColLisboa,
       ISNULL((SELECT Col1 
                 FROM TabCities 
                WHERE TabCities.CityName = 'Caracas'), '') + CASE TabOrders.Col1
                                                               WHEN 'RD' THEN 'a/'
                                                               WHEN 'SD' THEN 'a/'
                                                               WHEN 'WD' THEN 'a/'
                                                               WHEN 'XD' THEN 'a/'
                                                               ELSE ''
                                                             END + ISNULL(TabOrders.Col1, '') AS ColCaracas,
       ISNULL((@ResultadoParis), '') + CASE TabOrders.Col1
                                                             WHEN 'RD' THEN 'a/'
                                                             WHEN 'SD' THEN 'a/'
                                                             WHEN 'WD' THEN 'a/'
                                                             WHEN 'XD' THEN 'a/'
                                                             ELSE ''
                                                           END + ISNULL(TabOrders.Col1, '') AS ColParis
  FROM TabOrders
  JOIN TabCustomers 
    ON TabCustomers.CustomerID = TabOrders.CustomerID
 WHERE TabOrders.OrderID BETWEEN 1 AND 110
 ORDER BY TabOrders.Value
SET STATISTICS IO ON
GO

-- "Spool" manual utilizando as variáveis
DECLARE @Berlin_Value    VARCHAR(250),
        @Barcelona_Value VARCHAR(250),
        @London_Value    VARCHAR(250),
        @Lisboa_Value    VARCHAR(250),
        @Caracas_Value   VARCHAR(250),
        @Paris_Value     VARCHAR(250);

SELECT @Berlin_Value = CASE CityName WHEN 'Berlin' THEN Col1 ELSE @Berlin_Value END,
       @Barcelona_Value = CASE CityName WHEN 'Barcelona' THEN Col1 ELSE @Berlin_Value END,
       @London_Value = CASE CityName WHEN 'London' THEN Col1 ELSE @Berlin_Value END,
       @Lisboa_Value = CASE CityName WHEN 'Lisboa' THEN Col1 ELSE @Berlin_Value END,
       @Caracas_Value = CASE CityName WHEN 'Caracas' THEN Col1 ELSE @Berlin_Value END,
       @Paris_Value = CASE CityName WHEN 'Paris' THEN Col1 ELSE @Berlin_Value END
  FROM TabCities
 WHERE TabCities.CityName IN ('Berlin', 'Barcelona', 'London', 'Lisboa', 'Caracas', 'Paris');
 
SELECT TabOrders.*,
       ISNULL(@Berlin_Value, '') + CASE TabOrders.Col1
                                     WHEN 'RD' THEN 'a/'
                                     WHEN 'SD' THEN 'a/'
                                     WHEN 'WD' THEN 'a/'
                                     WHEN 'XD' THEN 'a/'
                                     ELSE ''
                                   END + ISNULL(TabOrders.Col1, '') AS ColBerlin,
       ISNULL(@Barcelona_Value, '') + CASE TabOrders.Col1
                                        WHEN 'RD' THEN 'a/'
                                        WHEN 'SD' THEN 'a/'
                                        WHEN 'WD' THEN 'a/'
                                        WHEN 'XD' THEN 'a/'
                                        ELSE ''
                                      END + ISNULL(TabOrders.Col1, '') AS ColBarcelona,
       ISNULL(@London_Value, '') + CASE TabOrders.Col1
                                     WHEN 'RD' THEN 'a/'
                                     WHEN 'SD' THEN 'a/'
                                     WHEN 'WD' THEN 'a/'
                                     WHEN 'XD' THEN 'a/'
                                     ELSE ''
                                   END + ISNULL(TabOrders.Col1, '') AS ColLondon,
       ISNULL(@Lisboa_Value, '') + CASE TabOrders.Col1
                                     WHEN 'RD' THEN 'a/'
                                     WHEN 'SD' THEN 'a/'
                                     WHEN 'WD' THEN 'a/'
                                     WHEN 'XD' THEN 'a/'
                                     ELSE ''
                                   END + ISNULL(TabOrders.Col1, '') AS ColLisboa,
       ISNULL(@Caracas_Value, '') + CASE TabOrders.Col1
                                      WHEN 'RD' THEN 'a/'
                                      WHEN 'SD' THEN 'a/'
                                      WHEN 'WD' THEN 'a/'
                                      WHEN 'XD' THEN 'a/'
                                      ELSE ''
                                    END + ISNULL(TabOrders.Col1, '') AS ColCaracas,
       ISNULL(@Paris_Value, '') + CASE TabOrders.Col1
                                    WHEN 'RD' THEN 'a/'
                                    WHEN 'SD' THEN 'a/'
                                    WHEN 'WD' THEN 'a/'
                                    WHEN 'XD' THEN 'a/'
                                    ELSE ''
                                  END + ISNULL(TabOrders.Col1, '') AS ColParis
  FROM TabOrders
  JOIN TabCustomers
    ON TabCustomers.CustomerID = TabOrders.CustomerID
 WHERE TabOrders.OrderID BETWEEN 1 AND 110
 ORDER BY TabOrders.Value