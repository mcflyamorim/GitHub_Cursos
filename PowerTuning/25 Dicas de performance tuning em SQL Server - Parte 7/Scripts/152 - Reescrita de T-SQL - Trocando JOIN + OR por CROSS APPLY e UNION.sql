/*
  RESTORE DATABASE [Dica152] FROM  DISK = N'D:\Fabiano\Trabalho\FabricioLima\Cursos\25 Dicas de performance tuning em SQL Server - Parte 7\Scripts\Dica152.bak' 
  WITH  FILE = 1,  NOUNLOAD,  STATS = 5
*/
USE Dica152
GO

-- Utilizar COMPATIBILITY_LEVEL = SQL2019
ALTER DATABASE [Dica152] SET COMPATIBILITY_LEVEL = 150
GO

SET STATISTICS IO ON
-- Fazendo scan pra acessar a tabela t_order...
-- Or acabando com o plano... :-( ... 
SELECT ord.host_order_detail_id, ord.wh_id, ISNULL(ord.item_number, itm.item_number) AS item_number
  FROM t_al_host_order_detail ord
 INNER JOIN t_order orm
    ON orm.wh_id = ord.wh_id
   AND (ord.order_number = orm.order_number OR ord.display_order_number = orm.display_order_number)
  LEFT OUTER JOIN t_item_master itm
    ON ord.display_item_number = itm.display_item_number
   AND ord.wh_id = itm.wh_id
   AND ISNULL(ord.client_code, ord.wh_id) = itm.client_code
   AND itm.attribute_collection_id IS NOT NULL
 WHERE ord.host_group_id = 'CLARIFY2-2541928'
 ORDER BY ord.host_order_detail_id ASC
OPTION (RECOMPILE, MAXDOP 1); 
GO

-- O que o usuário quer é, 
-- orm.wh_id = ord.wh_id AND ord.order_number = orm.order_number
-- Ou
-- orm.wh_id = ord.wh_id AND ord.display_order_number = orm.display_order_number

-- Faz seek no índice por wh_id e order_number
SELECT * FROM t_order ord
 WHERE ord.wh_id = 'COLDC11'
   AND ord.order_number = 'LSI|U013672347'
GO
-- Faz seek no índice por display_order_number
SELECT * FROM t_order ord
 WHERE ord.wh_id = 'COLDC11'
   AND ord.display_order_number = 'U013672347' 
GO

-- Ou seja, já existem índices cobrindo o join... Por que não usa-los?
-- Eu estava esperando um "index intersection aqui..."
SELECT ord.host_order_detail_id, ord.wh_id, ISNULL(ord.item_number, itm.item_number) AS item_number
  FROM t_al_host_order_detail ord
 INNER JOIN t_order orm
    ON orm.wh_id = ord.wh_id
   AND (ord.order_number = orm.order_number OR ord.display_order_number = orm.display_order_number)
  LEFT OUTER JOIN t_item_master itm
    ON ord.display_item_number = itm.display_item_number
   AND ord.wh_id = itm.wh_id
   AND ISNULL(ord.client_code, ord.wh_id) = itm.client_code
   AND itm.attribute_collection_id IS NOT NULL
 WHERE ord.host_group_id = 'CLARIFY2-2541928'
 ORDER BY ord.host_order_detail_id ASC
OPTION (RECOMPILE, MAXDOP 1); 
GO

-- E se eu reescrever a query pra fazer um UNION?
SELECT ord.host_order_detail_id, ord.wh_id, ISNULL(ord.item_number, itm.item_number) AS item_number
  FROM t_al_host_order_detail ord
 CROSS APPLY (SELECT a.wh_id FROM t_order a
               WHERE a.wh_id = ord.wh_id
                 AND ord.order_number = a.order_number
               UNION 
              SELECT b.wh_id FROM t_order b
               WHERE b.wh_id = ord.wh_id
                 AND ord.display_order_number = b.display_order_number) AS orm  
  LEFT OUTER JOIN t_item_master itm
    ON ord.display_item_number = itm.display_item_number
   AND ord.wh_id = itm.wh_id
   AND ISNULL(ord.client_code, ord.wh_id) = itm.client_code
   AND itm.attribute_collection_id IS NOT NULL
 WHERE ord.host_group_id = 'CLARIFY2-2541928'
 ORDER BY ord.host_order_detail_id ASC
OPTION (RECOMPILE, MAXDOP 1); 
GO


-- Forceseek também resolve...
SELECT ord.host_order_detail_id, ord.wh_id, ISNULL(ord.item_number, itm.item_number) AS item_number
  FROM t_al_host_order_detail ord
 INNER JOIN t_order orm WITH(FORCESEEK)
    ON orm.wh_id = ord.wh_id
   AND (ord.order_number = orm.order_number OR ord.display_order_number = orm.display_order_number)
  LEFT OUTER JOIN t_item_master itm
    ON ord.display_item_number = itm.display_item_number
   AND ord.wh_id = itm.wh_id
   AND ISNULL(ord.client_code, ord.wh_id) = itm.client_code
   AND itm.attribute_collection_id IS NOT NULL
 WHERE ord.host_group_id = 'CLARIFY2-2541928'
 ORDER BY ord.host_order_detail_id ASC
OPTION (RECOMPILE, MAXDOP 1); 
GO
