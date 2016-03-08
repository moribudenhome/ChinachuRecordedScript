using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

public class PowerShellUtility
{
	static PSDataCollection<PSObject> outputCollection = null;
	
	// 指定されたPowerShellを実行
	public static void Execute( string filepath, string[] input )
	{
		string shell = "";
		try {
			using ( StreamReader sr = new StreamReader( filepath, Encoding.GetEncoding( "Shift_JIS" ) ) )  {
				shell = sr.ReadToEnd(); 
			}

		} catch ( Exception e ) {
			Console.WriteLine( e.Message );
		}

		outputCollection = new PSDataCollection<PSObject>();
		outputCollection.DataAdded += OnDataAdded;

		using ( var rs = RunspaceFactory.CreateRunspace() ) {
			rs.Open();
			using ( PowerShell ps = PowerShell.Create() ) {
				ps.AddScript( shell );
				for ( int i = 0; i < input.Length; i++ ) {
					ps.AddParameter( "arg" + i, input[ i ] );
				}
				IAsyncResult a = ps.BeginInvoke<PSObject, PSObject>( null, outputCollection );
				a.AsyncWaitHandle.WaitOne();
			}
		}
	}

	static void OnDataAdded( object sender, DataAddedEventArgs e )
	{
		if ( outputCollection == null ) { return; }
		Console.WriteLine( outputCollection[ e.Index ] );
	}
}

