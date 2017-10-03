package gdapi
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	import flash.system.Security;
	
	import gd.GDEvent;
	
	[SWF(width='540',height='440',frameRate='30',backgroundColor='0x000000')]
	public dynamic class GDApi extends Sprite
	{		
		/*
		* Properties 
		*/
		internal static var _UseSSL:Boolean = false;
		internal static var _apiWidth:int=640;
		internal static var _apiHeight:int=480;		
		internal static var _BannerTimeOut:int=50;
		internal static var _BlockText:String='';
		internal static var _SID:String = "";
		internal static var _GID:String = "";
		internal static var _USERID:String = "";
		internal static var _GUID:String = "";
		internal static var _ROOT:DisplayObject;
		internal static var _ServerId:String = "";
		internal static var _Enabled:Boolean = true;
		internal static var _WebRef:String = "";
		internal static var _isLocal:Boolean=false;
		internal static var _ApiVersion:String = "v232";
		internal static var _ServerVersion:String = "v1";
		internal static var _Stage:Stage;
		
		/*
		 * Private declaration 
		*/
		internal static var Debug_InitWarning:String = "First, you have to call 'Log' method to connect to the server.";
		internal static var Debug_NotSetParams:String = "Please check initiliaze params, gid or userid";
		internal static var Cookie:SharedObject;
		internal static var _GDBanner:GDBanner;
		internal static var _GDAnalytics:GDAnalytics;		
		internal static var _instance:GDApi;
		internal static var _isAir:Boolean=false;
		
		/**
		 * API enables to view Log.
		 */		
		public function get EnabledDebug():Boolean {
			return GDUtils._EnabledDebug;
		}
		public function set EnabledDebug(value:Boolean):void {
			GDUtils._EnabledDebug=value;
			return;
		}
		/**
		 * Banner time out
		 */	
		public function get BannerTimeOut():int { 
			return _BannerTimeOut; 
		};
		public function set BannerTimeOut(value:int):void { 
			_BannerTimeOut = value; 
		};
		/**
		 * Set Blocked Screen Text.
		 */	
		public function get BlockText():String { 
			return _BlockText; 
		};
		public function set BlockText(value:String):void { 
			_BlockText = value; 
		};		
		/**
		 * API Stage Width.
		 */		
		public function get apiWidth():int {
			return _apiWidth;
		}
		public function set apiWidth(value:int):void {
			_apiWidth=value;
			return;
		}
		/**
		 * API gets Session Id.
		 */	
		public function get SID():String { 
			return _SID; 
		};		
		/**
		 * API Stage Height.
		 */		
		public function get apiHeight():int {
			return _apiHeight;
		}
		public function set apiHeight(value:int):void {
			_apiHeight=value;
			return;
		}
		
		public function GDApi()
		{
			try { // try/catch is using for AIR.
				Security.allowDomain("*");
				Security.allowInsecureDomain("*");
			} catch(e) {
				_isAir = (Capabilities.playerType == "Desktop");
			}
			
			GDUtils.DebugLog("GDApi constructor.");
			_instance = this;			
			
			addEventListener(Event.ADDED_TO_STAGE,function(e:Event):void{
				if (stage==null) {
					GDUtils.DebugLog("GDApi Stage is null");				
				} else {
					GDUtils.DebugLog("GDApi Stage is created");								
				}
				_Stage = stage;				
			});
			
		}
				
		public function Log(args:Object):void 
		{			
			GDUtils.DebugLog("Log:"+args);
			
			/* Set Init Values */
			_SID = SessionId.getId();
			_GID = args.gid;
			_GUID = args.userid;
			_ROOT = args.root;
									
			/* Check Game Id */
			if(_GID.length !=32) {
				GDUtils.DebugLog("GameId is not valid.");				
				return;				
			}		
			
			/* Find Server */
			var _tGUID:Array = _GUID.toLowerCase().split("-");
			_ServerId = _tGUID.splice(5, 1);
			_GUID = _tGUID.join("-");
			_Enabled = true;

			try { // try/catch is using for AIR.
				Security.loadPolicyFile("http://"+_GUID+".s1.submityourgame.com/crossdomain.xml?gid="+args.gid+"&ver="+_ApiVersion);					
			} catch(e) {
			}
			
			/* Set Cookies */
			Cookie = SharedObject.getLocal("flashgamesubmitter");
			
			/* Check the URL is http / https */
			if(_WebRef.indexOf("http://") != 0 && _WebRef.indexOf("https://") != 0) 
			{
				// Sandbox exceptions for testing
				if(Security.sandboxType != "localWithNetwork" && Security.sandboxType != "localTrusted" && Security.sandboxType != "remote")
				{
					if (_isAir) {
						GDUtils.DebugLog("Air is detected. Passing Sandboxtype...");										
					} else {
						GDUtils.DebugLog("Sandboxtype isn't localWithNetwork or localTrusted or remote. GDApi will not run.");				
						_Enabled = false;
						return;
					}
				}
			}
			
			/* Find Url */
			_WebRef = GDUtils.FindUrl(_ROOT.loaderInfo.loaderURL);
			
			if (_WebRef != "http://localhost/") 
			{
				_isLocal = false;
			} else {
				_isLocal = true;
				GDUtils.DebugLog("API is running on localhost.");
				dispatchEvent(new Event(gdapi.GDEvent.RUNNING_LOCAL));										
			}			

			
			GDBlocker.addEventListener(gdapi.GDEvent.SITE_NOTALLOWED,onSiteBlocked);
			GDBlocker.CheckBlocker();
		
			_GDAnalytics = new GDAnalytics();
			_GDAnalytics.jsInjectAnalytics(args.gid);
			_GDAnalytics.jsSendEventGoogle('API','Init')
			
			_GDBanner = new GDBanner(_GDAnalytics);			
			_GDBanner.addEventListener(gdapi.GDEvent.BANNER_STARTED,onAdStarted)
			_GDBanner.addEventListener(gdapi.GDEvent.BANNER_CLOSED,onAdClosed)
			_GDBanner.addEventListener(gdapi.GDEvent.BANNER_RECEIVED,onAdReceived)
			_GDBanner.init({_key:"Preroll",_type:"interstitial"});			
			
			// Is there internet acceess?
			if (Security.sandboxType != "localWithFile") 
			{
					/*
					* Init Channel
					*/
					GDChannel.Init();
					
					// Log Visit
					Visit();
					GDUtils.SaveCookie("visit",GDUtils.GetCookie("visit")+1);
				
			} else {				
				GDUtils.DebugLog("There isn't internet access of the file. Please give access to your file from Flash Settings. GDApi cannot access to the GDSserver and will not work.");						
			}
			return;
			
		}
		
		internal static function Visit():void
		{
			if(!_Enabled){
				GDUtils.DebugLog(Debug_InitWarning)
				return;
			}
			
			var sendObj:Object = new Object();
			sendObj.action = "visit";
			sendObj.value = GDUtils.GetCookie("visit");
			sendObj.state = GDUtils.GetCookie("state");
			GDLogRequest.PushLog(sendObj);									
		}
		
		internal static function IncPlay():int
		{
			var play:int = GDUtils.GetCookie("play");
			play++;
			GDUtils.SaveCookie("play",play);
			return play;
		}
		
		/**
		 * Show Banner. 
		 */		
		public function ShowBanner(args:*):void 
		{
			if(!_GDBanner){
				GDUtils.DebugLog(Debug_NotSetParams)
				return;
			}
			
			if(!_Enabled){
				GDUtils.DebugLog(Debug_InitWarning)
				return;
			}
			
			if (args.test) {
				_GDBanner.ShowTestBanner();
			} else {
				_GDBanner.ReShowBanner(args);	
			}
		}
		/**
		 * Close Banner. 
		 */		
		public function CloseBanner():void 
		{
			if(!_GDBanner){
				GDUtils.DebugLog(Debug_NotSetParams)
				return;
			}
			
			if(!_Enabled){
				GDUtils.DebugLog(Debug_InitWarning)
				return;
			}
			_GDBanner.CloseBanner();
		}
		
		/**
		 * API sends how many times 'PlayGame' is called. If you invoke 'PlayGame' many times, it increases 'PlayGame' counter and sends this counter value. 
		 */		
		public function PlayGame():void 
		{
			if(!_GDBanner){
				GDUtils.DebugLog(Debug_NotSetParams)
				return;
			}
			
			
			if(!_Enabled){
				GDUtils.DebugLog(Debug_InitWarning)
				return;
			}
			var sendObj:Object = new Object();
			sendObj.action = "play";
			sendObj.value = IncPlay();
			GDLogRequest.PushLog(sendObj);		
		}
		
		/**
		 * API sends how many times 'CustomLog' that is called related to given by _key name. If you invoke 'CustomLog' many times, it increases 'CustomLog' counter and sends this counter value. 
		 */		
		public function CustomLog(_key:String):void 
		{
			if(!_GDBanner){
				GDUtils.DebugLog(Debug_NotSetParams)
				return;
			}
			
			if(!_Enabled){
				GDUtils.DebugLog(Debug_InitWarning)
				return;
			}
			
			if (_key!="play" || _key!="visit") 
			{
				var customValue:int = GDUtils.GetCookie(_key);
				if (customValue==0) {					
					customValue = 1;
					GDUtils.SaveCookie(_key,customValue);
				} 
				
				var sendObj:Object = new Object();
				sendObj.action = "custom";
				sendObj.value = new Array({key:_key, value:customValue});
				GDLogRequest.PushLog(sendObj);						
			}
		}
		
		internal static function Ping():Object
		{
			var sendObj:Object = new Object();
			sendObj.action = "ping";
			sendObj.value = "ping";
			return sendObj;
		}	
	
		/**
		 * Sets the API to use SSL-only for all communication
		 */
		public function SetSSL():void
		{
			_UseSSL = true;
			GDUtils.DebugLog("Enabled SSL requests.");
		}

		protected function onSiteBlocked(e:Event):void
		{
			GDBlocker.BlockSiteLoaded();
			dispatchEvent(new Event(gdapi.GDEvent.SITE_NOTALLOWED));
		}
		
		protected function onAdStarted(e:Event):void
		{
			dispatchEvent(e);
		}
		
		protected function onAdReceived(e:gdapi.GDEvent):void
		{
			dispatchEvent(new gd.GDEvent(gd.GDEvent.BANNER_RECEIVED,e.data));
			//_GDAnalytics.jsSendEventGoogle("Ad","Loaded");
		}
		
		protected function onAdClosed(e:Event):void
		{
			dispatchEvent(e);
			//_GDAnalytics.jsSendEventGoogle("Ad","Closed");
		}
		
	}
}