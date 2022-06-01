using System;
using System.Collections.Generic;
using System.Text;

namespace SqlClrLib.Model
{
    /// <summary>
    /// Holds thread execution result
    /// </summary>
    [Serializable]
    class ResultItem
    {
        public ResultItem(ThreadSql sql)
        {
            Key = sql.Key;
            Success = sql.Exception == null;
            RunTime = Convert.ToInt32(sql.RunTime);
            if (sql.Exception != null)
            {
                ErrorMessage = sql.Exception.Message;
                ErrorStack = string.Format("{0}:\n{1}", sql.Exception.GetType().FullName, sql.Exception.StackTrace);
            }
            else
            {
                ErrorMessage = string.Empty;
                ErrorStack = string.Empty;
            }
        }
        public string Key;
        public bool Success;
        public int RunTime;
        public string ErrorMessage;
        public string ErrorStack;
    }

}
