using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace model
{
	public class EncodeWaitings
	{
		static EncodeWaitings instance = null;
		private EncodeWaitings() { }
		public static EncodeWaitings Get()
		{
			if ( instance == null ) {
				instance = new EncodeWaitings();
			}
			return instance;
		}

		public enum ENCODE_STATE
		{
			wait = 0,
			progress,
			success,
			failure,
		}

		public class EncodeWaitingInfo
		{
			public EncodeWaitingInfo( int id, string srcPath, string dstPath, ENCODE_STATE encodeState )
			{
				Id = id;
				SrcPath = srcPath.Replace( '/', '\\' );
				DstPath = dstPath.Replace( '/', '\\' );
				EncodeState = encodeState;
			}
			public int Id { get; private set; }
			public string SrcPath { get; private set; }
			public string DstPath { get; private set; }
			public ENCODE_STATE EncodeState { get; private set; }
		}
		List<EncodeWaitingInfo> infos = new List<EncodeWaitingInfo>();

		// エンコード待ちリスト更新
		public void UpdateEncodeWaitingList()
		{
			infos.Clear();
			MySQLUtility.QueryDictionary( ( d ) => {
				infos.Add( new EncodeWaitingInfo( (int)d[ "id" ], (string)d[ "src_path" ], (string)d[ "dst_path" ], (ENCODE_STATE)d[ "encode_state" ] ) );
			}, "SELECT id,src_path,dst_path,encode_state FROM encode_waitings where encode_state={0}", 0 );
			Console.WriteLine();
		}

		// エンコード状態更新.
		public void UpdateEncodeState( int id, ENCODE_STATE state ) 
		{
			MySQLUtility.Query( null, "UPDATE encode_waitings SET encode_state={0} WHERE id={1}", (int)state, id );
			UpdateEncodeWaitingList();
		}
	}
}

