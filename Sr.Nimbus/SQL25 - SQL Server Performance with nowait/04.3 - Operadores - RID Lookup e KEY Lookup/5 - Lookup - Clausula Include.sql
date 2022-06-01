/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

-- Covered indexes
-- Para mais detalhes em relação a este assunto veja os treinamentos de indexação

-- Mesmo que um índice por CompanyName exista o SQL não vai usar por causa da seletividade
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName LIKE 'Centro%'
GO

/*
  A partir do SQL Server 2005 podemos utilizar a clausula INCLUDE 
  para evitar o lookup
*/

CREATE INDEX ix_CompanyName_Col1_Col2 ON CustomersBig(CompanyName) INCLUDE(Col1, Col2)
GO

-- Com o índice coberto o SQL Faz o Seek + um Range Scan
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName LIKE 'Centro%'