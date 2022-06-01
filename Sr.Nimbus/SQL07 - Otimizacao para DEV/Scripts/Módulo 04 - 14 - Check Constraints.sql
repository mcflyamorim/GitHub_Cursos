/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

/*
  Check Constraints
*/

-- Preparando o ambiente
IF OBJECT_ID('Tab1_Test_CheckConstraints') IS NOT NULL
  DROP TABLE Tab1_Test_CheckConstraints
GO
CREATE TABLE Tab1_Test_CheckConstraints(Col1   Integer NOT NULL PRIMARY KEY,
                                        Status Char(1))
GO
ALTER TABLE Tab1_Test_CheckConstraints ADD CONSTRAINT ck CHECK(Status = 'S' OR Status = 'N')
GO

SELECT *
  FROM Tab1_Test_CheckConstraints
 WHERE Status = 'X'
OPTION(RECOMPILE)