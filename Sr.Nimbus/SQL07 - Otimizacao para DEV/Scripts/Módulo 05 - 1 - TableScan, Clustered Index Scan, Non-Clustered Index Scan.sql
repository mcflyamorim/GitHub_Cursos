/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO
/*
  TableScan, Clustered Index Scan, Non-Clustered Index Scan
*/

/*
  TableScan é utilizado para ler os dados de uma Heap
*/

IF EXISTS(SELECT * FROM sysindexes WHERE name ='PK_Order_Details')
  ALTER TABLE Order_Details DROP CONSTRAINT PK_Order_Details
GO

-- Ex: TableScan
SELECT * FROM Order_Details

IF NOT EXISTS(SELECT * FROM sysindexes WHERE name ='PK_Order_Details')
  ALTER TABLE Order_Details ADD CONSTRAINT PK_Order_Details PRIMARY KEY(OrderID, ProductID)
GO

/*
  Clustered Index Scan le os dados no índice cluster.
  
  Ler os dados no índice cluster não significa que os dados
  sempre serão retornados na ordem do índice cluster.
  
  Allocation Order Scan: Lê os dados com base na ordem de 
                         alocação das páginas

  Index Order Scan: Lê os dados com base na ordem do índice
*/

-- Ex: Clustered Index Scan
SELECT * FROM Products

IF EXISTS(SELECT * FROM sysindexes WHERE name ='ix_ProductName')
  DROP INDEX ix_ProductName ON Products
GO
CREATE INDEX ix_ProductName ON Products(ProductName)
GO

-- Ex: Non-Clustered Index Scan
SELECT * FROM Products WITH(INDEX=ix_ProductName)


/*
  Nota: Você realmente conhece todos os efeitos do uso do 
  hint NOLOCK?
  Tem certeza?
  "NOLOCK, Bomba Relógio.sql"
*/


/*
  Exemplo problema com leitura na ordem de alocação das páginas (IAM)
*/
-- Preparando o ambiente
IF OBJECT_ID('Tab1', 'U') IS NOT NULL
  DROP TABLE Tab1;
GO
CREATE TABLE Tab1(Col1 VarChar(250) NOT NULL DEFAULT(NEWID()) PRIMARY KEY,
                  Col2 Char(2000) NOT NULL DEFAULT('Teste'));
GO

-- Deixar rodando esta consulta na Conexão 1
TRUNCATE TABLE Tab1
GO
WHILE 1=1
  INSERT INTO Tab1 DEFAULT VALUES
GO


-- Opcional: Consulta Fragmentação da tabela
SELECT avg_fragmentation_in_percent 
  FROM sys.dm_db_index_physical_stats (DB_ID('NorthWind'),OBJECT_ID('Tab1'),1,NULL,NULL);
GO

-- Conexão 2
IF OBJECT_ID('tempdb.dbo.#Tab1', 'U') IS NOT NULL
  DROP TABLE #Tab1;
GO
SET NOCOUNT ON;
WHILE 1 = 1
BEGIN
  -- Joga os dados da tabela Tab1 em uma tabela temporária
  -- Atenção no uso do NOLOCK para forçar a leitura por ordem de alocação
  SELECT * 
    INTO #Tab1 
    FROM Tab1 WITH(NOLOCK)

  -- Agrupa os dados por Col1 (Coluna com NEWID() como Default)
  -- Se existir mais que uma linha para um único valor
  -- significa que os dados foram lidos mais de uma vez
  IF EXISTS(SELECT Col1
              FROM #Tab1 
             GROUP BY Col1 
            HAVING COUNT(*) > 1)
  BEGIN     
    BREAK
  END
  DROP TABLE #Tab1
END
-- Consulta os registros lidos em duplicidade
SELECT Col1, COUNT(*) AS cnt
  FROM #Tab1 
 GROUP BY Col1
HAVING COUNT(*) > 1;
GO

-- Procura o registro na tabela original
SELECT * 
  FROM Tab1
 WHERE Col1 = '81416138-CC2E-401D-982E-35F869CD9564'

-- Procura o registro na tabela temporária
SELECT * 
  FROM #Tab1
 WHERE Col1 = '81416138-CC2E-401D-982E-35F869CD9564'


/*
  Exemplo problema com leitura na ordem do índice
*/

-- Conexão 1
SET NOCOUNT ON
IF OBJECT_ID('Funcionarios') IS NOT NULL
  DROP TABLE Funcionarios
GO
CREATE TABLE Funcionarios(ID      Int IDENTITY(1,1) PRIMARY KEY,
                          ContactName    Char(7000),
                          Salario Numeric(18,2));
GO
-- Inserir 4 registros para alocar 4 páginas
INSERT INTO Funcionarios(ContactName, Salario)
VALUES('Fabiano', 1000),('Felipe',2000),('Nilton', 3000),('Diego', 4000)
GO
CREATE NONCLUSTERED INDEX ix_Salario ON Funcionarios(Salario) INCLUDE(ContactName)
GO

/*
  Fica mudando a página do Fabiano para primeira página e última
  
  Na primeira execução do update o Fabiano vai da primeira página 
  para a última. 
  Ele ganha 1000, ou seja, 6000 - 1000 = 5000,
  No update o SQL precisa manter o índice ix_Salario atualizado
  na ordem correta, ou seja, o Fabiano vai para o final (maior salário)
  
  Na segunda execução do update o Fabiano vai da última página
  para a primeira
  Ele ganha 5000, ou seja, 6000 - 5000 = 1000
  No update o SQL precisa manter o índice ix_Salario atualizado
  na ordem correta, ou seja, o Fabiano vai para o começo (menor salário)
  
  Nota: executar o update duas vezes, e mostrar os valores mudando
*/
-- Deixar rodando o update na Conexão 1
WHILE 1 = 1
  UPDATE Funcionarios
     SET Salario = 6000 - Salario
   WHERE ContactName = 'Fabiano';

-- Conexão 2:
SET NOCOUNT ON;
-- Pular linha
WHILE 1 = 1
BEGIN
  IF OBJECT_ID('tempdb.dbo.#TMPFuncionarios', 'U') IS NOT NULL
    DROP TABLE #TMPFuncionarios;

  SELECT * 
    INTO #TMPFuncionarios 
    FROM Funcionarios WITH(index=ix_Salario)
  IF @@ROWCOUNT < 4
    BREAK
END
SELECT * FROM #TMPFuncionarios
GO
-- Ler linha em duplicidade
WHILE 1 = 1
BEGIN
  IF OBJECT_ID('tempdb.dbo.#TMPFuncionarios', 'U') IS NOT NULL
    DROP TABLE #TMPFuncionarios;

  SELECT * 
    INTO #TMPFuncionarios 
    FROM Funcionarios WITH(index=ix_Salario)
  IF @@ROWCOUNT > 4
    BREAK
END
SELECT * FROM #TMPFuncionarios