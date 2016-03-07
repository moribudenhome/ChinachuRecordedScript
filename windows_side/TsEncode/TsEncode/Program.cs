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

			var m = model.EncodeWaitings.Get();

			// エンコード待ちリスト更新.
			m.UpdateEncodeWaitingList();
			// 逐次エンコード
			m.Foreach( ( info ) => {
				m.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.progress );
				PowerShellUtility.Execute( "Ps/encode.ps1", new[] { "192.168.1.6", info.SrcPath, info.DstPath } );
				// TODO エラー処理が無いのでエンコードへまっても成功になる！
				m.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.success);
			} );

			MySQLUtility.Close();
		}
	}
}
