
-- Ver no profiler

-- EncryptByPassPhrase faz que o TSQL não fique disponível...
SELECT 'Teste Código que ninguem pode ver pelo Profiler' 
WHERE EncryptByPassPhrase('','') <> ''
GO

 