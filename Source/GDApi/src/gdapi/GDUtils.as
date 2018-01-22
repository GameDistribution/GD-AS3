package gdapi
{
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	
	internal final class GDUtils
	{
		internal static var _EnabledDebug:Boolean = false;		
		
		public function GDUtils()
		{
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
			else if(_url.indexOf("app:/") == 0)
			{
				url = getOS();
			}
			
			if(url == null  || url == "" || url == "null")
			{
				url = "http://localhost/";
			}
			
			if(url.indexOf("http://") != 0 && url.indexOf("https://") != 0)
				url = "http://localhost/";
			
			return url;
		}
		
		/**
		 * Gets OS
		 * @param
		 */
		internal static function getOS():String {
			var cp:* = Capabilities;
			var ver:String = Capabilities.version;
			var playerType:String = Capabilities.playerType;
			switch(true)
			{
				case (ver.indexOf('WIN') > -1):
				{
					return "http://win.os";
				}
				case (ver.indexOf('MAC') > -1):
				{
					return "http://mac.os";
				}
				case (ver.indexOf('IOS') > -1):
				{
					return "http://ios.os";
				}
				case (ver.indexOf('QNX') > -1):
				{
					return "http://blackberry.os"; // blackberry
				}
				case (ver.indexOf('AND') > -1):
				{					
					return "http://android.os";
				}
				default:
					
			}	
			return "http://unknown.os";
		}
		
		internal static function FindRefer():String {
			if(ExternalInterface.available)
			{
				try
				{
					return (String(ExternalInterface.call("window.location.href.toString")));
				}
				catch(s:Error)
				{
					return "null";
				}
			} else if(GDApi._isAir)
			{
				return getOS();
			}	
			
			return "null";
		}		
		
		internal static function DebugLog(...parameters):void {	
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
		
		internal static function CallJSFunction(methodFunction:String,...parameters):void {	
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(methodFunction,parameters);					
				}
				catch(s:Error)
				{
				}
			}	
			else{
				
			}
		}
		
		internal static function RegisterJSCallBackFunction(method:String,methodFunction:Function):void {	
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.addCallback(method, methodFunction);
					DebugLog(method+" RegisterJSCallBackFunction is attached.");
				}
				catch(s:Error)
				{
					DebugLog("RegisterJSCallBackFunction :"+s.message);
				}
			}
		}
		
	}
}