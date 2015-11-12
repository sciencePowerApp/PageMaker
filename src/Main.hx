package;

import haxe.ds.Vector;
import openfl.display.Sprite;
import openfl.Lib;

/**
 * ...
 * @author 
 */
class Main extends Sprite 
{

	public function new() 
	{
		super();
		var xml_Service:Xml_Service = new Xml_Service();
		var data:Vector<Xml> = xml_Service.get();
		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");
	}

}

class Xml_Service {

	
	
}