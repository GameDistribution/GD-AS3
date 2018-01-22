package gd
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.system.Security;
	import gd.json.JSONDecoder;
	
	public dynamic class GDLogger extends Sprite
	{
		/*
		 * Singleton var
		*/
		/**@private*/protected static var _instance:GDLogger;

		/*
		 * Events 
		*/
		private var _evt_AdClosed:Function = null;
		private var _evt_AdStarted:Function = null;
		private var _evt_AdReceived:Function = null;
		private var _evt_NotAllowed:Function = null;
		private var _evt_APINotLoaded:Function = null;
						
		/*
		* Properties 
		*/
		internal var _UseSSL:Boolean = false;
		internal var _EnabledDebug:Boolean = false;
		internal var _BlockText:String = "";
		
		/*
		 * Private var
		*/
		internal var _GDApi:Object;		
		internal var _args:*;		
		internal var _apiURL:String = "vcheck.submityourgame.com";
		internal var _loaded:Boolean = false;
		internal var _stageWidth:Number = 550;
		internal var _stageHeight:Number = 400;
		internal var _stage:Stage;
		internal var _isLocal:Boolean=false;
		
		/**
		 * API enables to view Log.
		 */		
		public function get EnabledDebug():Boolean {
			return _EnabledDebug;
		}
		public function set EnabledDebug(value:Boolean):void {
			_EnabledDebug=value;
			return;
		}
		
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
		 * Logger initializes the API.  You must create GDApi first before doing anything else. It is a singleton class.
		 * @param	gID			Your game id from GameDistribution
		 * @param	guid		Your game guid from GameDistribution
		 * @param	root		Should be root to detect the page
		 */		
		public function GDLogger(args:*)
		{
			try {
				Security.allowDomain("*");
				Security.allowInsecureDomain("*");
			}catch (e:Error) { 
			};			
			
			if(_instance == null) {
				_instance = this;
			} else {
				trace("GDApi: Instance Error: The GDApi class is a singleton and should only be constructed once. Use GDApi.api to access it after it has been constructed.");
				return;
			}
			
			// Pass arguments
			_args = args;
			
			/* Find Url */			
			if (FindUrl(args.root.loaderInfo.loaderURL) != "http://localhost/") 
			{
				_isLocal = false;
			} else {
				_isLocal = true;
			}
			
			try {
				var _apiVersionChecker:MediaLoader = new MediaLoader((_UseSSL ? "https://" : "http://") + _apiURL+ "/api",false);
				_apiVersionChecker.addEventListener(MediaLoaderEvent.LOADED, onLoaderComplete);
				_apiVersionChecker.addEventListener(MediaLoaderEvent.INIT, onLoaderInit);
				_apiVersionChecker.addEventListener(MediaLoaderEvent.ERROR, onLoaderError);
			} finally {
				DebugLog("Finding latest GDApi...");
			}
		}
		
		private function onLoaderComplete(event:MediaLoaderEvent):void {
			var vars:Object;
			var request:URLLoader = event.result as URLLoader;
			DebugLog('Response: '+request.data);
			
			if (request.data!=null && request.data!='') 
			{
				try {
					vars = new JSONDecoder(request.data,true).getValue();
				} catch(e:Error) {
					DebugLog('JSON Error: '+ e.message);										
				}
				
				if (vars!=null) {
					try {
						
						var apiURL:String = (_UseSSL ? "https://" : "http://") + vars.url;
						CONFIG::DEVELOPMENT
						{
							apiURL = (_UseSSL ? "https://" : "http://") + vars.urld;
						}
						DebugLog("Latest GDApi Found, Ver:"+vars.ver+" Url:"+apiURL);
						var _apiLoader:MediaLoader = new MediaLoader(apiURL);
						_apiLoader.addEventListener(MediaLoaderEvent.LOADED, onApiLoadComplete);
						_apiLoader.addEventListener(MediaLoaderEvent.ERROR, onApiLoadError);
					}
					catch (e:Error) 
					{
						DebugLog('API is Not loaded GDApi v'+vars.ver);																					
					} finally {
						DebugLog('Loading GDApi v'+vars.ver);																
					}
				}
			}
		}
		
		private function onLoaderInit(event:Event):void {
			var loader:Loader = Loader(event.target.loader);
			var info:LoaderInfo = LoaderInfo(loader.contentLoaderInfo);
			DebugLog("onLoaderInit: loaderURL=" + info.loaderURL + " url=" + info.url);
		}
		
		private function onLoaderError(event:MediaLoaderEvent):void {
			DebugLog("onLoaderError: " + event);
			e_onAPINotLoaded(new Event(GDEvent.API_NOTLOADED));
		}			

		private function onApiLoadComplete(event:MediaLoaderEvent):void {
			try
			{
				_GDApi = (event.result as LoaderInfo).content as Object;
				
				if (_GDApi!=null) {
					_loaded = true;					
					for (var vars:String in _args) {
						DebugLog("args: "+vars+" @ "+_args[vars]);
					}
					DebugLog("API is adding Child.");
					_args.root.addChild(this);
					setStage();					
					DebugLog("API is Loaded.");
				} else {
					DebugLog("API is Loaded, but it is not valid!");					
					_loaded = false;
				}
			} catch (e:Error) {
				DebugLog("API Loader: " + e.message);
				_loaded = false;
			}
			
		}
		
		/**
		 * API sends how many times 'PlayGame' is called. If you invoke 'PlayGame' many times, it increases 'PlayGame' counter and sends this counter value. 
		 */				
		public function PlayGame():void 
		{
			if (_GDApi!=null && _loaded && _GDApi.hasOwnProperty("PlayGame")) {
				_GDApi.PlayGame();
			}
		}	
		/**
		 * API sends how many times 'CustomLog' that is called related to given by _key name. If you invoke 'CustomLog' many times, it increases 'CustomLog' counter and sends this counter value. 
		 */		
		public function CustomLog(_key:String):void 
		{
			/*
			if (_GDApi!=null && _loaded && _GDApi.hasOwnProperty("CustomLog")) {
				_GDApi.CustomLog(_key);
			} */
		}		
		/**
		 * Close Banner. 
		 */		
		public function CloseBanner():void 
		{
			/*
			if (_GDApi!=null && _loaded && _GDApi.hasOwnProperty("CloseBanner")) {
				_GDApi.CloseBanner();
			}*/
		}
		/**
		 * Show Banner. 
		 */		
		public function ShowBanner(args:*):void 
		{
			if (_GDApi!=null && _loaded && _GDApi.hasOwnProperty("ShowBanner")) {
				_GDApi.ShowBanner(args);
			}
		}
		
		private function onApiLoadError(event:MediaLoaderEvent):void {
			DebugLog("onApiLoadError: " + event);
			e_onAPINotLoaded(new Event(GDEvent.API_NOTLOADED));
		}			
		
		public static function get api():GDLogger	{
			if(_instance == null) {
				trace("GDApi: Instance Error: Attempted to get instance before construction.");
				return null;
			}
			return _instance;
		}

		/**
		 * Sets the API to use SSL-only for all communication
		 */
		public function SetSSL():void
		{
			_UseSSL = true;
			DebugLog("Enabled SSL requests.");
		}
		
		private function resizeStage(e:Event):void {
			if(_loaded == false) return;
			_stageWidth = _stage.stageWidth;
			_stageHeight = _stage.stageHeight;
			if (_GDApi.hasOwnProperty("apiWidth")) {				
				_GDApi.apiWidth = _stageWidth;
				DebugLog("apiWidth is set "+_stageWidth);
			}
			if (_GDApi.hasOwnProperty("apiHeight")) {				
				_GDApi.apiHeight = _stageHeight;
				DebugLog("apiHeight is set "+_stageHeight);
			}
		}
		
		private function setStage():void {
			DebugLog("Entered setState...");
			_stage = stage;
			_stage.addEventListener(Event.RESIZE, resizeStage);
			_stageWidth = stage.stageWidth;
			_stageHeight = stage.stageHeight;
			if(_loaded){
				_GDApi.apiWidth = _stageWidth;
				_GDApi.apiHeight = _stageHeight;
				
				if (_GDApi.hasOwnProperty("EnabledDebug")) {				
					_GDApi.EnabledDebug = _EnabledDebug;
					DebugLog("EnabledDebug is set.");
				}
				if (_GDApi.hasOwnProperty("BlockText")) {				
					_GDApi.BlockText = _BlockText;
					DebugLog("BlockText is set "+_BlockText);
				}
				if (_UseSSL && _GDApi.hasOwnProperty("SetSSL")) {
					_GDApi.SetSSL();
					DebugLog("SetSSL is set.");
				}
				
				_GDApi.addEventListener(GDEvent.BANNER_CLOSED,e_onAdClosed);
				_GDApi.addEventListener(GDEvent.BANNER_STARTED,e_onAdStarted);
				_GDApi.addEventListener(GDEvent.BANNER_RECEIVED,e_onAdReceived);
				_GDApi.addEventListener(GDEvent.SITE_NOTALLOWED,e_onNotAllowed);
				if (_GDApi.hasOwnProperty("Log")) {				
					_GDApi.Log(_args);
					DebugLog("Log is set "+_args);
				}				
				_stage.addChild(_GDApi as Sprite);
			}
		}

		/** @private */ public function set onAPINotLoaded(func:Function):void { _evt_APINotLoaded = func; }
		/** @private */ public function get onAPINotLoaded():Function {return _evt_APINotLoaded;}
		private function e_onAPINotLoaded(e:Event):void {
			if(_evt_APINotLoaded != null) _evt_APINotLoaded();
			dispatchEvent(e);
		}
		
		/** @private */ public function set onAdClosed(func:Function):void { _evt_AdClosed = func; }
		/** @private */ public function get onAdClosed():Function {return _evt_AdClosed;}
		private function e_onAdClosed(e:Event):void {
			if(_evt_AdClosed != null) _evt_AdClosed();
			dispatchEvent(e);
		}
		
		/** @private */ public function set onAdStarted(func:Function):void { _evt_AdStarted = func; }
		/** @private */ public function get onAdStarted():Function {return _evt_AdStarted;}
		private function e_onAdStarted(e:Event):void {
			if(_evt_AdStarted != null) _evt_AdStarted();
			dispatchEvent(e);
		}
		
		/** @private */ public function set onAdReceived(func:Function):void { _evt_AdReceived = func; }
		/** @private */ public function get onAdReceived():Function {return _evt_AdReceived;}
		private function e_onAdReceived(e:GDEvent):void {
			if(_evt_AdReceived != null) _evt_AdReceived();
			dispatchEvent(e);
		}
		
		/** @private */ public function set onSiteNotAllowed(func:Function):void { _evt_NotAllowed = func; }
		/** @private */ public function get onSiteNotAllowed():Function {return _evt_NotAllowed;}
		private function e_onNotAllowed(e:Event):void {
			if(_evt_NotAllowed != null) _evt_NotAllowed();
			dispatchEvent(e);
		}
		
		/**
		 * Attempts to detect the page url
		 * @param	url		The callback url if page cannot be detected
		 */
		internal static function FindUrl(_url:String):String
		{
			var url:String;
			
			if(ExternalInterface.available)
			{
				try
				{
					url = String(ExternalInterface.call("window.location.href.toString"));
				}
				catch(s:Error)
				{
					url = _url;
				}
			}
			else if(_url.indexOf("http://") == 0 || _url.indexOf("https://") == 0)
			{
				url = _url;
			}
			
			if(url == null  || url == "" || url == "null")
			{
				url = "http://localhost/";
			}
			
			if(url.indexOf("http://") != 0 && url.indexOf("https://") != 0)
				url = "http://localhost/";
			
			return url;
		}
		
		internal function DebugLog(...parameters):void {	
			if (_EnabledDebug) {	
				if(ExternalInterface.available)
				{
					try
					{
						ExternalInterface.call("console.log",parameters);					
					}
					catch(s:Error)
					{
					}
				}				
				trace("GDAPI Debug @ ",parameters);
			}
		}
				
	}
}