package gdapi
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

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
		
		
		/**
		 * Gets a cookie value
		 * @param	key		The key (views, plays)
		 */
		internal static function GetCookie(key:String):int
		{
			if(GDApi.Cookie.data[key+"_"+GDApi._GID] == undefined)
			{
				return 1;
			}
			else
			{
				return int(GDApi.Cookie.data[key+"_"+GDApi._GID]);
			}
		}
		
		/**
		 * Saves a cookie value
		 * @param	key		The key (views, plays)
		 * @param	value 	The value
		 */
		internal static function SaveCookie(key:String, value:*):void
		{			
			
			GDApi.Cookie.data[key+"_"+GDApi._GID] = value.toString();
			
			try
			{
				GDApi.Cookie.flush();
			}
			catch(s:Error)
			{
				
			}
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
		
		internal static function createText(_text:String,_width:int,_x:int,_y:int,_size:int):TextField
		{
			var myTextField:TextField = new TextField();  				
			
			//myTextField.text = _text;
			myTextField.htmlText = _text;
			myTextField.width = _width;  
			myTextField.x = _x;  
			myTextField.y = _y;  
			
			myTextField.selectable = false;  
			myTextField.border = false;  
			
			myTextField.autoSize = TextFieldAutoSize.LEFT;  
			myTextField.wordWrap = true;
			
			var myFormat:TextFormat = new TextFormat();  
			myFormat.color = 0xFFFFFF;   
			myFormat.size = _size;  
			myFormat.italic = false; 
			myFormat.font = "Verdana";
			myTextField.setTextFormat(myFormat);  							
			return myTextField;
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