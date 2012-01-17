package tools.externs.data;

/**
 * ...
 * @author Joshua Granick
 */

class ClassDefinition {
	
	
	public var className:String;
	public var imports:Hash <String>;
	public var isConfigClass:Bool;
	public var methods:Hash <ClassMethod>;
	public var parentClassName:String;
	public var properties:Hash <ClassProperty>;
	public var staticMethods:Hash <ClassMethod>;
	public var staticProperties:Hash <ClassProperty>;
	
	
	public function new () {
		
		imports = new Hash <String> ();
		methods = new Hash <ClassMethod> ();
		properties = new Hash <ClassProperty> ();
		staticMethods = new Hash <ClassMethod> ();
		staticProperties = new Hash <ClassProperty> ();
		
	}
	
	
}