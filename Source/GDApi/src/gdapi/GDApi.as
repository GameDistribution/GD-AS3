package gdapi
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.system.Security;
	
	[SWF(width='540',height='440',frameRate='30',backgroundColor='0x000000')]
	public dynamic class GDApi extends Sprite
	{		
		/*
		* Properties 
		*/
		internal static var _UseSSL:Boolean = false;
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
		internal static var _GDBanner:GDBanner;
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
		 * API gets Session Id.
		 */	
		public function get SID():String { 
			return _SID; 
		};		
		
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
			
		}
				
		public function Log(args:Object):void 
		{			
			GDUtils.DebugLog("Log:"+args);			
			/* Set Init Values */
			_SID = SessionId.getId();
			_GID = args.gid;
			_GUID = args.userid;
			_USERID = args.userid;
			_ROOT = args.root;
									
			/* Check Game Id */
			if(_GID.length !=32) {
				GDUtils.DebugLog("GameId is not valid.");	
				onApiNotLoaded();
				return;				
			}		
			
			/* Find Server */
			var _tGUID:Array = _GUID.toLowerCase().split("-");
			_ServerId = _tGUID.splice(5, 1);
			_GUID = _tGUID.join("-");
			_Enabled = true;
			
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
						onApiNotLoaded();
						return;
					}
				}
			}
		
			_GDBanner = new GDBanner();			
			_GDBanner.addEventListener(GDEvent.BANNER_STARTED,onAdStarted);
			_GDBanner.addEventListener(GDEvent.BANNER_CLOSED,onAdClosed);
			_GDBanner.addEventListener(GDEvent.BANNER_RECEIVED,onAdReceived);
			_GDBanner.init();			
						
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
			
			_GDBanner.ShowAd();	

		}
		/**
		 * Close Banner. 
		 */		
		public function CloseBanner():void 
		{
		
		}
		
		/**
		 * Sets the API to use SSL-only for all communication
		 */
		public function SetSSL():void
		{
			_UseSSL = true;
			GDUtils.DebugLog("Enabled SSL requests.");
		}
		
		protected function onApiNotLoaded():void
		{
			dispatchEvent(new Event (GDEvent.API_NOTLOADED));
		}
		
		protected function onAdStarted(e:GDEvent):void
		{
			dispatchEvent(new Event (GDEvent.BANNER_STARTED));
			GDUtils.CallJSFunction("console.log('FLASH banner started.')");
		}
		
		protected function onAdReceived(e:GDEvent):void
		{
			dispatchEvent(new Event (GDEvent.BANNER_RECEIVED,e.data));
		}
		
		protected function onAdClosed(e:GDEvent):void
		{
			dispatchEvent(new Event (GDEvent.BANNER_CLOSED));
		}
		
	}
}