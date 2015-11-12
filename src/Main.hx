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
	
	
	

}

enum PermittedTypes{
	button;
	calculate;
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
		
		for (question in permittedElements['question']) {
			gotos = question.attributes();
			for (goto in gotos) {
				if (pages.exists(goto.toString()) == false) err("A question has an answer that takes you to an unknown page ("+goto.toString()+")");
			}	
		}
	}
	
	public function checkPermittedTypes() {
	
		permittedElements = new Map<String,Array<Xml>>();
				
		for (type in PermittedTypes.createAll()) {
			permittedElements[type.getName()] = new Array<Xml>();
		}
		
		var nodeNam:String;
		for (node in xml.elements()) {
			nodeNam = node.nodeName.toLowerCase();
			if (permittedElements[nodeNam] == null) err("There is an unknown element type of " + nodeNam);
			else permittedElements[nodeNam].push( node );
		}
	}
	
	public function checkInputs() {
		var id:String;
		for (input in permittedElements['input']) {
			if (input.exists("id") == false) err("There is an input set with no id");
			else { 
				id = input.get('id');
				if (legalName.match(id) == false) err("Illegal characters used as an input's id (" + id + ")");
				else {
					if (variables.indexOf(id) == -1) variables.push(id);
					else {
						err("More than 1 input with the same name ("+id+") ");
					}
				}
			}
		}
		
	}
	
	public function checkCalculates() 
	{
		var formulaVariables:Array<String>;
		for (input in permittedElements['calculate']) {
			if (input.exists('variables')) {
				formulaVariables = input.get("variables").split(",");
				
				for (f_var in formulaVariables) {
					if (variables.indexOf(f_var) == -1) {
						err("A Calculate needs a variable ("+f_var+") that does not exist on a given page");
					}
				}
				
			}
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