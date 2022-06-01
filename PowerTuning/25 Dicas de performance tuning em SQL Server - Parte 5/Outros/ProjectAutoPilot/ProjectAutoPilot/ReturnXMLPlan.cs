using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;


public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void CLR_GetAutoPilotShowPlan
    (
         SqlString SQL,
         out SqlXml PlanXML
    )
    {
        //Prep connection
        SqlConnection cn = new SqlConnection("Context Connection = True");

        //Set command texts
        SqlCommand cmd_SetAutoPilotOn = new SqlCommand("SET AUTOPILOT ON", cn);
        SqlCommand cmd_SetAutoPilotOff = new SqlCommand("SET AUTOPILOT OFF", cn);
        SqlCommand cmd_input = new SqlCommand(SQL.ToString(), cn);

        if (cn.State != ConnectionState.Open)
        {
            cn.Open();
        }

        //Run AutoPilot On
        cmd_SetAutoPilotOn.ExecuteNonQuery();

        //Run input SQL
        SqlDataAdapter da = new SqlDataAdapter();
        DataSet ds = new DataSet();

        da.SelectCommand = cmd_input;
        ds.Tables.Add(new DataTable("Results"));

        ds.Tables[0].BeginLoadData();
        da.Fill(ds, "Results");
        ds.Tables[0].EndLoadData();

        //Run AutoPilot Off
        cmd_SetAutoPilotOff.ExecuteNonQuery();

        if (cn.State != ConnectionState.Closed)
        {
            cn.Close();
        }

        //Package XML as output
        System.Xml.XmlDocument xmlDoc = new System.Xml.XmlDocument();
        //XML is in 1st Col of 1st Row of 1st Table
        xmlDoc.InnerXml = ds.Tables[0].Rows[0][0].ToString();
        System.Xml.XmlNodeReader xnr = new System.Xml.XmlNodeReader(xmlDoc);
        PlanXML = new SqlXml(xnr);
    }
};
