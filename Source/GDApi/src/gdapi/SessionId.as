package gdapi
{
	import flash.system.Capabilities;

	internal final class SessionId
	{
		private static var counter:Number = 0;

		public function SessionId()
		{
		}
		
		internal static function getId():String
		{
			var dt:Date = new Date();
			var sid1:Number = dt.getTime();
			var sid2:Number = Math.random() * Number.MAX_VALUE;
			var sid3:String = Capabilities.serverString;
			var src:String = sid1 + sid3 + sid2 + counter++;
			return Encoders.MD5(src);
			
		}
	}
}