USE tempdb
GO
IF OBJECT_ID('Pedido') IS NOT NULL
  DROP TABLE Pedido
GO
CREATE TABLE Pedido (ID INT IDENTITY(1,1),
        Cliente INT NOT NULL,
        Vendedor VARCHAR(30) NOT NULL,
        Quantidade SmallInt NOT NULL,
        Valor Numeric(18,2) NOT NULL,
        Data DATETIME NOT NULL)
GO
CREATE CLUSTERED INDEX ix ON Pedido(ID)
GO

SET IDENTITY_INSERT Pedido ON
INSERT INTO Pedido(ID, Cliente, Vendedor, Quantidade, Valor, Data)
  SELECT 1,
      ABS(CheckSUM(NEWID()) / 100000000),
  'Fabiano',
      ABS(CheckSUM(NEWID()) / 10000000),
      ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
  '19831203'
INSERT INTO Pedido(ID, Cliente, Vendedor, Quantidade, Valor, Data)
  SELECT 2,
      ABS(CheckSUM(NEWID()) / 100000000),
  'Fabiano',
      ABS(CheckSUM(NEWID()) / 10000000),
      ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
  '19831203'
INSERT INTO Pedido(ID, Cliente, Vendedor, Quantidade, Valor, Data)
  SELECT 3,
      ABS(CheckSUM(NEWID()) / 100000000),
  'Fabiano',
      ABS(CheckSUM(NEWID()) / 10000000),
      ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
  '20100622'
INSERT INTO Pedido(ID, Cliente, Vendedor, Quantidade, Valor, Data)
  SELECT 4,
      ABS(CheckSUM(NEWID()) / 100000000),
  'Fabiano',
      ABS(CheckSUM(NEWID()) / 10000000),
      ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
  '19831203'
  SET IDENTITY_INSERT Pedido OFF
GO

-- Visualizando os dados
SELECT * FROM Pedido
GO

SELECT *
  FROM Pedido Ped1
  WHERE Ped1.Valor > (
  SELECT AVG(Ped2.Valor)
    FROM Pedido AS Ped2
    WHERE Ped2.Data < Ped1.Data)
