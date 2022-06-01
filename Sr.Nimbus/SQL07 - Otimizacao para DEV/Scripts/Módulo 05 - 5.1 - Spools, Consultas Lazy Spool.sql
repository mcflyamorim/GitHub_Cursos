/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

-- Mudar o Value de registros da tabela e 
-- comparar os tempos de execução das consultas
IF OBJECT_ID('Orders_LazySpool') IS NOT NULL
  DROP TABLE Orders_LazySpool
GO
CREATE TABLE Orders_LazySpool (ID         Integer IDENTITY(1,1) PRIMARY KEY,
                     Cliente    Integer NOT NULL,
                     Vendedor   VarChar(30) NOT NULL,
                     Quantidade SmallInt NOT NULL,
                     Value      Numeric(18,2) NOT NULL,
                     Data       DateTime NOT NULL)
GO
DECLARE @i SmallInt
  SET @i = 0
WHILE @i < 50
BEGIN
  INSERT INTO Orders_LazySpool(Cliente, Vendedor, Quantidade, Value, Data)
  VALUES(ABS(CheckSUM(NEWID()) / 100000000),
         'Fabiano',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Neves',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Amorim',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000))
  SET @i = @i + 1
END
GO

-- Lazy Spool
SELECT Ped1.Cliente, Ped1.Value
  FROM Orders_LazySpool Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Cliente = Ped1.Cliente)
