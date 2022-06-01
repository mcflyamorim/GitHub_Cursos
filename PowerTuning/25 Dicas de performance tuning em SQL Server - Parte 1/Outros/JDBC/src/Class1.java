// Import the SQL Server JDBC Driver classes 
import java.sql.*;

public class Class1 {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		
		try  
	       { 
	            // Load the SQLServerDriver class, build the 
	            // connection string, and get a connection 
	            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver"); 
	            String connectionUrl = "jdbc:sqlserver://dellfabiano\\sql2016;" +
	                                    "SelectMethod=direct;" + 
	                                    "database=NorthWind;" + 
	                                    "user=sa;" + 
	                                    "password=@bc12345"; 
	            
	            Connection con = DriverManager.getConnection(connectionUrl); 
	            System.out.println("Connected...");

	            // Create and execute an SQL statement that returns some data.  

	            // Prepare a statement
	            PreparedStatement ps = con.prepareStatement( "SELECT CustomerID, ContactName FROM CustomersBig WHERE ContactName = ?" ) ;

	            // Set the first parameter of the statement
	            ps.setObject( 1, "Fabiano Amorim") ;
          
	            // Execute the query
	            ResultSet rs = ps.executeQuery() ;
	            
	            // Iterate through the data in the result set and display it.  
	            while (rs.next())  
	            {  
	               System.out.println(rs.getString(1) + " " + rs.getString(2));  
	            }
	            System.out.println("Done...");

	       }  
	       catch(Exception e)  
	       { 
	            System.out.println(e.getMessage()); 
	            System.exit(0);  
	       } 
	}

}
