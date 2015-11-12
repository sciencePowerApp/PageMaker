package;

import haxe.ds.Vector;
import openfl.Assets;
import openfl.display.Sprite;


/**
 * ...
 * @author 
 */
class Main extends Sprite 
{

	public function new() 
	{
		super();
		//must be in assets as embedded 
		var xml_Service:Xml_Service = new Xml_Service("assets/xml");
		var dict:Map<String,Xml> = xml_Service.get();
		
		
		
		
		var pages:Map<String,PageInfo> = new Map<String,PageInfo>();
		
		for (key in dict.keys()) {
			expandQs(dict[key]);
			addPages(key, pages, dict[key]);
		}
		
		var checker:Checker = new Checker(pages);
	}
	
	function addPages(filename:String, pages:Map<String,PageInfo>, xml:Xml)
	{
		var pageNam:String;
		for (child in xml.elements()) {
			pageNam = child.nodeName;
			if (pages.exists(pageNam)) throw "more than one page with the same name of: " + pageNam;
			pages[pageNam] = new PageInfo(filename, pageNam, child);
		}	
	}
	
	function expandQs(xml:Xml) {
		var type:String;
		for (child in xml.elements()) {
			if (child.exists('type')) {
				type = child.get('type');
				child.remove('type');
				switch(type) {
					case 'question':
						pageToQuestion(child);
				}
					
				
				
			}
		}
	}
	
	function pageToQuestion(child:Xml) {
		var xml:Xml = Xml.createElement('question');
		var val:String;
		for (attrib in child.attributes()) {
			val = child.get(attrib);
			xml.set(attrib, val);
			child.remove(attrib);
		}
		val = child.firstChild().nodeValue;
		child.firstChild().nodeValue = '';
		child.addChild(xml);
		
	}
	
	
	

}

enum PermittedTypes{
	button;
	calculation;
	input;
	question;
	text;	
}

class PageInfo {
	public var fileFrom:String;
	public var xml:Xml;
	public var name:String;
	public static var legalName:EReg = ~/[a - zA - Z_][a - zA - Z0 - 9_]*/ ;
	public var variables:Array<String> = new Array<String>();
	
	private var permittedElements:Map<String,Array<Xml>>;
	
	
	public function new(fileFrom:String, name:String, xml:Xml) {
		this.fileFrom = fileFrom;
		this.name = name;
		this.xml = xml;
	}
	
	public function checkButtons(pages:Map<String, PageInfo>) 
	{
		var goto:String;
		for (button in permittedElements['button']) {
			if(button.exists('goto') == true){
			goto = button.get('goto');
			
				if (goto.length > 0) {
					if (pages.exists(goto) == false) err("A button has a 'goto' ("+goto+") that is unknown");
				}
				else err("A button has 'goto' set to ''");
			
			}
			else throw err("A button has no 'goto' set");
		}
	}
	
	private function err(message:String) {
		trace("ERROR " + fileFrom + " " + name+":	"+message);
	}
	
	public function checkQuestions(pages:Map<String, PageInfo>) {
		
		var gotos;
		var page:String;
		
		for (question in permittedElements['question']) {
			gotos = question.attributes();
			for (goto in gotos) {
				page = question.get(goto);
				if (pages.exists(page) == false) err("A question has an answer that takes you to an unknown page ("+goto.toString()+" => "+page+")");
			}	
		}
	}
	
	public function checkPermittedTypes(_xml:Xml = null) {
	
		if (_xml == null) {
			_xml = xml;
			permittedElements = new Map<String,Array<Xml>>();				
			for (type in PermittedTypes.createAll()) {
				permittedElements[type.getName()] = new Array<Xml>();
			}
		}
		
		
		var nodeNam:String;
		for (node in _xml.elements()) {
			nodeNam = node.nodeName.toLowerCase();
			if (permittedElements[nodeNam] != null) permittedElements[nodeNam].push( node ); //ignore haxeUI node types
			checkPermittedTypes(node); // iterate down
		}
	}
	
	public function checkInputs() {
		var id:String;
		for (input in permittedElements['input']) {
			if (input.exists("id") == false) err("There is an input set with no id");
			else { 
				id = input.get('id');
				//if (legalName.match(id) == false) err("Illegal characters used as an input's id (" + id + ")");
				//else {
					if (variables.indexOf(id) == -1) variables.push(id);
					else {
						err("More than 1 input with the same name ("+id+") ");
					}
				//}
			}
		}
		
		//add inputs calculated from calculation
		for (calculation in permittedElements['calculation']) {
			if (calculation.exists('id')) {
				id = calculation.get('id');
				if (variables.indexOf(id) == -1) variables.push(id);
				else {
					err("More than 1 input (this time, a secondary calculated input: "+calculation+") with the same name ("+id+") ");
				}
			}
		}
		
	}
	
	public function checkCalculates() 
	{
		var formulaVariables:Array<String>;
		for (input in permittedElements['calculation']) {
			if (input.exists('variables')) {
				formulaVariables = input.get("variables").split(",");
				
				for (f_var in formulaVariables) {
					if (variables.indexOf(f_var) == -1) {
						err("A Calculation needs a variable ("+f_var+") that does not exist on a given page");
					}
				}
				
			}
			if (input.exists('formula') == false) err("No formula defined for "+input	);
		}
	}
	
}


class Checker {
	var pages:Map<String, PageInfo>;

	
	public function new(pages:Map<String,PageInfo>) {
		this.pages = pages;
		checkPermittedTypes();
		checkButtonLinks();
		checkQuestions();
		checkInputs();
		checkCalculates(); 
		
	}
	
	function checkCalculates() 
	{
		for (page in pages) {
			page.checkCalculates();
		}
	}
	
	function checkInputs() {
		for (page in pages) {
			page.checkInputs();
		}
	}
	
	function checkQuestions() {
		for (page in pages) {
			page.checkQuestions(pages);
		}
	}
	
	function checkPermittedTypes() 
	{
		for (page in pages) {
			page.checkPermittedTypes();
		}
	}
	
	function checkButtonLinks() 
	{
		for (page in pages) {
			page.checkButtons(pages);
		}		
	}
	

}













class Xml_Service {
	var folder:String;

	
	public function new(folder:String) {
		this.folder = folder;
	}
	
	public function get():Map<String,Xml> {
		var dict:Map<String,Xml> = new Map<String,Xml>();
		
		var list:Array<String> = Assets.list(AssetType.TEXT);
		for (filename in list) {
			if (filename.split(".xml").length > 1) dict[filename] = getXml(   filename	  );
		}
		
		return dict;
	}
	
	private function getXml(nam:String):Xml {
		
		var str:String = Assets.getText(nam);
		
		
		var xml:Xml;
		try {
			xml = Xml.parse(str);
		}
		catch(e:String) {
			throw "problem parsing this xml: " + nam;
		}
		return xml;
		
	}
	
	
}