OPTION(USE PLAN N'<ShowPlanXML xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" Version="1.1" Build="10.50.1746.0" xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementCompId="1" StatementEstRows="45" StatementId="1" StatementOptmLevel="FULL" StatementOptmEarlyAbortReason="GoodEnoughPlanFound" StatementSubTreeCost="0.0182132" StatementText="SELECT Ped1.Cliente, Ped1.Value&#xD;&#xA;  FROM Orders_LazySpool Ped1&#xD;&#xA; WHERE Ped1.Value &lt; (SELECT AVG(Ped2.Value)&#xD;&#xA;                       FROM Orders_LazySpool Ped2&#xD;&#xA;                      WHERE Ped2.Cliente = Ped1.Cliente)&#xD;&#xA;OPTION (MAXDOP 1, RECOMPILE)" StatementType="SELECT" QueryHash="0x54CD13ECA0AC1B54" QueryPlanHash="0x25045D163BCCA044">
          <StatementSetOptions ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" NUMERIC_ROUNDABORT="false" QUOTED_IDENTIFIER="true" />
          <QueryPlan CachedPlanSize="16" CompileTime="17" CompileCPU="11" CompileMemory="224">
            <RelOp AvgRowSize="20" EstimateCPU="0.0013193" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="45" LogicalOp="Inner Join" NodeId="1" Parallel="false" PhysicalOp="Nested Loops" EstimatedTotalSubtreeCost="0.0182132">
              <OutputList>
                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
              </OutputList>
              <NestedLoops Optimized="false">
                <RelOp AvgRowSize="20" EstimateCPU="0" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="22" LogicalOp="Lazy Spool" NodeId="2" Parallel="false" PhysicalOp="Table Spool" EstimatedTotalSubtreeCost="0.0168425">
                  <OutputList>
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                  </OutputList>
                  <Spool>
                    <RelOp AvgRowSize="20" EstimateCPU="0.000171338" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="150" LogicalOp="Segment" NodeId="3" Parallel="false" PhysicalOp="Segment" EstimatedTotalSubtreeCost="0.0166712">
                      <OutputList>
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                        <ColumnReference Column="Segment1010" />
                      </OutputList>
                      <Segment>
                        <GroupBy>
                          <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                        </GroupBy>
                        <SegmentColumn>
                          <ColumnReference Column="Segment1010" />
                        </SegmentColumn>
                        <RelOp AvgRowSize="20" EstimateCPU="0.00179156" EstimateIO="0.0112613" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="150" LogicalOp="Sort" NodeId="4" Parallel="false" PhysicalOp="Sort" EstimatedTotalSubtreeCost="0.0164998">
                          <OutputList>
                            <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                            <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                          </OutputList>
                          <MemoryFractions Input="1" Output="1" />
                          <Sort Distinct="false">
                            <OrderBy>
                              <OrderByColumn Ascending="true">
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                              </OrderByColumn>
                            </OrderBy>
                            <RelOp AvgRowSize="20" EstimateCPU="0.000322" EstimateIO="0.003125" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="150" LogicalOp="Clustered Index Scan" NodeId="5" Parallel="false" PhysicalOp="Clustered Index Scan" EstimatedTotalSubtreeCost="0.003447" TableCardinality="150">
                              <OutputList>
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                              </OutputList>
                              <IndexScan Ordered="false" ForcedIndex="false" NoExpandHint="false">
                                <DefinedValues>
                                  <DefinedValue>
                                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                                  </DefinedValue>
                                  <DefinedValue>
                                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                                  </DefinedValue>
                                </DefinedValues>
                                <Object Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Index="[PK__Orders___3214EC27640DD89F]" Alias="[Ped1]" TableReferenceId="-1" IndexKind="Clustered" />
                              </IndexScan>
                            </RelOp>
                          </Sort>
                        </RelOp>
                      </Segment>
                    </RelOp>
                  </Spool>
                </RelOp>
                <RelOp AvgRowSize="20" EstimateCPU="1.71338E-05" EstimateIO="0" EstimateRebinds="22" EstimateRewinds="0" EstimateRows="6.81818" LogicalOp="Inner Join" NodeId="6" Parallel="false" PhysicalOp="Nested Loops" EstimatedTotalSubtreeCost="3.42676E-05">
                  <OutputList>
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                  </OutputList>
                  <NestedLoops Optimized="false">
                    <Predicate>
                      <ScalarOperator ScalarString="[NorthWind].[dbo].[Orders_LazySpool].[Value] as [Ped1].[Value]&lt;[Expr1004]">
                        <Compare CompareOp="LT">
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                            </Identifier>
                          </ScalarOperator>
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Column="Expr1004" />
                            </Identifier>
                          </ScalarOperator>
                        </Compare>
                      </ScalarOperator>
                    </Predicate>
                    <RelOp AvgRowSize="20" EstimateCPU="1.71338E-06" EstimateIO="0" EstimateRebinds="22" EstimateRewinds="0" EstimateRows="1" LogicalOp="Compute Scalar" NodeId="7" Parallel="false" PhysicalOp="Compute Scalar" EstimatedTotalSubtreeCost="1.88472E-05">
                      <OutputList>
                        <ColumnReference Column="Expr1004" />
                      </OutputList>
                      <ComputeScalar>
                        <DefinedValues>
                          <DefinedValue>
                            <ColumnReference Column="Expr1004" />
                            <ScalarOperator ScalarString="CASE WHEN [Expr1011]=(0) THEN NULL ELSE [Expr1012]/CONVERT_IMPLICIT(numeric(19,0),[Expr1011],0) END">
                              <IF>
                                <Condition>
                                  <ScalarOperator>
                                    <Compare CompareOp="EQ">
                                      <ScalarOperator>
                                        <Identifier>
                                          <ColumnReference Column="Expr1011" />
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
                                          <ColumnReference Column="Expr1012" />
                                        </Identifier>
                                      </ScalarOperator>
                                      <ScalarOperator>
                                        <Convert DataType="numeric" Precision="19" Scale="0" Style="0" Implicit="true">
                                          <ScalarOperator>
                                            <Identifier>
                                              <ColumnReference Column="Expr1011" />
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
                        <RelOp AvgRowSize="20" EstimateCPU="1.71338E-05" EstimateIO="0" EstimateRebinds="22" EstimateRewinds="0" EstimateRows="1" LogicalOp="Aggregate" NodeId="8" Parallel="false" PhysicalOp="Stream Aggregate" EstimatedTotalSubtreeCost="1.71338E-05">
                          <OutputList>
                            <ColumnReference Column="Expr1011" />
                            <ColumnReference Column="Expr1012" />
                          </OutputList>
                          <StreamAggregate>
                            <DefinedValues>
                              <DefinedValue>
                                <ColumnReference Column="Expr1011" />
                                <ScalarOperator ScalarString="Count(*)">
                                  <Aggregate AggType="countstar" Distinct="false" />
                                </ScalarOperator>
                              </DefinedValue>
                              <DefinedValue>
                                <ColumnReference Column="Expr1012" />
                                <ScalarOperator ScalarString="SUM([NorthWind].[dbo].[Orders_LazySpool].[Value] as [Ped1].[Value])">
                                  <Aggregate AggType="SUM" Distinct="false">
                                    <ScalarOperator>
                                      <Identifier>
                                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                                      </Identifier>
                                    </ScalarOperator>
                                  </Aggregate>
                                </ScalarOperator>
                              </DefinedValue>
                            </DefinedValues>
                            <RelOp AvgRowSize="20" EstimateCPU="0" EstimateIO="0" EstimateRebinds="22" EstimateRewinds="0" EstimateRows="6.81818" LogicalOp="Lazy Spool" NodeId="9" Parallel="false" PhysicalOp="Table Spool" EstimatedTotalSubtreeCost="0">
                              <OutputList>
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                              </OutputList>
                              <Spool PrimaryNodeId="2" />
                            </RelOp>
                          </StreamAggregate>
                        </RelOp>
                      </ComputeScalar>
                    </RelOp>
                    <RelOp AvgRowSize="20" EstimateCPU="0" EstimateIO="0" EstimateRebinds="22" EstimateRewinds="0" EstimateRows="6.81818" LogicalOp="Lazy Spool" NodeId="16" Parallel="false" PhysicalOp="Table Spool" EstimatedTotalSubtreeCost="0">
                      <OutputList>
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                      </OutputList>
                      <Spool PrimaryNodeId="2" />
                    </RelOp>
                  </NestedLoops>
                </RelOp>
              </NestedLoops>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>') 

GO
-- Hash Join
SELECT Ped1.Cliente, Ped1.Value
  FROM Orders_LazySpool Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Cliente = Ped1.Cliente)
