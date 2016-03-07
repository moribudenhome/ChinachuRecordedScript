using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public class MySQLUtility
{
	public static MySqlConnection MySQLConnection { get; private set; }

	public static bool Open()
	{
		Close();

		// TODO 後で外から設定できるようにしような
		string connstr = "userid=root; password=; database=chinachu_manage; host=192.168.1.6";

		MySQLConnection = new MySqlConnection( connstr );
		try {
			MySQLConnection.Open();
		} catch ( MySqlException e ) {
			Console.WriteLine( e.Message );
			return false;
		}
		return true;
	}

	public static void Close()
	{
		if ( MySQLConnection != null ) {
			MySQLConnection.Close();
			MySQLConnection = null;
		}
	}

	public static void Query( Action<MySqlDataReader> row, string format, params object[] args )
	{
		MySqlCommand cmd = new MySqlCommand( string.Format( format, args ), MySQLConnection );
		MySqlDataReader reader = cmd.ExecuteReader();
		while ( reader.Read() ) {
			if ( row != null ) {
				row( reader );
			}
		}
		reader.Close();
	}

	public static bool QueryDictionary( Action<Dictionary<string, object>> row, string format, params object[] args )
	{
		MySqlCommand cmd = new MySqlCommand( string.Format( format, args ), MySQLConnection );
		try {
			MySqlDataReader reader = cmd.ExecuteReader();

			// カラム名をリストアップ
			string[] names = new string[ reader.FieldCount ];
			for ( int i = 0; i < reader.FieldCount; i++ ) {
				names[ i ] = reader.GetName( i );
			}

			// レコード情報構築.
			while ( reader.Read() ) {
				var recorde = new Dictionary<string, object>();
				for ( int i = 0; i < reader.FieldCount; i++ ) {
					recorde[ names[ i ] ] = reader.GetValue( i );
				}
				if ( row != null ) {
					row( recorde );
				}
			}
			reader.Close();
			return true;
		} catch ( MySqlException e ) {
			Console.WriteLine( e.Message );
			return false;
		}
	}
}
