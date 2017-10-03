package gdapi
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
		
	import gdapi.json.JSONDecoder;
	import gdapi.json.JSONEncoder;
		
	internal final class GDChannel
	{
		private static var StatsURL:String;
		internal static var StatsURLHead:String;
		
		private static var urlLoader:URLLoader = new URLLoader();
		private static var urlRequest:URLRequest = new URLRequest();
		private static var postObj:URLVariables = new URLVariables();;
		private static var callbackParam:String;
				
		internal static function Init():void
		{
			//Pool = new Vector.<PRequest>();
			StatsURLHead = (GDApi._UseSSL ? "https://" : "http://") + GDApi._GUID + "."+ GDApi._ServerId +".submityourgame.com";
			StatsURL = StatsURLHead + "/"+GDApi._ServerVersion+"/";
			
			urlLoader.addEventListener("ioError", Fail);
			urlLoader.addEventListener("networkError", Fail);
			urlLoader.addEventListener("verifyError", Fail);
			urlLoader.addEventListener("diskError", Fail);
			urlLoader.addEventListener("securityError", Fail);
			urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
			urlLoader.addEventListener("complete", Complete);
			
			postObj.gid = GDApi._GID;
			postObj.ref = GDApi._WebRef; 
			postObj.sid = GDApi._SID;
			postObj.ver = GDApi._ApiVersion;
			
			urlRequest.contentType = "application/x-www-form-urlencoded";
			urlRequest.url = StatsURL;
			urlRequest.method = URLRequestMethod.POST;
			
			var chanTimer:Timer = new Timer(30000);
			chanTimer.addEventListener(TimerEvent.TIMER, TimerHandler);
			chanTimer.start();			
		}
		private static function TimerHandler(event:Event):void
		{	
			
			GDUtils.DebugLog('timer working...');		
			
			if (GDApi._Enabled) {
				var actionArray:Object = GDApi.Ping();				
				if (GDLogRequest.Pool.length>0) {
					actionArray = GDLogRequest.Pool.shift();
					GDUtils.DebugLog('Pool length > 0');		
				} 
				postObj.cbp = callbackParam;
				try {					
					postObj.act = new JSONEncoder( actionArray ).getString();
					GDUtils.DebugLog('post obj act: '+postObj.act);
					urlRequest.data = postObj;
					urlLoader.load(urlRequest);
					//GDUtils.DebugLog('Send action: '+postObj.act);
				} 
				catch (e:Error) {
					GDUtils.DebugLog('JSON Error: '+e.message);					
				}
			}
		}
		
		private static function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			//GDUtils.DebugLog('Response: '+request.data);			
						
			switch (e.type) {
				case Event.COMPLETE:
					if (request.data!=null && request.data!='') 
					{
						try {							
							var vars:Object = new JSONDecoder( request.data,true ).getValue();
							GDLogRequest.doResponse(vars);
							callbackParam = vars.cbp;
						}
						catch (e:Error) {
							GDUtils.DebugLog('JSON Error: '+e.message);					
							GDApi.Visit();
						}
					}
					break;
			}
			
		}
		
		private static function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			GDApi.Visit();
			GDUtils.DebugLog('Fail: '+e+' : '+request.data);			
		}
		
		private static function HTTPStatusIgnore(e:Event):void
		{
		}
		
	}
}