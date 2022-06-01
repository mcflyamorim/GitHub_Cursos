using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Data.Sql;
using Microsoft.SqlServer.Server;

namespace WindowsFormsApplication1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection("Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=NorthWind;Data Source=HPFABIANO\\SQL2012"))
            {
                // Inicio
                DateTime Date1;
                Date1 = DateTime.Now;
                conn.Open();
                SqlCommand QuerySQL = new SqlCommand("DBCC DROPCLEANBUFFERS; SELECT OrderID, CustomerID, OrderDate FROM OrdersBig ORDER BY CustomerID OPTION (MAXDOP 1)", conn);
                DataSet ds1 = new DataSet();
                SqlDataAdapter adp1 = new SqlDataAdapter(QuerySQL);
                adp1.Fill(ds1,"OrdersBig");
                dataGridView1.DataMember = "OrdersBig";
                dataGridView1.DataSource = ds1;
                conn.Close();
                // Fim
                DateTime Date2;
                Date2 = DateTime.Now;
                TimeSpan Diff;
                Diff = Date2.Subtract(Date1);
                MessageBox.Show(Diff.ToString());
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection("Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=NorthWind;Data Source=HPFABIANO\\SQL2012"))
            {
                // Inicio
                DateTime Date1;
                Date1 = DateTime.Now;
                conn.Open();
                SqlCommand QuerySQL = new SqlCommand("DBCC DROPCLEANBUFFERS; SELECT OrderID, CustomerID, OrderDate FROM OrdersBig OPTION (MAXDOP 1)", conn);
                DataSet ds1 = new DataSet();
                SqlDataAdapter adp1 = new SqlDataAdapter(QuerySQL);
                adp1.Fill(ds1, "OrdersBig");
                dataGridView1.DataMember = "OrdersBig";
                dataGridView1.DataSource = ds1;
                // Fim
                DateTime Date2;
                Date2 = DateTime.Now;
                TimeSpan Diff;
                Diff = Date2.Subtract(Date1);
                MessageBox.Show(Diff.ToString());
                Date1 = DateTime.Now;
                dataGridView1.Sort(dataGridView1.Columns["CustomerID"], ListSortDirection.Ascending);
                conn.Close();
                // Fim
                Date2 = DateTime.Now;
                Diff = Date2.Subtract(Date1);
                MessageBox.Show(Diff.ToString());
            }
        }
    }
}
