package gdapi
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;

	internal final class GDBanner extends EventDispatcher
	{
		private static var BannerServerURL:String = "bn.submityourgame.com";
		private static var StatsURL:String;
		private static var urlLoader:URLLoader;
		private static var urlRequest:URLRequest = new URLRequest();
		private static var loaderContext:LoaderContext;
		//private static const dispatcher:EventDispatcher = new EventDispatcher();		
		
		internal static var _bannerWidth:int=640;
		internal static var _bannerHeight:int=480;
		internal static var _bannerTop:int=0;
		internal static var _bannerLeft:int=0;
		internal static var _BannerTimeOut:int = 50;
		internal static var _bannerText:String = '';
		internal static var _bannerActive:Boolean = false;
		internal static var _bannerBGColor:String = '000000';		
		internal static var _bannerAutoSize:Boolean=false;
		internal static var _EnableBanner:Boolean=true;
		internal static var _HtmlBanner:Boolean=false;
		internal static var _MappedId:String = '';
		internal static var _AId:String = '';
		internal static var _UId:String = '';
		internal static var _MidRoll:Boolean=false;
		internal static var _isJSInjected:Boolean=false;
		internal static var _CurrentFrameRate:Number = 0.0;		
		internal static var _AndAdUnit:String = '';
		internal static var _AdUnit:String = '';
		internal static var _isMobile:Boolean = GDUtils.getOS()=="http://android.os";
		internal static var _GDAnalytics:GDAnalytics;	
		
		private static var blankScreen:MovieClip;
		private static var bannerTimer:Timer = new Timer(1000);
		private static var midRollTimer:Timer;
		private static var loader:Loader;
		private static var waitText:TextField;
		private static var bannerConfig:XML;
		private static var _bannerTopSpace:int=0;		
		private static var _bannerBottomSpace:int=0;
		private static var loaderBar:Shape;
		internal static var SitesCounter:int = 0;
		private static var _ShowBannerTimerText:Boolean=true;
		private static var _argsBanner:*=null;
		//private static var playBTN:playButton;
		private static var GoogleAds:*;
		
		
		public function GDBanner(_GDAnalyticsObj : GDAnalytics){
			_GDAnalytics = _GDAnalyticsObj;
		}
		
		internal function init(args:*):void {
			_argsBanner = args;

			var referURL:String = GDUtils.FindRefer();			
			if (referURL!="null") {
				StatsURL = (GDApi._UseSSL ? "https://" : "http://") + GDApi._ServerId +"." + BannerServerURL + "/" + GDApi._GID + ".xml?ver="+GDApi._ApiVersion+"&url="+referURL;
				
				urlLoader = new URLLoader();
				urlLoader.addEventListener("ioError", Fail);
				urlLoader.addEventListener("networkError", Fail);
				urlLoader.addEventListener("verifyError", Fail);
				urlLoader.addEventListener("diskError", Fail);
				urlLoader.addEventListener("securityError", Fail);
				urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
				urlLoader.addEventListener("complete", Complete);				
				urlRequest.contentType = "application/x-www-form-urlencoded";
				urlRequest.url = StatsURL;
				urlRequest.method = URLRequestMethod.POST;
				try {
					urlLoader.load(urlRequest);
				} catch (e:Error) {
					dispatchEvent(new Event(GDEvent.BANNER_CLOSED));			
					GDUtils.DebugLog("showBanner error: "+e.message);				
				}			
			}
		}	 
		private function loadBanner(url:String):void {
			if (_EnableBanner) {
				/*
				var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain), (SecurityDomain.currentDomain)); // Use For Running
				context.allowCodeImport = true;
				loader = new Loader();			
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
				loader.contentLoaderInfo.addEventListener(Event.UNLOAD, onUnloadLoader);
				loader.contentLoaderInfo.addEventListener(Event.INIT, initHandler);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				loader.load(new URLRequest((GDApi._UseSSL ? "https://" : "http://") + url),context);
				GDUtils.DebugLog("Banner URL:"+(GDApi._UseSSL ? "https://" : "http://") + url);
				*/
				url = (GDApi._UseSSL ? "https://" : "http://") + url;
				urlLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, onBinaryComplete);
				urlLoader.addEventListener(Event.INIT, initHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				urlLoader.addEventListener(IOErrorEvent.NETWORK_ERROR, ioErrorHandler);
				urlLoader.addEventListener(IOErrorEvent.DISK_ERROR, ioErrorHandler);
				urlLoader.addEventListener(IOErrorEvent.VERIFY_ERROR, ioErrorHandler);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.load(new URLRequest(url));
				GDUtils.DebugLog("Banner URL:"+url);
				
				_bannerActive = true;
			} else {
				_bannerActive = false;				
			}
		}
		
		public function onBinaryComplete(event:Event):void {
			loader = new Loader();
			loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain );
			loaderContext.allowCodeImport = true;		
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.loadBytes(urlLoader.data,loaderContext);
		}

		
		protected function onUnloadLoader(event:Event):void
		{			
			loader = null;
		}
		
		protected function TimerComplete(event:TimerEvent):void
		{
			_bannerActive = false;
			//GDUtils.DebugLog("_root.stage.numChildren:"+GDApi._ROOT.stage.numChildren);			
			try {
				if (GoogleAds!=null && GoogleAds.destroy!=null) {
					GoogleAds.destroy();
				}				
				loader.unloadAndStop(true);			
								
				if (blankScreen!=null) {
					GDApi._ROOT.stage.removeChild(blankScreen);
					blankScreen = null;
				}
				GDUtils.DebugLog("Removed : banner stage");							
				
			} catch (e:Error) {
				GDUtils.DebugLog('Banner Error: '+e.message);	
			}
			//GDUtils.DebugLog("_root.stage.numChildren:"+GDApi._ROOT.stage.numChildren);			
			GDUtils.DebugLog("Banner removed.");
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
			_MidRoll = false;			
		}
		
		protected function TimerHandler(event:TimerEvent):void
		{
			//GDUtils.DebugLog("Banner time out: "+bannerTimer.currentCount.toString() );
		}
		
		private function onLoaderComplete(event:Event):void {
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;	
			//GDUtils.DebugLog("getQualifiedClassName: " + getQualifiedClassName( event.target.content ) );
			
			if (getQualifiedClassName( event.target.content ) == "GoogleAds") {
				GoogleAds=event.target.content;
				
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("contentId")) {
					GoogleAds.contentId = GDApi._GID;
				}
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("bannerArgs")) {
					GoogleAds.bannerArgs = _argsBanner;
				}
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("mappedId") && _MappedId!="") {
					GoogleAds.mappedId = _MappedId;					
				}
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("fg_aid") && _AId!="") {
					GoogleAds.fg_aid = _AId;					
				}
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("fg_uid") && _UId!="") {
					GoogleAds.fg_uid = _UId;					
				}				
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("fg_adunit") && _AndAdUnit!="") {
					GoogleAds.fg_adunit = _AndAdUnit;					
				}				
				if (GoogleAds!=null && GoogleAds.hasOwnProperty("fg_adu") && _AdUnit!="") {
					GoogleAds.fg_adu = _AdUnit;					
				}
				
				if (_bannerAutoSize) {			
					GoogleAds.bandBGLoading.x = 0;
					GoogleAds.bandBGLoading.y = 0;	
					GoogleAds._bannerWidth=GDApi._apiWidth;	
					GoogleAds._bannerHeight=GDApi._apiHeight;	
				} else {
					GoogleAds.bandBGLoading.x = _bannerLeft;
					GoogleAds.bandBGLoading.y = _bannerTop;	
					GoogleAds._bannerWidth=_bannerWidth;	
					GoogleAds._bannerHeight=_bannerHeight;					
				}
				
				GoogleAds.addEventListener("onAFGClosed",onAFGClosed);			
				GoogleAds.addEventListener("onAFGShowed",onAFGShowed);	
				GoogleAds.addEventListener("onAFGManagerLoaded",onAFGManagerLoaded);					
				GoogleAds.addEventListener(GDEvent.BANNER_RECEIVED,onAFGReceived);					
				_ShowBannerTimerText = false;
			} else {
				_ShowBannerTimerText = true;				
			}
			
			drawBackground(loaderInfo.content);	
			blankScreen.addChildAt(GoogleAds.bandBGLoading,blankScreen.numChildren-1);
			//dispatchEvent(new Event(GDEvent.BANNER_STARTED));
		}

		private function onAFGReceived(e:GDEvent):void
		{
			e.target.removeEventListener(GDEvent.BANNER_RECEIVED,onAFGReceived);
			GDUtils.DebugLog("AFG Received: "+e.data.dimensions);
			
			if (e.data.remainingTime>_BannerTimeOut) {
				bannerTimer.repeatCount = e.data.remainingTime+5;				
			}
			dispatchEvent(e);		
		}
		
		private function onAFGManagerLoaded(e:Event):void
		{
			e.target.removeEventListener("onAFGManagerLoaded",onAFGManagerLoaded);
			GDUtils.DebugLog("AFG Time: "+GoogleAds._remainingTime);
			
			/*
			if (GoogleAds._remainingTime>-1) {
				playBTN.visible=false;
				bannerTimer.repeatCount = GoogleAds._remainingTime+10;
				bannerTimer.reset();
				bannerTimer.start();
			}
			*/
			
			blankScreen.visible = true;			
		}
		
		private function onAFGShowed(e:Event):void
		{			
			e.target.removeEventListener("onAFGShowed",onAFGShowed);
			GDUtils.DebugLog("AFG Showed");					
		}
		
		private function onAFGClosed(e:Event):void
		{			
			e.currentTarget.removeEventListener("onAFGClosed",onAFGClosed);
			CloseBanner();
			GDUtils.DebugLog("AFG Closed");
		}
		
		private function initHandler(event:Event):void {
			var loader:Loader = Loader(event.target.loader);
			var info:LoaderInfo = LoaderInfo(loader.contentLoaderInfo);
			GDUtils.DebugLog("Banner initHandler: loaderURL=" + info.loaderURL + " url=" + info.url);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			GDUtils.DebugLog("Banner ioErrorHandler: " + event);
			_bannerActive = false;
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));			
		}				
		
		private function drawBackground(banner:DisplayObject):void {
			
			GDUtils.DebugLog("Drawing banner background.");		
						
			Mouse.show();
			
			blankScreen = new MovieClip();
			blankScreen.opaqueBackground = uint("0x"+_bannerBGColor);
			blankScreen.alpha = 1;			
			blankScreen.visible = false;
					
			var rectangle:Shape = new Shape; // initializing the variable named rectangle
			rectangle.graphics.beginFill(uint("0x"+_bannerBGColor)); 
			rectangle.graphics.drawRect(0, 0, GDApi._apiWidth,GDApi._apiHeight); // (x spacing, y spacing, width, height)
			rectangle.graphics.endFill();				
			blankScreen.addChild(rectangle);
			
			GDApi._ROOT.addEventListener(Event.RESIZE, function(e:Event):void{
				rectangle.graphics.drawRect(0, 0, GDApi._apiWidth,GDApi._apiHeight); 				
			});
									
			try {
				_bannerLeft = (GDApi._ROOT.stage.stageWidth-_bannerWidth)/2;
				_bannerTop = (GDApi._ROOT.stage.stageHeight-_bannerHeight-_bannerTopSpace-_bannerBottomSpace)/2;
				
				if (_bannerAutoSize) {			
					banner.x = _bannerLeft;
					banner.y = _bannerTopSpace;
					banner.width = GDApi._ROOT.stage.stageWidth; //-5;
					banner.height = GDApi._ROOT.stage.stageHeight-_bannerTopSpace-_bannerBottomSpace;				
				} else {
					banner.x = _bannerLeft;
					banner.y = _bannerTop+_bannerTopSpace;
					banner.width = _bannerWidth;
					banner.height = _bannerHeight;				
				}				
				
				blankScreen.addChild(banner);
			} catch (e:Error) {
						
			}
									
			bannerTimer.repeatCount = _BannerTimeOut;
			bannerTimer.addEventListener(TimerEvent.TIMER, TimerHandler);
			bannerTimer.addEventListener(TimerEvent.TIMER_COMPLETE, TimerComplete);
			bannerTimer.reset();
			bannerTimer.start();						
			
			// Add SkipButton into Player Canvas
			/*
			playBTN = new playButton();
			playBTN.x=10;
			playBTN.y=GDApi._apiHeight-playBTN.height-10;						
			playBTN.playBG.x+=3;
			playBTN.visible=true;
			blankScreen.addChild(playBTN);
			
			var minuteTimer:Timer = new Timer(1000,15); 
			minuteTimer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void  
			{ 
				playBTN.playBG.x += int(playBTN.playBG.width/(event.target as Timer).repeatCount);
			}); 
			minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {
				playBTN.playBG.x = 0;
				playBTN.addEventListener(MouseEvent.CLICK, function():void {
					GDUtils.DebugLog("PlayButton Clicked");
					CloseBanner();
				});			
			}); 
			
			// starts the timer ticking 
			minuteTimer.start();			
			*/
			
			GDApi._ROOT.stage.addChild(blankScreen);			
		}		
				
		private function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			GDUtils.DebugLog('Response: '+request.data);
			
			XML.ignoreWhitespace = true; 
			bannerConfig = new XML(request.data);
			
			var showAfterTime:int = 0;
			if (bannerConfig!=null && String(bannerConfig.cfg.f)!="false" && String(bannerConfig.row[0])!=null && String(bannerConfig.row[0].sat)!=null) {
				showAfterTime=int(bannerConfig.row[0].sat);
				if (showAfterTime>0) {
					midRollTimer = new Timer(showAfterTime*60000);
					midRollTimer.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void {
						_MidRoll=true;						
					});
					midRollTimer.start();
				} else {
					_MidRoll=false;
				}
			}
				
			ReShowBanner(_argsBanner,true);			
		}	
		
		internal function ShowTestBanner():void {
			GDUtils.DebugLog("Trying to show test banner...");
			dispatchEvent(new Event(GDEvent.BANNER_STARTED));				
			if (loader) {
				loader.unloadAndStop(true);
			}
			_bannerWidth=300;
			_bannerHeight=250;
			_bannerAutoSize=false;
			loadBanner("www.gamedistribution.com/swf/testbanner.swf");
		}
		
		internal function ReShowBanner(args:*=null,isPreRoll:Boolean=false):void {
			try {
				_argsBanner = args;
				dispatchEvent(new Event(GDEvent.BANNER_STARTED));
				// To prevent second time showing banner
				if (!_bannerActive && bannerConfig!=null) {
					if (String(bannerConfig.cfg.f)=='false') {			
						dispatchEvent(new Event(GDEvent.BANNER_CLOSED));	
					} else {	
						if (!isPreRoll && _isMobile) {
							_MidRoll = true;
						}
						
						 // Read Banner Config from XML
						if ( (isPreRoll && String(bannerConfig.row[0].pre)=='1') || _MidRoll) {
							//_MidRoll = false;
							GDUtils.DebugLog("Midroll Banner State: "+_MidRoll);
							_bannerText = String(bannerConfig.row[0].bgt);
							_bannerBGColor = String(bannerConfig.row[0].bgc);
							_bannerWidth = int(bannerConfig.row[0].wid);
							_bannerHeight = int(bannerConfig.row[0].hei);
							_BannerTimeOut = int(bannerConfig.row[0].tim);
							_bannerAutoSize = (bannerConfig.row[0].aut=='1');
							_EnableBanner = (bannerConfig.row[0].act=='1');						
							_HtmlBanner = (bannerConfig.row[0].htmlbanner=='1');						
							_MappedId = String(bannerConfig.row[0].mappedid);						
							_AId = String(bannerConfig.row[0].aid);						
							_UId = String(bannerConfig.row[0].uid);		
							_AndAdUnit = String(bannerConfig.row[0].andadu);
							_AdUnit = String(bannerConfig.row[0].adu);
							
							if (_EnableBanner && bannerConfig.row[1]) {
								for (SitesCounter=0; SitesCounter < bannerConfig.row[1].b.length(); SitesCounter++) {
									if (parseDomain(GDApi._WebRef)==String(bannerConfig.row[1].b[SitesCounter])) {
										_EnableBanner = false;
									}
								}						
							}						
							if (!_EnableBanner) {
								dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
							}
							
							//getting ads from html
							GDUtils.RegisterJSCallBackFunction("jsGDO",jsGDO);
							GDUtils.RegisterJSCallBackFunction("jsPauseGame",jsPauseGame);
							GDUtils.RegisterJSCallBackFunction("jsResumeGame",jsResumeGame);				
							GDUtils.RegisterJSCallBackFunction("jsOnAdsStarted",jsOnAdsStarted);				
							GDUtils.RegisterJSCallBackFunction("jsOnAdsClosed",jsOnAdsClosed);				
							GDUtils.RegisterJSCallBackFunction("jsOnAdsError",jsOnAdsError);				
							GDUtils.RegisterJSCallBackFunction("jsOnAdsReady",jsOnAdsReady);
							GDUtils.RegisterJSCallBackFunction("jsOnAdsLoaded",jsOnAdsLoaded);
							jsInjectGD();
							
							if (isPreRoll) {
								
								var minuteTimer:Timer = new Timer(120*1000,1); // 2min delay 
								minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {	
									GDUtils.CallJSFunction("jsShowBanner");	
									_GDAnalytics.jsSendEventGoogle("Ad","Requested Preroll");												
								}); 		
								minuteTimer.start(); 						
								
							}	
							else{										
								if(_MidRoll){								
									GDUtils.CallJSFunction("jsShowBanner");	
									_GDAnalytics.jsSendEventGoogle("Ad","Requested Midroll");
									_MidRoll = false;
								}							
							}
							
													
							// getting ads from flash	
							/*
							else {
								// Load Banner and Show	
								if (isPreRoll && String(bannerConfig.row[0].pre)=='1') { // delay 2min for preroll
									
									var minuteTimer2:Timer = new Timer(120*1000,1); // 2min delay 
									minuteTimer2.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {					
										loadBanner(String(bannerConfig.row[0].url));	
										_GDAnalytics.jsSendEventGoogle("Ad","Requested Preroll");	
									}); 		
									minuteTimer2.start(); 										
								} else {
									loadBanner(String(bannerConfig.row[0].url));	
									_GDAnalytics.jsSendEventGoogle("Ad","Requested Midroll");
								}
							}	*/			
							
							
						} else {
							dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
							GDUtils.DebugLog("Midroll Banner State: "+_MidRoll);							
						}
					}			
				} else {
					dispatchEvent(new Event(GDEvent.BANNER_CLOSED));				
				}
			} catch (e:Error) {
				_bannerActive = false;
				dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
				GDUtils.DebugLog("Banner XML error: "+e.message);
			}
		}
			
		public function jsPauseGame():String {
			try {
				_CurrentFrameRate = GDApi._Stage.frameRate;
				GDApi._Stage.frameRate=0.01;
				SoundMixer.soundTransform = new SoundTransform(0);
				
				_GDAnalytics.jsSendEventGoogle("Game","Paused");
			} catch (e:Error) {
				GDUtils.DebugLog("jsPauseGame: "+e.getStackTrace());				
			}
			return "{frameRate:\""+GDApi._Stage.frameRate+"\"}";			
		}
		
		public function jsResumeGame():String {
			GDApi._Stage.frameRate=_CurrentFrameRate;
			SoundMixer.soundTransform = new SoundTransform(1);
			_GDAnalytics.jsSendEventGoogle("Game","Resumed");
			return "{frameRate:\""+GDApi._Stage.frameRate+"\"}";			
		}		
		public function jsOnAdsLoaded(contentType:String):void{
			_GDAnalytics.jsSendEventGoogle("Ad","Loaded: "+contentType);
			dispatchEvent(new Event(GDEvent.BANNER_RECEIVED));
		}
		
		public function jsOnAdsStarted():void {
			//dispatchEvent(new Event(GDEvent.BANNER_STARTED));
		}
		
		public function jsOnAdsClosed():void {
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
		}
		
		public function jsOnAdsError():void {
			_GDAnalytics.jsSendEventGoogle("Ad","Error");
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
		}
		
		public function jsOnAdsReady():void {
			if (GDBanner._EnableBanner) {
				//GDUtils.CallJSFunction("jsShowBanner");
			}
		}
		
		public function jsGDO():String {
			return "{GDApi:\""+GDApi._ApiVersion+"\",GUID:\""+GDApi._GUID+"\",GID:\""+GDApi._GID+"\"}";
		}
		
		internal function jsInjectGD():Boolean {
			//return false;		
			if(ExternalInterface.available)
			{
				var today:Date = new Date();		
				try
				{					
					var script_js:XML =						
						<script>
						<![CDATA[
							(function()
							{
								(function(i,s,o,g,r,a,m)
									{
										i['FamobiGameObject']=r;
										i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)};
										i[r].l=1*new Date();
										a=s.createElement(o);
										m=s.getElementsByTagName(o)[0];
										a.async=1;
										a.src=g;
										m.parentNode.insertBefore(a,m);
									})(window,document,'script','http://vcheck.submityourgame.com/js/fgo.min.js','fgo');

									fgo("]]>{GDApi._GUID}<![CDATA[","]]>{_UId}<![CDATA[","]]>{_AId}<![CDATA[");
							})
						]]>						
						</script>;						
					ExternalInterface.call(script_js);
					_isJSInjected = true;
					GDUtils.DebugLog('jsInjectGD: true');
					return true;
				}
				catch(s:Error)
				{
					GDUtils.DebugLog('jsInjectGD: false');
					return false;
				}
			}	
			
			return false;
		}		
		internal function CloseBanner():void {
			if (GoogleAds!=null && GoogleAds.destroy!=null) {
				GoogleAds.destroy();
			}
			bannerTimer.stop();
			TimerComplete(null);
		}		
		
		private function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			GDUtils.DebugLog('Fail: '+e+' : '+request.data);
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));			
		}
		
		private function HTTPStatusIgnore(e:Event):void
		{
		}	
		private function parseDomain(WebRef:String):String {
			var WebArray:Array = WebRef.replace('http://','').split('/');
			return WebArray[0];			
		}		
		
		/*
		Custom Event Listener for Static functions
		*/	
		/*
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		public function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}
		public function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}	
		*/
	}
}