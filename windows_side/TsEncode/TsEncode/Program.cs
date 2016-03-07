using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TsEncode
{
	class Program
	{
		static void Main( string[] args )
		{
			if( !MySQLUtility.Open() ) { return; }

			//model.EncodeWaitings.Get().UpdateEncodeWaitingList();
			//model.EncodeWaitings.Get().UpdateEncodeState( 1, model.EncodeWaitings.ENCODE_STATE.wait );

			MySQLUtility.Close();
			//PowerShellUtility.Execute( "ps/encode.ps1", new[] { "a", "b", "c" } );
			if ( MySQLUtility.Open() ) {
				//MySQLUtility.Query( ( reader ) => {
				//	string[] row = new string[ reader.FieldCount ];
				//	for ( int i = 0; i < reader.FieldCount; i++ ) {
				//		Console.WriteLine( reader.GetString( i ) );
				//	}
				//}, "SELECT src_path,dst_path,encode_state FROM encode_waitings where encode_state={0}", 0 );
				//Console.WriteLine( "" );
				//Console.WriteLine( "" );
				//Console.WriteLine( "" );
				//MySQLUtility.QueryDictionary( ( d ) => {
				//	//foreach ( var e in dic ) {
				//	//	Console.WriteLine( "key=" + e.Key + " value=" + e.Value );
				//	//}
				//	Console.WriteLine( (int)d[ "encode_state" ] );
				//}, "SELECT src_path,dst_path,encode_state FROM encode_waitings where encode_state={0}", 0 );
			}
		}
	}
}
