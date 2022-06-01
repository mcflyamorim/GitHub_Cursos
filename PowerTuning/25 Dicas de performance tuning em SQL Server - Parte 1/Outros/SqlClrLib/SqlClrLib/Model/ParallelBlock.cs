using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Transactions;
using System.Data.SqlClient;
using System.Data;
using System.Threading;

namespace SqlClrLib.Model
{
    /// <summary>
    /// Manages parallel execution of added <see cref="ThreadSql"/ items>
    /// </summary>
    class ParallelBlock
    {
        private string _name;
        private List<ThreadSql> _threads;
        private string _connectionString;
        private int _commandTimeout = 0;
        private List<string> _startedThreads;

        /// <summary>
        /// Initializes parallel block during the call to <see cref="Parallel_Declare"/> stored procedure
        /// </summary>
        /// <param name="name"></param>
        public ParallelBlock(SqlString name)
        {
            string srvName = null;
            _startedThreads = new List<string>();
            _name = name.IsNull ? string.Empty : name.Value;

            //let's get current server name
            SqlConnectionStringBuilder connStrBuilder = new SqlConnectionStringBuilder();
            connStrBuilder.ContextConnection = true;
            using (SqlConnection conn = new SqlConnection(connStrBuilder.ConnectionString))
            {
                conn.Open();
                using (SqlCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT @@SERVERNAME";
                    cmd.CommandType = CommandType.Text;
                    srvName = (string)cmd.ExecuteScalar();
                }
                conn.Close();
            }
            //build connection string, which will be used to execute sql in threads
            connStrBuilder = new SqlConnectionStringBuilder();
            connStrBuilder.DataSource = srvName;
            connStrBuilder.IntegratedSecurity = true;
            connStrBuilder.MultipleActiveResultSets = false;
            connStrBuilder.Pooling = true;
            //Enlisting will be done when connecting to server if transaction is enabled
            connStrBuilder.Enlist = false;
            _connectionString = connStrBuilder.ConnectionString;

            _threads = new List<ThreadSql>();
        }

        /// <summary>
        /// Returns connection string to current server
        /// </summary>
        public string ConnectionString
        {
            get { return _connectionString; }
        }

        /// <summary>
        /// Returns the name of the block set by Parallel_Declare procedure
        /// </summary>
        public string Name
        {
            get { return _name; }
        }

        /// <summary>
        /// Adds sql to be executed in parallel
        /// </summary>
        /// <param name="key"></param>
        /// <param name="sql"></param>
        public void Add(string key, string sql)
        {
            foreach (ThreadSql thread in _threads)
            {
                if (thread.Key == key)
                    throw new Exception(string.Format("Duplicate key '{0}'", key));
            }

            ThreadSql threadSql = new ThreadSql(key, _connectionString, sql);
            _threads.Add(threadSql);
        }

        /// <summary>
        /// Gets/Sets command timeout in seconds. Default value is 120 seconds
        /// </summary>
        public int CommandTimeout
        {
            get { return _commandTimeout; }
            set { _commandTimeout = value; }
        }

        private System.Transactions.IsolationLevel _transactionLevel;
        /// <summary>
        /// Will mark the block as transactional
        /// </summary>
        /// <param name="level"></param>
        public void StartTransaction(System.Transactions.IsolationLevel level)
        {
            _transactionLevel = level;
            IsTransactional = true;
        }

        /// <summary>
        /// Returns transaction level
        /// </summary>
        public System.Transactions.IsolationLevel TransactionLevel
        {
            get { return _transactionLevel; }
        }

        private bool _istransactional = false;
        /// <summary>
        /// Gets/Sets value indicating if parallel block is transactional
        /// </summary>
        public bool IsTransactional
        {
            get
            {
                return _istransactional;
            }
            set { _istransactional = value; }
        }

        private int _maxThreads = 10;

        /// <summary>
        /// Gets/Sets maximum number of thread to be executed at the same time
        /// </summary>
        public int MaxThreads
        {
            get { return _maxThreads; }
            set
            {
                if (value < 1 || value > 64)
                    throw new ArgumentException(string.Format("Maximum number of threads can be between 1 and 64. Value {0}.", value));
                _maxThreads = value;
            }
        }

        /// <summary>
        /// Gets array of results from thread execution.
        /// </summary>
        /// <returns></returns>
        public ResultItem[] GetResult()
        {
            List<ResultItem> items = new List<ResultItem>();
            foreach (ThreadSql sql in _threads)
            {
                items.Add(new ResultItem(sql));
            }

            return items.ToArray();
        }

        /// <summary>
        /// Executes sqls in parallel
        /// </summary>
        /// <param name="trans"></param>
        /// <returns></returns>
        public int Run(Transaction trans)
        {
            int failedCount = 0;

            if (_threads.Count > 0)
            {
                //make sure each thread is set to transactional if transaction is set
                foreach (ThreadSql sql in _threads)
                {
                    sql.AddTransaction(trans);
                }
                List<WaitHandle> handles = new List<WaitHandle>();
                //Start first [MaxThreads] threads
                foreach (ThreadSql sql in _threads)
                {
                    if (!sql.IsStarted)
                    {
                        handles.Add(sql.Start());
                        if (handles.Count >= MaxThreads)
                            break;
                    }
                }

                bool failed = false;

                while (handles.Count > 0)
                {
                    //Let's implemented better ThreadPool then MS one.
                    //WaitAny can accept no more then 64 items in the array
                    WaitHandle.WaitAny(handles.ToArray());
                    handles.Clear();

                    if (!failed)
                    {
                        //let's check if any thread has failed
                        foreach (ThreadSql sql in _threads)
                        {
                            if (sql.Exception != null)
                            {
                                failed = true;
                                break;
                            }
                        }
                    }

                    if (!failed)
                    {
                        //if there are no failed threads continue

                        //Let's get all running threads
                        foreach (ThreadSql sql in _threads)
                        {
                            if (sql.IsRunning)
                                handles.Add(sql.Handle);
                            if (handles.Count > MaxThreads)
                                break;
                        }

                        //if number of threads less then [MaxThreads]
                        if (handles.Count <= MaxThreads)
                        {
                            foreach (ThreadSql sql in _threads)
                            {
                                //let's add new threads to process
                                if (!sql.IsStarted)
                                {
                                    handles.Add(sql.Start());
                                    if (handles.Count >= MaxThreads)
                                        break;
                                }
                            }
                        }
                    }
                }

                //After all threads are done, let's check how many failed
                foreach (ThreadSql sql in _threads)
                {
                    if (sql.Exception != null)
                        failedCount++;

                    if (sql.Handle != null)
                        sql.Handle.Close();
                }
            }

            return failedCount;
        }
    }
}
