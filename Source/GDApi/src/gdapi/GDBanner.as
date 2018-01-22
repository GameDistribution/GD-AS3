package gdapi
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	
	
	internal final class GDBanner extends EventDispatcher
	{
		internal static var _AId:String = '';
		internal static var _UId:String = '';
		internal static var _isJSInjected:Boolean=false;
	
		internal function init():void {
			GDUtils.RegisterJSCallBackFunction("jsGDO",jsGDO);			
			GDUtils.RegisterJSCallBackFunction("jsOnAdsStarted",jsOnAdsStarted);				
			GDUtils.RegisterJSCallBackFunction("jsOnAdsClosed",jsOnAdsClosed);				
			GDUtils.RegisterJSCallBackFunction("jsOnAdsError",jsOnAdsError);				
			GDUtils.RegisterJSCallBackFunction("jsOnAdsLoaded",jsOnAdsLoaded);
			jsInjectGD();			
		}	 	
		
		internal function ShowAd():void {
			GDUtils.CallJSFunction("jsShowBanner");
		}
				
		public function jsOnAdsLoaded():void{
			dispatchEvent(new Event(GDEvent.BANNER_RECEIVED));
		}
		
		public function jsOnAdsStarted():void {
			dispatchEvent(new Event(GDEvent.BANNER_STARTED));
		}
		
		public function jsOnAdsClosed():void {
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
		}
		
		public function jsOnAdsError():void {
			dispatchEvent(new Event(GDEvent.BANNER_CLOSED));
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

									fgo("]]>{GDApi._GID}<![CDATA[","]]>{GDApi._USERID}<![CDATA[");
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
		
		private function parseDomain(WebRef:String):String {
			var WebArray:Array = WebRef.replace('http://','').split('/');
			return WebArray[0];			
		}		

	}
}