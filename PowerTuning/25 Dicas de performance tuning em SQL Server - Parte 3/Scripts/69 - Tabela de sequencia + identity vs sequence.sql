USE Northwind
GO

-- Criando tabela com Identity...
IF OBJECT_ID('TabSequences') IS NOT NULL 
  DROP TABLE TabSequences
GO
CREATE TABLE TabSequences
             (SeqID bigint identity(1,1) primary KEY, SeqVal CHAR(1))
GO

-- Proc para gerar a sequencia...
-- Roda insert e depois apaga o valor...
IF OBJECT_ID('GetNewSeqVal_TabSequences') IS NOT NULL
  DROP PROC GetNewSeqVal_TabSequences
GO
CREATE PROCEDURE GetNewSeqVal_TabSequences
AS
BEGIN
  DECLARE @NewSeqValue int
  SET NOCOUNT ON
  INSERT INTO TabSequences (SeqVal) VALUES ('a')
     
  SET @NewSeqValue = SCOPE_IDENTITY()
     
  DELETE FROM TabSequences WITH (READPAST)
  RETURN @NewSeqValue
END
GO

-- Pegando um valor...
DECLARE @NewSeqVal INT
EXEC @NewSeqVal = GetNewSeqVal_TabSequences
SELECT @NewSeqVal
GO

-- Como que fica com concorrência? ... 

-- SQL Query Stress --
-- 17 segundos...

-- Waits comuns...
-- LATCH_EX [ACCESS_METHODS_HOBT_VIRTUAL_ROOT]
-- PAGELATCH_EX:Northwind:1(*)


-- E com sequence? 

IF OBJECT_ID('Seq_Sequence1') IS NOT NULL
  DROP SEQUENCE Seq_Sequence1
GO
CREATE SEQUENCE Seq_Sequence1
 START WITH 1
 INCREMENT BY 1
GO

-- Alterando a SP...
ALTER PROCEDURE GetNewSeqVal_TabSequences
AS
BEGIN
  DECLARE @SequenceID AS INT = NEXT VALUE FOR Seq_Sequence1;
  RETURN @SequenceID;
END
GO

-- Pegando um valor...
DECLARE @NewSeqVal INT
EXEC @NewSeqVal = GetNewSeqVal_TabSequences
SELECT @NewSeqVal
GO


-- E agora, como que fica a concorrência? ... 

-- SQL Query Stress --