OPTION(USE PLAN N'<ShowPlanXML xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" Version="1.1" Build="10.50.1746.0" xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementCompId="1" StatementEstRows="4500" StatementId="1" StatementOptmLevel="FULL" StatementOptmEarlyAbortReason="GoodEnoughPlanFound" StatementSubTreeCost="0.341564" StatementText="SELECT Ped1.Cliente, Ped1.Value&#xD;&#xA;  FROM Orders_LazySpool Ped1&#xD;&#xA; WHERE Ped1.Value &lt; (SELECT AVG(Ped2.Value)&#xD;&#xA;                       FROM Orders_LazySpool Ped2&#xD;&#xA;                      WHERE Ped2.Cliente = Ped1.Cliente)&#xD;&#xA;OPTION (MAXDOP 1, RECOMPILE)" StatementType="SELECT" QueryHash="0x54CD13ECA0AC1B54" QueryPlanHash="0x4D3428048BE875E8">
          <StatementSetOptions ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" NUMERIC_ROUNDABORT="false" QUOTED_IDENTIFIER="true" />
          <QueryPlan CachedPlanSize="32" CompileTime="78" CompileCPU="76" CompileMemory="248">
            <RelOp AvgRowSize="20" EstimateCPU="0.0902019" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="4500" LogicalOp="Inner Join" NodeId="0" Parallel="false" PhysicalOp="Hash Match" EstimatedTotalSubtreeCost="0.341564">
              <OutputList>
                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
              </OutputList>
              <MemoryFractions Input="0" Output="0" />
              <Hash>
                <DefinedValues />
                <HashKeysBuild>
                  <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                </HashKeysBuild>
                <HashKeysProbe>
                  <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                </HashKeysProbe>
                <ProbeResidual>
                  <ScalarOperator ScalarString="[NorthWind].[dbo].[Orders_LazySpool].[Cliente] as [Ped1].[Cliente]=[NorthWind].[dbo].[Orders_LazySpool].[Cliente] as [Ped2].[Cliente] AND [NorthWind].[dbo].[Orders_LazySpool].[Value] as [Ped1].[Value]&lt;[Expr1004]">
                    <Logical Operation="AND">
                      <ScalarOperator>
                        <Compare CompareOp="EQ">
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                            </Identifier>
                          </ScalarOperator>
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                            </Identifier>
                          </ScalarOperator>
                        </Compare>
                      </ScalarOperator>
                      <ScalarOperator>
                        <Compare CompareOp="LT">
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                            </Identifier>
                          </ScalarOperator>
                          <ScalarOperator>
                            <Identifier>
                              <ColumnReference Column="Expr1004" />
                            </Identifier>
                          </ScalarOperator>
                        </Compare>
                      </ScalarOperator>
                    </Logical>
                  </ScalarOperator>
                </ProbeResidual>
                <RelOp AvgRowSize="28" EstimateCPU="0.0858651" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="22" LogicalOp="Compute Scalar" NodeId="1" Parallel="false" PhysicalOp="Compute Scalar" EstimatedTotalSubtreeCost="0.16861">
                  <OutputList>
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                    <ColumnReference Column="Expr1004" />
                  </OutputList>
                  <ComputeScalar>
                    <DefinedValues>
                      <DefinedValue>
                        <ColumnReference Column="Expr1004" />
                        <ScalarOperator ScalarString="CASE WHEN [Expr1010]=(0) THEN NULL ELSE [Expr1011]/CONVERT_IMPLICIT(numeric(19,0),[Expr1010],0) END">
                          <IF>
                            <Condition>
                              <ScalarOperator>
                                <Compare CompareOp="EQ">
                                  <ScalarOperator>
                                    <Identifier>
                                      <ColumnReference Column="Expr1010" />
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
                                      <ColumnReference Column="Expr1011" />
                                    </Identifier>
                                  </ScalarOperator>
                                  <ScalarOperator>
                                    <Convert DataType="numeric" Precision="19" Scale="0" Style="0" Implicit="true">
                                      <ScalarOperator>
                                        <Identifier>
                                          <ColumnReference Column="Expr1010" />
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
                    <RelOp AvgRowSize="28" EstimateCPU="0.0858651" EstimateIO="0" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="22" LogicalOp="Aggregate" NodeId="2" Parallel="false" PhysicalOp="Hash Match" EstimatedTotalSubtreeCost="0.16861">
                      <OutputList>
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                        <ColumnReference Column="Expr1010" />
                        <ColumnReference Column="Expr1011" />
                      </OutputList>
                      <MemoryFractions Input="0" Output="0" />
                      <Hash>
                        <DefinedValues>
                          <DefinedValue>
                            <ColumnReference Column="Expr1010" />
                            <ScalarOperator ScalarString="COUNT(*)">
                              <Aggregate AggType="COUNT*" Distinct="false" />
                            </ScalarOperator>
                          </DefinedValue>
                          <DefinedValue>
                            <ColumnReference Column="Expr1011" />
                            <ScalarOperator ScalarString="SUM([NorthWind].[dbo].[Orders_LazySpool].[Value] as [Ped2].[Value])">
                              <Aggregate AggType="SUM" Distinct="false">
                                <ScalarOperator>
                                  <Identifier>
                                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Value" />
                                  </Identifier>
                                </ScalarOperator>
                              </Aggregate>
                            </ScalarOperator>
                          </DefinedValue>
                        </DefinedValues>
                        <HashKeysBuild>
                          <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                        </HashKeysBuild>
                        <RelOp AvgRowSize="20" EstimateCPU="0.016657" EstimateIO="0.066088" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="15000" LogicalOp="Clustered Index Scan" NodeId="3" Parallel="false" PhysicalOp="Clustered Index Scan" EstimatedTotalSubtreeCost="0.082745" TableCardinality="15000">
                          <OutputList>
                            <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                            <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Value" />
                          </OutputList>
                          <IndexScan Ordered="false" ForcedIndex="false" NoExpandHint="false">
                            <DefinedValues>
                              <DefinedValue>
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Cliente" />
                              </DefinedValue>
                              <DefinedValue>
                                <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped2]" Column="Value" />
                              </DefinedValue>
                            </DefinedValues>
                            <Object Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Index="[PK__Orders___3214EC2767DE6983]" Alias="[Ped2]" IndexKind="Clustered" />
                          </IndexScan>
                        </RelOp>
                      </Hash>
                    </RelOp>
                  </ComputeScalar>
                </RelOp>
                <RelOp AvgRowSize="20" EstimateCPU="0.016657" EstimateIO="0.066088" EstimateRebinds="0" EstimateRewinds="0" EstimateRows="15000" LogicalOp="Clustered Index Scan" NodeId="12" Parallel="false" PhysicalOp="Clustered Index Scan" EstimatedTotalSubtreeCost="0.082745" TableCardinality="15000">
                  <OutputList>
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                    <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                  </OutputList>
                  <IndexScan Ordered="false" ForcedIndex="false" NoExpandHint="false">
                    <DefinedValues>
                      <DefinedValue>
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Cliente" />
                      </DefinedValue>
                      <DefinedValue>
                        <ColumnReference Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Alias="[Ped1]" Column="Value" />
                      </DefinedValue>
                    </DefinedValues>
                    <Object Database="[NorthWind]" Schema="[dbo]" Table="[Orders_LazySpool]" Index="[PK__Orders___3214EC2767DE6983]" Alias="[Ped1]" IndexKind="Clustered" />
                  </IndexScan>
                </RelOp>
              </Hash>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>')