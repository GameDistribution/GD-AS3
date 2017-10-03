package gdapi
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Security;	
	
	internal final class GDBlocker
	{
		private static var BlockerServerURL:String = "bl.submityourgame.com";
		private static var StatsURL:String;
		
		private static var urlLoader:URLLoader = new URLLoader();
		private static var urlRequest:URLRequest = new URLRequest();
		
		public static var SitesCounter:int = 0;
		public static var SiteBlocked:Boolean=false;
		
		private static const dispatcher:EventDispatcher = new EventDispatcher();		
		
		internal static function CheckBlocker():void
		{
			StatsURL = (GDApi._UseSSL ? "https://" : "http://") + GDApi._ServerId +"." + BlockerServerURL + "/" + GDApi._GID + ".xml";
			
			urlLoader.addEventListener("ioError", Fail);
			urlLoader.addEventListener("networkError", Fail);
			urlLoader.addEventListener("verifyError", Fail);
			urlLoader.addEventListener("diskError", Fail);
			urlLoader.addEventListener("securityError", Fail);
			urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
			urlLoader.addEventListener("complete", Complete);
			
			urlRequest.contentType = "application/x-www-form-urlencoded";
			urlRequest.url = StatsURL;
			urlRequest.method = URLRequestMethod.GET;
			
			try {
				urlLoader.load(urlRequest);
			} catch (e:Error) {
				GDUtils.DebugLog("CheckBlocker error: "+e.message);
			}
			
		}			
		
		private static function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			GDUtils.DebugLog('Response: '+request.data);
			
			XML.ignoreWhitespace = true; 
			var blockedSites:XML = new XML(request.data);
			
			if (String(blockedSites.row.f)=='false') {			
				SiteBlocked = false;
			} else {
				try {				
					if (blockedSites.row) {
						for (SitesCounter=0; SitesCounter < blockedSites.row.length(); SitesCounter++) {
							if (parseDomain(GDApi._WebRef)==String(blockedSites.row.b[SitesCounter])) {
								SiteBlocked = true;
								dispatchEvent(new Event(GDEvent.SITE_NOTALLOWED));
								return;
							}
						}
					} else {
						SiteBlocked = false;					
					}
				} catch (e:Error) {
					SiteBlocked = false;
					GDUtils.DebugLog("Block XML error: "+e.message);
				}				
			}
		}	
			
		private static function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			GDUtils.DebugLog('Fail: '+e+' : '+request.data);
		}
		
		private static function HTTPStatusIgnore(e:Event):void
		{
		}	
		
		
		/**
		 * Checks BlockSite XML is Loaded
		 * @param	e		Event
		 */
		internal static function BlockSiteLoaded():void {
			
			if (SiteBlocked) {
				GDApi._Enabled = false;
				GDUtils.DebugLog("Site is blocked!");		
				
				var blankScreen:MovieClip= new MovieClip();
				blankScreen.opaqueBackground = 0x000000;
				blankScreen.alpha = 1;			
				
				var rectangle:Shape = new Shape; // initializing the variable named rectangle
				rectangle.graphics.beginFill(0x000000); 
				rectangle.graphics.drawRect(0, 0, GDApi._ROOT.stage.stageWidth,GDApi._ROOT.stage.stageHeight); // (x spacing, y spacing, width, height)
				rectangle.graphics.endFill();	
				
				blankScreen.addChild(rectangle);
				
				blankScreen.addChild(GDUtils.createText("UNAUTHORIZED GAME!",400,50,50,32));
				blankScreen.addChild(GDUtils.createText("This site blocked outgoing links in this game and game will not work as it should. Please search for this game on your favorite search engine."+(GDApi._BlockText!=""?"\r\n"+GDApi._BlockText:""),400,50,100,24) );
				
				GDApi._ROOT.stage.addChildAt(blankScreen, GDApi._ROOT.stage.numChildren);
			} else {
				// Check exceptions for external open url
				GDUtils.DebugLog("Site is allowed.");	
			}
		}
		
		private static function parseDomain(WebRef:String):String {
			var WebArray:Array = WebRef.replace('http://','').split('/');
			return String(WebArray[0]);			
		}
		
		/*
		Custom Event Listener for Static functions
		*/
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		public static function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}
		public static function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}		
	}
}