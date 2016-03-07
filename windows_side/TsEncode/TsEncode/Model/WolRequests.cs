using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace model
{
	public class WolRequests
	{
		static WolRequests instance = null;
		private WolRequests() { }
		public static WolRequests Get()
		{
			if ( instance == null ) {
				instance = new WolRequests();
			}
			return instance;
		}

		public enum WOL_STATE
		{
			requested,
			success,
			pending,
		}

		// WOLリクエストが来ているか確認
		public bool CheckWolRequested()
		{
			bool isExist = false;

			List<string> pendingIds = new List<string>();
			List<string> requestIds = new List<string>();
			MySQLUtility.QueryDictionary( ( d ) => {
				int id = (int)d[ "id" ];
				var requestTime = (DateTime)d[ "created_at" ];
				var tp = DateTime.Now - requestTime;
				// 15分超えてたら無視.
				if ( 15.0f < tp.TotalMinutes ) {
					pendingIds.Add( id.ToString() );
					return;
				}
				Console.WriteLine( requestTime.ToString() );
				requestIds.Add( id.ToString() );
				isExist = true;
			}, "SELECT id,created_at FROM wol_requests where wol_state={0}", (int)WOL_STATE.requested );

			// 時間超えてるのはpending状態にする
			if ( 0 < pendingIds.Count ) {
				MySQLUtility.Query( null, "UPDATE wol_requests SET wol_state={0} WHERE {1}",
					(int)WOL_STATE.pending, MySQLUtility.BuildOrQueryHelper( "id", pendingIds ) );
			}
			if ( 0 < requestIds.Count ) {
				MySQLUtility.Query( null, "UPDATE wol_requests SET wol_state={0} WHERE {1}",
					(int)WOL_STATE.success, MySQLUtility.BuildOrQueryHelper( "id", requestIds ) );
			}
			return isExist;
		}
	}
}
