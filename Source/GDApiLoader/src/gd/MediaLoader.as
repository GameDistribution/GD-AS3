package gd
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	internal final class MediaLoader extends EventDispatcher
	{
		private	var _loader:Loader = new Loader();
		private	var _urlloader:URLLoader = new URLLoader();
		private var _loaderContext:LoaderContext;
		
		public function MediaLoader(uri:String,useLoaderContext:Boolean=true)
		{			
			load(uri,useLoaderContext);
		}

		private function load(uri:String,useLoaderContext:Boolean):void {		
			try {
				if (!useLoaderContext) {
					_urlloader.addEventListener(Event.COMPLETE, onComplete);
					_urlloader.addEventListener(Event.INIT, onInit);
					_urlloader.addEventListener(IOErrorEvent.IO_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.NETWORK_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.DISK_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.VERIFY_ERROR, onError);
					//_urlloader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPError);
					_urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
					var _urlRequest:URLRequest = new URLRequest();
					_urlRequest.contentType = "application/x-www-form-urlencoded";
					_urlRequest.url = uri;
					_urlRequest.method = URLRequestMethod.GET;	
					_urlloader.load(_urlRequest);
				} else {
					/*
					_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
					_loader.contentLoaderInfo.addEventListener(Event.INIT, onInit);
					_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
					_loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onError);
					_loader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, onError);
					_loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, onError);
					_loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPError);
					_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
					_loaderContext = new LoaderContext(false, (GDLogger.api._isLocal?null:ApplicationDomain.currentDomain), (GDLogger.api._isLocal?null:SecurityDomain.currentDomain) );
					_loaderContext.allowCodeImport = true;					
					_loader.load(new URLRequest(uri), _loaderContext);	
					
					*/
					_urlloader.addEventListener(Event.COMPLETE, onBinaryComplete);
					_urlloader.addEventListener(Event.INIT, onInit);
					_urlloader.addEventListener(IOErrorEvent.IO_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.NETWORK_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.DISK_ERROR, onError);
					_urlloader.addEventListener(IOErrorEvent.VERIFY_ERROR, onError);
					_urlloader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPError);
					_urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
					_urlloader.dataFormat = URLLoaderDataFormat.BINARY;
					_urlloader.load(new URLRequest(uri));
					
					
				}
			} catch (e:Error) {			
			}
		}
		
		public function onBinaryComplete(event:Event):void {
			_loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain );
			_loaderContext.allowCodeImport = true;		
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onContextLoaded);
			_loader.loadBytes(_urlloader.data,_loaderContext);
		}
		
		public function onContextLoaded(event:Event):void {
			dispatchEvent(new MediaLoaderEvent(MediaLoaderEvent.LOADED,event.currentTarget));			
		}
		
		public function onComplete(event:Event):void {
			dispatchEvent(new MediaLoaderEvent(MediaLoaderEvent.LOADED,event.currentTarget));
		}
		
		public function onInit(event:Event):void {
			dispatchEvent(new MediaLoaderEvent(MediaLoaderEvent.INIT,event));
		}
		
		public function onError(event:Event):void {
			event.preventDefault();
			event.stopImmediatePropagation();									
			dispatchEvent(new MediaLoaderEvent(MediaLoaderEvent.ERROR,event));
		}
		
		public function onHTTPError(event:Event):void {
			if (event is HTTPStatusEvent && (event as HTTPStatusEvent).status!=200) {
				event.preventDefault();
				event.stopImmediatePropagation();									
				dispatchEvent(new MediaLoaderEvent(MediaLoaderEvent.ERROR,event));
			}
		}		
	}
}