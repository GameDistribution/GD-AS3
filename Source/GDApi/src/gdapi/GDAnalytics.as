package gdapi
{
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	import flash.utils.setTimeout;

	internal final class GDAnalytics
	{
		internal static var _isAnalyticsJSInjected:Boolean=false;
		internal static var _gameId:String;
	 // 'UA-102700627-1'; // test account
	 // 'UA-102601800-1' // live account		
		internal function jsSendEventGoogle(eventCategory:String,eventAction:String):void {
			if (_isAnalyticsJSInjected) {				
				GDUtils.CallJSFunction("document.sendEventToGoogleAnalytics",eventCategory,eventAction,_gameId);			
			}
		}			
		internal function jsInjectAnalytics(gameid:String):Boolean {
			//return false;		
			_gameId = gameid;
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
						   		 (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
						                    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
						                m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
						            })(window,document,'script','https://www.google-analytics.com/analytics.js','_gd_ga');					
									
						            _gd_ga('create', 'UA-102601800-1', 'auto');
									document['sendEventToGoogleAnalytics'] = function(params){
										_gd_ga('send',{ 
												hitType: 'event',
								                eventCategory: params[0],
								                eventAction: params[1],
								                eventLabel: params[2]
										 })
									};
						            _gd_ga('send', 'pageview');			

						    		var s = document.createElement("script");
						            s.innerHTML = "var DS_OPTIONS={id: 'GAMEDISTRIBUTION',success: function(id) {_gd_ga('set', 'userId', id); _gd_ga('set', 'dimension1', id);}}";
						            document.head.appendChild(s);
						
						            (function(window, document, element, source) {
						                var ds = document.createElement(element),
						                    m = document.getElementsByTagName(element)[0];
						                ds.type = 'text/javascript';
						                ds.async = true;
						                ds.src = source;
       								 m.parentNode.insertBefore(ds, m)						
								 })
							]]>						
						</script>;		
					
					ExternalInterface.call(script_js);
					_isAnalyticsJSInjected = true;
					GDUtils.DebugLog('jsInjectAnalytics: true');
					return true;
				}
				catch(s:Error)
				{
					GDUtils.DebugLog('jsInjectAnalytics: false');
					return false;
				}
			}	
			
			return false;
		}		
		
	}
}