OPTION(USE PLAN N'
<ShowPlanXML xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" Version="1.1" Build="10.50.6220.0" xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementCompId="1" StatementEstRows="180" StatementId="1" StatementOptmLevel="FULL" StatementOptmEarlyAbortReason="GoodEnoughPlanFound" StatementSubTreeCost="0.291272" StatementText="&#xD;&#xA;SELECT *&#xD;&#xA;  FROM Pedido Ped1&#xD;&#xA;  WHERE Ped1.Valor &gt; (&#xD;&#xA;  SELECT AVG(Ped2.Valor)&#xD;&#xA;    FROM Pedido AS Ped2&#xD;&#xA;    WHERE Ped2.Data &lt; Ped1.Data)" StatementType="SELECT" QueryHash="0x25DA08EB1AF69674" QueryPlanHash="0xC4269A8110ED33CE">
          <StatementSetOptions ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" NUMERIC_ROUNDABORT="false" QUOTED_IDENTIFIER="true" />
          <QueryPlan CachedPlanSize="32" CompileTime="1" CompileCPU="1" CompileMemory="320">
            <RelOp AvgRowSize="53" EstimateCPU="0.000288" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="180" LogicalOp="Filter" NodeId="0" Parallel="false" PhysicalOp="Filter" EstimatedTotalSubtreeCost="0.291272">
              <OutputList>
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="ID" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Cliente" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Vendedor" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Quantidade" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Valor" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
              </OutputList>
              <Filter StartupExpression="false">
                <RelOp AvgRowSize="70" EstimateCPU="0.002508" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="600" LogicalOp="Inner Join" NodeId="1" Parallel="false" PhysicalOp="Nested Loops" EstimatedTotalSubtreeCost="0.290984">
                  <OutputList>
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="ID" />
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Cliente" />
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Vendedor" />
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Quantidade" />
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Valor" />
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                    <ColumnReference Column="Expr1006" />
                  </OutputList>
                  <NestedLoops Optimized="false">
                    <OuterReferences>
                      <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                    </OuterReferences>
                    <RelOp AvgRowSize="53" EstimateCPU="0.000817" EstimateIO="0.00534722" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="600" LogicalOp="Clustered Index Scan" NodeId="2" Parallel="false" PhysicalOp="Clustered Index Scan" EstimatedTotalSubtreeCost="0.00616422" TableCardinality="600">
                      <OutputList>
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="ID" />
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Cliente" />
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Vendedor" />
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Quantidade" />
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Valor" />
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                      </OutputList>
                      <IndexScan Ordered="false" ForcedIndex="false" ForceScan="false" NoExpandHint="false">
                        <DefinedValues>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="ID" />
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Cliente" />
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Vendedor" />
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Quantidade" />
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Valor" />
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                          </DefinedValue>
                        </DefinedValues>
                        <Object Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Index="[ix]" Alias="[Ped1]" IndexKind="Clustered" />
                      </IndexScan>
                    </RelOp>
                    <RelOp AvgRowSize="24" EstimateCPU="0.00025835" EstimateIO="0.003125" EstimateRebinds="595.947" EstimateRewinds="3.05333" EstimateRows="1" LogicalOp="Lazy Spool" NodeId="3" Parallel="false" PhysicalOp="Index Spool" EstimatedTotalSubtreeCost="0.282312">
                      <OutputList>
                        <ColumnReference Column="Expr1006" />
                      </OutputList>
                      <Spool>
                        <SeekPredicateNew>
                          <SeekKeys>
                            <Prefix ScanType="EQ">
                              <RangeColumns>
                                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                              </RangeColumns>
                              <RangeExpressions>
                                <ScalarOperator ScalarString="[tempdb].[dbo].[Pedido].[Data] as [Ped1].[Data]">
                                  <Identifier>
                                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                                  </Identifier>
                                </ScalarOperator>
                              </RangeExpressions>
                            </Prefix>
                          </SeekKeys>
                        </SeekPredicateNew>
                        <RelOp AvgRowSize="24" EstimateCPU="0.0001085" EstimateIO="0" EstimateRebinds="149" EstimateRewinds="0" EstimateRows="1" LogicalOp="Compute Scalar" NodeId="4" Parallel="false" PhysicalOp="Compute Scalar" EstimatedTotalSubtreeCost="0.124178">
                          <OutputList>
                            <ColumnReference Column="Expr1006" />
                          </OutputList>
                          <ComputeScalar>
                            <DefinedValues>
                              <DefinedValue>
                                <ColumnReference Column="Expr1006" />
                                <ScalarOperator ScalarString="CASE WHEN [Expr1013]=(0) THEN NULL ELSE [Expr1014]/CONVERT_IMPLICIT(numeric(19,0),[Expr1013],0) END">
                                  <IF>
                                    <Condition>
                                      <ScalarOperator>
                                        <Compare CompareOp="EQ">
                                          <ScalarOperator>
                                            <Identifier>
                                              <ColumnReference Column="Expr1013" />
                                            </Identifier>
                                          </ScalarOperator>
                                          <ScalarOperator>
                                            <Const ConstValue="(0)" />
                                          </ScalarOperator>
                                        </Compare>
                                      </ScalarOperator>
                                    </Condition>
                                    <Then>
                                      <ScalarOperator>
                                        <Const ConstValue="NULL" />
                                      </ScalarOperator>
                                    </Then>
                                    <Else>
                                      <ScalarOperator>
                                        <Arithmetic Operation="DIV">
                                          <ScalarOperator>
                                            <Identifier>
                                              <ColumnReference Column="Expr1014" />
                                            </Identifier>
                                          </ScalarOperator>
                                          <ScalarOperator>
                                            <Convert DataType="numeric" Precision="19" Scale="0" Style="0" Implicit="true">
                                              <ScalarOperator>
                                                <Identifier>
                                                  <ColumnReference Column="Expr1013" />
                                                </Identifier>
                                              </ScalarOperator>
                                            </Convert>
                                          </ScalarOperator>
                                        </Arithmetic>
                                      </ScalarOperator>
                                    </Else>
                                  </IF>
                                </ScalarOperator>
                              </DefinedValue>
                            </DefinedValues>
                            <RelOp AvgRowSize="24" EstimateCPU="0.0001085" EstimateIO="0" EstimateRebinds="149" EstimateRewinds="0" EstimateRows="1" LogicalOp="Aggregate" NodeId="5" Parallel="false" PhysicalOp="Stream Aggregate" EstimatedTotalSubtreeCost="0.124178">
                              <OutputList>
                                <ColumnReference Column="Expr1013" />
                                <ColumnReference Column="Expr1014" />
                              </OutputList>
                              <StreamAggregate>
                                <DefinedValues>
                                  <DefinedValue>
                                    <ColumnReference Column="Expr1013" />
                                    <ScalarOperator ScalarString="Count(*)">
                                      <Aggregate AggType="countstar" Distinct="false" />
                                    </ScalarOperator>
                                  </DefinedValue>
                                  <DefinedValue>
                                    <ColumnReference Column="Expr1014" />
                                    <ScalarOperator ScalarString="SUM([tempdb].[dbo].[Pedido].[Valor] as [Ped2].[Valor])">
                                      <Aggregate AggType="SUM" Distinct="false">
                                        <ScalarOperator>
                                          <Identifier>
                                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Valor" />
                                          </Identifier>
                                        </ScalarOperator>
                                      </Aggregate>
                                    </ScalarOperator>
                                  </DefinedValue>
                                </DefinedValues>
                                <RelOp AvgRowSize="16" EstimateCPU="0.001055" EstimateIO="0.0266385" EstimateRebinds="149" EstimateRewinds="0" EstimateRows="180" LogicalOp="Eager Spool" NodeId="6" Parallel="false" PhysicalOp="Index Spool" EstimatedTotalSubtreeCost="0.107903">
                                  <OutputList>
                                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Valor" />
                                  </OutputList>
                                  <Spool>
                                    <SeekPredicateNew>
                                      <SeekKeys>
                                        <EndRange ScanType="LT">
                                          <RangeColumns>
                                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Data" />
                                          </RangeColumns>
                                          <RangeExpressions>
                                            <ScalarOperator ScalarString="[tempdb].[dbo].[Pedido].[Data] as [Ped1].[Data]">
                                              <Identifier>
                                                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Data" />
                                              </Identifier>
                                            </ScalarOperator>
                                          </RangeExpressions>
                                        </EndRange>
                                      </SeekKeys>
                                    </SeekPredicateNew>
                                    <RelOp AvgRowSize="24" EstimateCPU="0.000817" EstimateIO="0.00534722" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="600" LogicalOp="Clustered Index Scan" NodeId="7" Parallel="false" PhysicalOp="Clustered Index Scan" EstimatedTotalSubtreeCost="0.00616422" TableCardinality="600">
                                      <OutputList>
                                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Valor" />
                                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Data" />
                                      </OutputList>
                                      <IndexScan Ordered="false" ForcedIndex="false" ForceScan="false" NoExpandHint="false">
                                        <DefinedValues>
                                          <DefinedValue>
                                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Valor" />
                                          </DefinedValue>
                                          <DefinedValue>
                                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped2]" Column="Data" />
                                          </DefinedValue>
                                        </DefinedValues>
                                        <Object Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Index="[ix]" Alias="[Ped2]" IndexKind="Clustered" />
                                      </IndexScan>
                                    </RelOp>
                                  </Spool>
                                </RelOp>
                              </StreamAggregate>
                            </RelOp>
                          </ComputeScalar>
                        </RelOp>
                      </Spool>
                    </RelOp>
                  </NestedLoops>
                </RelOp>
                <Predicate>
                  <ScalarOperator ScalarString="[tempdb].[dbo].[Pedido].[Valor] as [Ped1].[Valor]&gt;[Expr1006]">
                    <Compare CompareOp="GT">
                      <ScalarOperator>
                        <Identifier>
                          <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[Pedido]" Alias="[Ped1]" Column="Valor" />
                        </Identifier>
                      </ScalarOperator>
                      <ScalarOperator>
                        <Identifier>
                          <ColumnReference Column="Expr1006" />
                        </Identifier>
                      </ScalarOperator>
                    </Compare>
                  </ScalarOperator>
                </Predicate>
              </Filter>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>
'
) 