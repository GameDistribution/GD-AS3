package gdapi
{
	import flash.events.Event;
	
	public final class GDEvent extends Event
	{
		public static const SITE_NOTALLOWED: String = "onSiteNotAllowed";		
		public static const RUNNING_LOCAL: String = "onRunningLocal";		
		public static const BANNER_CLOSED: String = "onBannerClosed";		
		public static const BANNER_STARTED: String = "onBannerStarted";		
		public static const BANNER_RECEIVED: String = "onBannerReceived";		
		public static const API_NOTLOADED: String = "onAPINotLoaded";		
		public var data: Object;
		
		public function GDEvent(type:String, data: Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		override public function clone():Event
		{
			return new GDEvent (type, data, bubbles, cancelable);
		}
	}
}
