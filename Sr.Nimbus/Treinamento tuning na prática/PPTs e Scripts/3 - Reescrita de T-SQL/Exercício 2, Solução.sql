
-- Solução

CREATE INDEX ix1 ON OrdersBig (Value) INCLUDE(OrderID, CustomerID, OrderDate)
GO


DECLARE @TabStatus_A_VALUE VARCHAR(4000),
        @TabStatus_B_VALUE VARCHAR(4000),
        @TabStatus_C_VALUE VARCHAR(4000),
        @TabStatus_D_VALUE VARCHAR(4000), 
        @TabStatus_E_VALUE VARCHAR(4000),
        @TabStatus_F_VALUE VARCHAR(4000),
        @TabStatus_G_VALUE VARCHAR(4000);

SELECT @TabStatus_A_VALUE = CASE ColStatus
                                      WHEN 'A' THEN Val
                                      ELSE @TabStatus_A_VALUE
                                 END,
       @TabStatus_B_VALUE = CASE ColStatus
                                     WHEN 'B' THEN Val
                                     ELSE @TabStatus_B_VALUE
                                END,
       @TabStatus_C_VALUE = CASE ColStatus
                                       WHEN 'C' THEN Val
                                       ELSE @TabStatus_C_VALUE
                                  END,
       @TabStatus_D_VALUE = CASE ColStatus
                                       WHEN 'D' THEN Val
                                       ELSE @TabStatus_D_VALUE
                                  END,
       @TabStatus_F_VALUE = CASE ColStatus
                                       WHEN 'F' THEN Val
                                       ELSE @TabStatus_F_VALUE
                                  END,
       @TabStatus_G_VALUE = CASE ColStatus
                                       WHEN 'G' THEN Val
                                       ELSE @TabStatus_G_VALUE
                                  END
FROM TabStatus
WHERE ColStatus IN ( 'A', 'B', 'C', 'D', 'E', 'F', 'G');

SELECT 
   OrdersBig.OrderID, 
   OrdersBig.CustomerID, 
   OrdersBig.Value, 
   OrdersBig.OrderDate, 
   ISNULL(
      (
         @TabStatus_A_VALUE
      ), '') + case CustomersBig.Col1  when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
         @TabStatus_B_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/'
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'   
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
         @TabStatus_C_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
        @TabStatus_D_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
       @TabStatus_E_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
        @TabStatus_F_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
        @TabStatus_G_VALUE
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, '')

FROM CustomersBig
join OrdersBig ON OrdersBig.CustomerID = CustomersBig.CustomerID
WHERE OrdersBig.Value BETWEEN 1 AND 1.3
OPTION (recompile)
GO