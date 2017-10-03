package gdapi
{
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	internal final class GDLogRequest
	{
		public static var Pool:Vector.<Object> = new Vector.<Object>();;
		
		private static var OpenedURL:String;
		
		public static var ANALYTIC_CMD:String="cmd"; 
		public static var ANALYTIC_VISIT:String="visit"; 
		public static var ANALYTIC_PLAY:String="play"; 
		public static var ANALYTIC_CUSTOM:String="custom"; 
		public static var ANALYTIC_STATE:String="state"; 
		public static var ANALYTIC_URL:String="url"; 
		public static var ANALYTIC_JS:String="js"; 
		
		internal static function PushLog(_pushAction:Object):void
		{
			for (var i:int=0; i < Pool.length;i++) {
				if ( Pool[i].action == _pushAction.action ) {
					if (Pool[i].action == ANALYTIC_CUSTOM && Pool[i].value[0].key==_pushAction.value[0].key) {
						Pool[i].value[0].value++;
					} else {
						Pool[i].value = _pushAction.value;
					}
					break;
				}
			}
			if (i==Pool.length) Pool.push(_pushAction);
			return;
		}
		
		internal static function OpenURL(_url:String,_target:String="_blank",_reopen:Boolean=false):int {
			var res:int=1500;
			if (_reopen) {
				OpenedURL="";
				res = 1501;
			} else if (OpenedURL!=_url) {
				navigateToURL(new URLRequest(_url),_target);
				OpenedURL = _url;
				res = 1502;
			}			
			return res;
		}		
		
		internal static function CallJS(_data:String):Object {
			var res:int=1600;
			var cresult:String = "";
			if(ExternalInterface.available)
			{
				try
				{
					cresult = String(ExternalInterface.call(_data));
					res=1601;
				}
				catch(s:Error)
				{
					cresult = s.message;
					res=1602;
				}
			}
			return ({"response":res,"cresult":cresult});			
		}
		internal static function doResponse(ResponseData:Object):void 
		{
			switch (ResponseData.act) {
				case ANALYTIC_CMD:
						var sendObj:Object = new Object();
						switch(ResponseData.res) {
							case ANALYTIC_VISIT:
								GDApi.Visit();
								break;
							case ANALYTIC_URL:
								sendObj.action = "cbp";
								sendObj.value = OpenURL(ResponseData.dat.url,ResponseData.dat.target,ResponseData.dat.reopen);
								PushLog(sendObj);						
								break;
							case ANALYTIC_JS:
								sendObj.action = "cbp";
								var _CallJS:Object = CallJS(ResponseData.dat.jsdata);
								sendObj.value = _CallJS.response;
								sendObj.result = _CallJS.cresult;
								PushLog(sendObj);						
								break;							
						}						
						break;				
				case ANALYTIC_VISIT:
						if (ResponseData.res==GDApi._SID) {
							GDUtils.SaveCookie(ANALYTIC_VISIT,0);
							GDUtils.SaveCookie(ANALYTIC_STATE,GDUtils.GetCookie(ANALYTIC_STATE)+1);
						}
						break;
				case ANALYTIC_PLAY:
						if (ResponseData.res==GDApi._SID) {
							GDUtils.SaveCookie(ANALYTIC_PLAY,0);
						}
						break;
				case ANALYTIC_CUSTOM:
					if (ResponseData.res==GDApi._SID) {
						GDUtils.SaveCookie(ResponseData.custom,0);
					}
					break;
				
			}
		}
	}
}