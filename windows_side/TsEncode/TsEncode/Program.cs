using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
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
			bool isStartupMode = false;
			foreach ( string arg in args ) {
				if ( arg == "--startupmode" || arg == "-s" ) {
					isStartupMode = true;
				}
			}
			do {
				if ( isStartupMode ) {
					Console.WriteLine( "システムが完全に起動するまで暫くお待ちください・・・" );
					System.Threading.Thread.Sleep( 1 * 60 * 1000 );
				}

				Console.WriteLine( "MySQLサーバーへの接続を開始します" );
				if ( !MySQLUtility.Open() ) {
					Console.WriteLine( "MySQLサーバーへの接続に失敗しました" );
					//Console.ReadKey();
					break;
				}

				if ( isStartupMode ) {
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
				}

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
						var srcfi = new FileInfo( @"\\192.168.1.6\share\" + info.SrcPath );
						var dstfi = new FileInfo( @"\\192.168.1.6\share\" + info.DstPath );
						// TODO ある程度ファイルサイズのサンプルが取れたら、サイズによってエンコード失敗してないかチェック
						// ひとまず512k以下は失敗とする
						if ( dstfi.Exists && 512000 < dstfi.Length ) {
							Console.WriteLine( "エンコード成功" );
							ewm.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.success );
						} else {
							Console.WriteLine( "エンコード失敗" );
							ewm.UpdateEncodeState( info.Id, model.EncodeWaitings.ENCODE_STATE.failure );
						}
					} );
					break;
				}
				Console.WriteLine( "全てのエンコード処理が完了しました。" );
				//Console.ReadKey();

			} while ( false );

			MySQLUtility.Close();

			if ( isShutdown ) {
				try {
					Console.WriteLine( "シャットダウンを実行します" );
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
