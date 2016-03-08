using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TsEncode
{
	class Program
	{
		static void Main( string[] args )
		{
			bool isShutdown = false;
			do {
				Console.WriteLine( "システムが完全に起動するまで暫くお待ちください・・・" );
				System.Threading.Thread.Sleep( 1 * 60 * 1000 );

				Console.WriteLine( "MySQLサーバーへの接続を開始します" );
				if ( !MySQLUtility.Open() ) {
					Console.WriteLine( "MySQLサーバーへの接続に失敗しました" );
					//Console.ReadKey();
					break;
				}

				// WOLによって起動したか確認.
				Console.WriteLine( "WOLでの起動か確認します。" );
				var wrm = model.WolRequests.Get();
				if ( !wrm.CheckWolRequested() ) {
					// WOLリクエストが無ければエンコードはしない.
					Console.WriteLine( "WOL要求が発見できませんでした" );
					//Console.ReadKey();
					break;
				}

				isShutdown = true;
				var ewm = model.EncodeWaitings.Get();

				Console.WriteLine( "エンコードを開始します" );
				while ( true ) {
					// エンコード待ちリスト更新.
					ewm.UpdateEncodeWaitingList();
					if ( ewm.IsEmpty() ) { break; }
					// 逐次エンコード
					ewm.Foreach( ( info ) => {
						ewm.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.progress );
						PowerShellUtility.Execute( "Ps/encode.ps1", new[] { "192.168.1.6", info.SrcPath, info.DstPath } );
						// TODO エラー処理が無いのでエンコードへまっても成功になる！
						ewm.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.success );
					} );
				}
				Console.WriteLine( "全てのエンコード処理が完了しました。シャットダウンを実行します。" );
				//Console.ReadKey();

			} while ( false );

			MySQLUtility.Close();

			if ( isShutdown ) {
				try {
					ProcessStartInfo psi = new ProcessStartInfo();
					psi.FileName = "shutdown.exe";
					psi.Arguments = "-s -t 0";   // shutdown
					//psi.Arguments = "-r -t 0";   // reboot
					psi.CreateNoWindow = true;
					Process p = Process.Start( psi );
				} catch ( Exception ex ) {
					Trace.WriteLine( ex.Message );
				}
			}

		}
	}
}
