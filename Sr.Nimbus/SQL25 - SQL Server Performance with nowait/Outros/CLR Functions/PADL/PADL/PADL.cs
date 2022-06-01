using System;
using System.Collections;
using System.Data;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;
using System.Text;
public partial class UD_String_functions_Transact_SQL_CS
{
    public struct Struc_AllWords
    {
        public short Wordnum;
        public string Word;
        public short Startofword;
        public short Lengthofword;
    }

    private static string Replicate(string cExpression, int nTimes)
    {
        StringBuilder sb = new StringBuilder(); //Create a stringBuilder
        sb.Insert(0, cExpression, nTimes);      //Insert the expression into the StringBuilder for nTimes
        return sb.ToString();                   //Convert it to a string and return it back
    }

    public static string Padl(string cString, short nLen, string cPadCharacter)
    {
        if (cPadCharacter == null || cPadCharacter.Length == 0)
        {
            cPadCharacter = " ";
        }
        if (cString.Length >= nLen)
        {
            cString = cString.Substring(0, nLen);
        }
        else
        {
            int nLeftLen = (nLen - cString.Length); //   Quantity of characters, added at the left
            cString = Replicate(cPadCharacter, (int)(System.Math.Ceiling((nLeftLen / cPadCharacter.Length) + (double)2))).Substring(0, nLeftLen) + cString;
        }
        return cString;
    }

}  //  UD_String_functions_Transact_SQL_CS

