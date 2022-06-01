DECLARE @Str VarChar(200), 
        @Caracter_A_Procurar VarChar(200), 
        @i Int, 
        @Qtde_Caracter Int; 

SET @Str = 'Um teste para validar quantos caracteres existem nesta String' 
SET @Caracter_A_Procurar = 'a' 
SET @i = 0 
SET @Qtde_Caracter = 0 

WHILE @i <= LEN(@Str) 
BEGIN 
    IF SUBSTRING(@Str, @i, 1) = @Caracter_A_Procurar 
        SET @Qtde_Caracter = @Qtde_Caracter + 1 
    SET @i = @i + 1 
END 
SELECT @Qtde_Caracter 
GO


DECLARE @Str VarChar(200), 
        @Caracter_A_Procurar VarChar(200) 

SET @Str = 'Um teste para validar quantos caracteres existem nesta String' 
SET @Caracter_A_Procurar = 'a' 

SELECT LEN(@Str) - LEN(REPLACE(@Str, @Caracter_A_Procurar, ''))
GO
