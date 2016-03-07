using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

public class PowerShellUtility
{
	// 指定されたPowerShellを実行
	public static void Execute( string filepath, IEnumerable input )
	{
		string shell = "";
		try {
			using ( StreamReader sr = new StreamReader( filepath, Encoding.GetEncoding( "Shift_JIS" ) ) )  {
				shell = sr.ReadToEnd(); 
			}
			Console.WriteLine( shell );

		} catch ( Exception e ) {
			Console.WriteLine( e.Message );
		}

		using ( var invoker = new RunspaceInvoke() ) {
			// TODO ブロッキングしないようにしたい.
			// TODO エラーハンドル.
			var results = invoker.Invoke( shell, input );

			foreach ( var result in results ) {
				Console.WriteLine( result );
			}
		}
	}
}

