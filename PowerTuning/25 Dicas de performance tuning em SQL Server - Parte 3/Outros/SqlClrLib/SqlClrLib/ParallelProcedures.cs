using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Collections.Generic;
using System.Threading;
using System.Collections;
using System.Transactions;

using SqlClrLib.Model;

public partial class StoredProcedures
{
    [ThreadStatic]
    private static ParallelBlock _block;

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Parallel_Declare([SqlFacet(MaxSize = 50)] SqlString name)
    {
        _block = new ParallelBlock(name);
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="mode">
        //     Volatile data can be read but not modified, and no new data can be added
        //     during the transaction.
        //Serializable = 0,
        //
        //     Volatile data can be read but not modified during the transaction. New data
        //     can be added during the transaction.
        //RepeatableRead = 1,
        //
        //     Volatile data cannot be read during the transaction, but can be modified.
        //ReadCommitted = 2,
        //
        //     Volatile data can be read and modified during the transaction.
        //ReadUncommitted = 3,
        //
        //     Volatile data can be read. Before a transaction modifies data, it verifies
        //     if another transaction has changed the data after it was initially read.
        //     If the data has been updated, an error is raised. This allows a transaction
        //     to get to the previously committed value of the data.
        //Snapshot = 4,
        //
        //     The pending changes from more highly isolated transactions cannot be overwritten.
        //Chaos = 5,
        //
        //     A different isolation level than the one specified is being used, but the
        //     level cannot be determined. An exception is thrown if this value is set.
        //Unspecified = 6,
    /// </param>
    /// <param name="mode"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Parallel_UseTransaction([SqlFacet(MaxSize=20, IsNullable=false)] SqlString mode)
    {
        EnsureBlockDeclared();
        System.Transactions.IsolationLevel level = (System.Transactions.IsolationLevel)Enum.Parse(
            typeof(System.Transactions.IsolationLevel), mode.Value);
        _block.StartTransaction(level);
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Parallel_SetOption_CommandTimeout(int commandTimeout)
    {
        EnsureBlockDeclared();
        _block.CommandTimeout = commandTimeout;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Parallel_SetOption_MaxThreads(int maxThreads)
    {
        EnsureBlockDeclared();
        _block.MaxThreads = maxThreads;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Parallel_AddSql([SqlFacet(MaxSize=128, IsNullable=false)] SqlString key, SqlChars sql)
    {
        EnsureBlockDeclared();
        _block.Add(key.Value, new string(sql.Value));
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static int Parallel_Execute()
    {
        EnsureBlockDeclared();
        int count = 0;
        if (_block.IsTransactional)
        {
            TransactionOptions opt = new TransactionOptions();
            opt.IsolationLevel = _block.TransactionLevel;
            using (TransactionScope scope = new TransactionScope(TransactionScopeOption.RequiresNew, opt))
            {
                TransactionInterop.GetTransmitterPropagationToken(Transaction.Current);
                count = _block.Run(Transaction.Current);
                if (count == 0)
                    scope.Complete();
            }
        }
        else
        {
            count = _block.Run(null);
        }
        return count;
    }

    [Microsoft.SqlServer.Server.SqlFunction(FillRowMethodName = "Parallel_Result_FillRow",
        TableDefinition = "key_s nvarchar(100), success_f bit, run_time_ms int, error_s nvarchar(max), error_stack nvarchar(max)")]
    public static IEnumerable Parallel_GetExecutionResult()
    {
        EnsureBlockDeclared();
        ResultItem[] result = _block.GetResult();
        return result;
    }

    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlChars Parallel_GetErrorMessage()
    {
        EnsureBlockDeclared();
        string errorMessage = string.Empty;
        ResultItem[] result = _block.GetResult();
        foreach (ResultItem item in result)
        {
            if (item.ErrorMessage.Length > 0)
                errorMessage += string.Format("{0}: {1}\n\r", item.Key, item.ErrorMessage);
        }

        if (errorMessage.Length == 0)
            return SqlChars.Null;

        return new SqlChars(string.Format("Parallel block '{0}' failed with following errors:\n\r{1}", _block.Name, errorMessage));
    }

    private static void Parallel_Result_FillRow(object obj, out string key_s, out bool success_f, out int run_time_ms, out string error_s, out string error_stack)
    {
        ResultItem item = obj as ResultItem;
        key_s = item.Key;
        success_f = item.Success;
        run_time_ms = item.RunTime;
        error_s = item.ErrorMessage;
        error_stack = item.ErrorStack;
    }

    private static void EnsureBlockDeclared()
    {
        if (_block == null)
            throw new ArgumentNullException("Parallel block has not been declared. Please execute Parallel_Declare stored procedure first.");
    }
};
