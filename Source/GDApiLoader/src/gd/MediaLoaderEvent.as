package gd
{
	import flash.events.Event;

	internal final class MediaLoaderEvent extends Event
	{
		public static var LOADED:String = "onMediaLoaded";
		public static var ERROR:String = "onMediaError";
		public static var INIT:String = "onMediaInit";

		public var result:Object;
		
		public function MediaLoaderEvent(type:String, result:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.result = result;			
		}
		override public function clone():Event
		{
			return new MediaLoaderEvent(type, result, bubbles, cancelable);
		}
	}
}