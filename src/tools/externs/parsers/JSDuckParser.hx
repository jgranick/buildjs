package tools.externs.parsers;


import neko.io.File;
import tools.externs.data.ClassDefinition;
import tools.externs.data.ClassMethod;
import tools.externs.data.ClassProperty;
import tools.externs.ExternGenerator;


/**
 * ...
 * @author Joshua Granick
 */

class JSDuckParser extends AbstractParser {
	
	
	private var definitions:Hash <ClassDefinition>;
	private var ignoredFiles:Array <String>;
	private var types:Hash <String>;
	
	
	public function new () {
		
		super ();
		
		definitions = new Hash <ClassDefinition> ();
		ignoredFiles = new Array <String> ();
		types = new Hash <String> ();
		
		types.set ("String", "String");
		types.set ("Number", "Float");
		types.set ("Function", "Dynamic");
		types.set ("Boolean", "Bool");
		types.set ("Object", "Dynamic");
		types.set ("undefined", "Void");
		types.set ("null", "Void");
		types.set ("", "Dynamic");
		types.set ("HTMLElement", "HtmlDom");
		types.set ("Mixed", "Dynamic");
		types.set ("Iterable", "Dynamic");
		types.set ("Array", "Array <Dynamic>");
		types.set ("RegExp", "EReg");
		
	}
	
	
	private function getClassInfo (data:Dynamic, definition:ClassDefinition):Void {
		
		definition.className = data.name;
		definition.parentClassName = Reflect.field (data, "extends");
		
	}
	
	
	private function getClassMembers (data:Dynamic, definition:ClassDefinition):Void {
		
		if (data.singleton) {
			
			definition.staticMethods = processMethods (cast (data.members.method, Array <Dynamic>));
			definition.staticProperties = processProperties (cast (data.members.property, Array <Dynamic>));
			
		} else {
			
			definition.methods = processMethods (cast (data.members.method, Array <Dynamic>));
			definition.properties = processProperties (cast (data.members.property, Array <Dynamic>));
			definition.staticMethods = processMethods (cast (data.statics.method, Array <Dynamic>));
			definition.staticProperties = processProperties (cast (data.members.property, Array <Dynamic>));
			
			if (Reflect.hasField (data.members, "cfg")) {
				
				var configProperties = cast (data.members.cfg, Array <Dynamic>);
				
				if (configProperties.length > 0 || cast (data.subclasses, Array <Dynamic>).length > 0) {
					
					var configDefinition = new ClassDefinition ();
					configDefinition.isConfigClass = true;
					configDefinition.className = definition.className + "Config";
					
					if (definition.parentClassName != null && definition.parentClassName != "") {
						
						configDefinition.parentClassName = definition.parentClassName + "Config";
						
					}
					
					configDefinition.properties = processProperties (cast (data.members.cfg, Array <Dynamic>));
					definitions.set (configDefinition.className, configDefinition);
					
				}
				
			}
			
		}
		
	}
	
	
	private function getParentDefinition (definition:ClassDefinition):ClassDefinition {
		
		if (definition != null && definition.parentClassName != null && definitions.exists (definition.parentClassName)) {
			
			var parentDefinition = definitions.get (definition.parentClassName);
			
			if (parentDefinition != definition) {
				
				return parentDefinition;
				
			}
			
		}
		
		return null;
		
	}
	
	
	private function processFile (file:String, basePath:String):Void {
		
		ExternGenerator.print ("Processing " + file);
		
		var content = ExternGenerator.getFileContent (basePath + file);
		var data = ExternGenerator.parseJSON (content);
		
		var definition = new ClassDefinition ();
		
		getClassInfo (data, definition);
		getClassMembers (data, definition);
		
		definitions.set (definition.className, definition);
		
	}
	
	
	public override function processFiles (files:Array <String>, basePath:String):Void {
		
		for (file in files) {
			
			var process = true;
			
			for (ignoredFile in ignoredFiles) {
				
				if (file == ignoredFile) {
					
					process = false;
					
				}
				
			}
			
			if (process) {
				
				processFile (file, basePath);
				
			}
			
		}
		
	}
	
	
	private function processMethods (methodsData:Array <Dynamic>):Hash <ClassMethod> {
		
		var methods = new Hash <ClassMethod> ();
		
		for (methodData in methodsData) {
			
			if (methodData.name == "constructor" || methodData.deprecated == null) {
				
				var method = new ClassMethod ();
				
				if (methodData.name == "constructor") {
					
					method.name = "new";
					method.returnType = "Void";
					
				} else {
					
					method.name = methodData.name;
					method.returnType = Reflect.field (methodData, "return").type;
					
				}
				
				method.owner = methodData.owner;
				
				for (param in cast (methodData.params, Array <Dynamic>)) {
					
					method.parameterNames.push (param.name);
					method.parameterOptional.push (param.optional);
					method.parameterTypes.push (param.type);
					
				}
				
				methods.set (method.name, method);
				
			}
			
		}
		
		return methods;
		
	}
	
	
	private function processProperties (propertiesData:Array <Dynamic>):Hash <ClassProperty> {
		
		var properties = new Hash <ClassProperty> ();
		
		for (propertyData in propertiesData) {
			
			if (propertyData.deprecated == null) {
				
				var property = new ClassProperty ();
				property.name = propertyData.name;
				property.owner = propertyData.owner;
				property.type = propertyData.type;
				
				properties.set (property.name, property);
				
			}
			
		}
		
		return properties;
		
	}
	
	
	private function resolveClass (definition:ClassDefinition):Void {
		
		ExternGenerator.addImport (resolveImport (definition.parentClassName), definition);
		
		for (method in definition.methods) {
			
			if (method.owner == definition.className || method.owner.indexOf ("mixin") > -1) {
				
				ExternGenerator.addImport (resolveImport (method.returnType), definition);
				
				for (paramType in method.parameterTypes) {
					
					ExternGenerator.addImport (resolveImport (paramType), definition);
					
				}
				
			} else {
				
				method.ignore = true;
				
			}
			
		}
		
		for (property in definition.properties) {
			
			if (property.owner == definition.className || (definition.isConfigClass && property.owner == definition.className.substr (0, definition.className.length - "Config".length)) || property.owner.indexOf ("mixin") > -1) {
				
				ExternGenerator.addImport (resolveImport (property.type), definition);
				
			} else {
				
				property.ignore = true;
				
			}
			
		}
		
		for (method in definition.staticMethods) {
			
			if (method.owner == definition.className || method.owner.indexOf ("mixin") > -1) {
				
				ExternGenerator.addImport (resolveImport (method.returnType), definition);
				
				for (paramType in method.parameterTypes) {
					
					ExternGenerator.addImport (resolveImport (paramType), definition);
					
				}
				
			} else {
				
				method.ignore = true;
				
			}
			
		}
		
		for (property in definition.staticProperties) {
			
			if (property.owner == definition.className || property.owner.indexOf ("mixin") > -1) {
				
				ExternGenerator.addImport (resolveImport (property.type), definition);
				
			} else {
				
				property.ignore = true;
				
			}
			
		}
		
	}
	
	
	public override function resolveClasses ():Void {
		
		for (definition in definitions) {
			
			ExternGenerator.print ("Resolving " + definition.className);
			
			resolveClass (definition);
			resolveConflicts (definition);
			
		}
		
	}
	
	
	private function resolveConflicts (definition:ClassDefinition):Void {
		
		for (method in definition.staticMethods) {
			
			if (ExternGenerator.isRestrictedName (method.name)) {
				
				method.hasConflict = true;
				
			} else {
				
				for (i in 0...method.parameterNames.length) {
					
					var paramName = method.parameterNames[i];
					
					if (ExternGenerator.isRestrictedName (paramName)) {
						
						method.parameterNames[i] = "_" + paramName;
						
					}
					
				}
				
			}
			
		}
		
		for (property in definition.staticProperties) {
			
			if (ExternGenerator.isRestrictedName (property.name) || definition.staticMethods.exists (property.name)) {
				
				property.hasConflict = true;
				
			}
			
		}
		
		for (method in definition.methods) {
			
			if (ExternGenerator.isRestrictedName (method.name)) {
				
				method.hasConflict = true;
				
			} else {
				
				for (i in 0...method.parameterNames.length) {
					
					var paramName = method.parameterNames[i];
					
					if (ExternGenerator.isRestrictedName (paramName)) {
						
						method.parameterNames[i] = "_" + paramName;
						
					}
					
				}
				
			}
			
			if (definition.staticMethods.exists (method.name) || definition.staticProperties.exists (method.name)) {
				
				method.hasConflict = true;
				
			} else {
				
				var parentClass = getParentDefinition (definition);
				
				while (parentClass != null) {
					
					if (parentClass.methods.exists (method.name)) {
						
						method.hasConflict = true;
						
					}
					
					parentClass = getParentDefinition (parentClass);
					
				}
				
			}
			
		}
		
		for (property in definition.properties) {
			
			if (ExternGenerator.isRestrictedName (property.name)) {
				
				property.hasConflict = true;
				
			}
			
			if (definition.staticMethods.exists (property.name) || definition.staticProperties.exists (property.name) || definition.methods.exists (property.name)) {
				
				property.hasConflict = true;
				
			} else {
				
				var parentClass = getParentDefinition (definition);
				
				while (parentClass != null) {
					
					if (parentClass.properties.exists (property.name)) {
						
						//property.hasConflict = true;
						property.ignore = true;
						
					}
					
					parentClass = getParentDefinition (parentClass);
					
				}
				
			}
			
		}
		
	}
	
	
	private function resolveImport (type:String):String {
		
		var type = resolveType (type, false);
		
		if (type.indexOf ("Array <") > -1) {
			
			var indexOfFirstBracket = type.indexOf ("<");
			type = type.substr (indexOfFirstBracket + 1, type.indexOf (">") - indexOfFirstBracket - 1);
			
		}
		
		if (type == "HtmlDom") {
			
			type = "js.Dom";
			
		}
		
		if (type.indexOf (".") == -1) {
			
			return null;
			
		} else {
			
			return type;
			
		}
		
	}
	
	
	private function resolveType (type:String, abbreviate:Bool = true):String {
		
		if (type == null) {
			
			return "Void";
			
		}
		
		var isArray = false;
		
		if (type.substr (-2) == "[]") {
			
			isArray = true;
			type = type.substr (0, type.length - 2);
			
		}
		
		var resolvedType:String = "";
		
		if (type.indexOf ("/") > -1) {
			
			resolvedType = "Dynamic";
			
		} else if (types.exists (type)) {
			
			resolvedType = types.get (type);
			
		} else {
			
			if (abbreviate) {
				
				resolvedType = ExternGenerator.resolveClassName (type);
				
			} else {
				
				resolvedType = ExternGenerator.resolvePackageNameDot (type) + ExternGenerator.resolveClassName (type);
				
			}
			
		}
		
		if (isArray) {
			
			return "Array <" + resolvedType + ">";
			
		} else {
			
			return resolvedType;
			
		}
		
	}
	
	
	private function writeConfigClass (definition:ClassDefinition, basePath:String):Void {
		
		var targetPath = basePath + ExternGenerator.resolvePackageNameDot (definition.className).split (".").join ("/") + ExternGenerator.resolveClassName (definition.className) + ".hx";
		
		ExternGenerator.print ("Writing " + targetPath);
		ExternGenerator.makeDirectory (targetPath);
		
		var imports = new Array <String> ();
		var methods = new Array <String> ();
		var properties = new Array <String> ();
		var staticMethods = new Array <String> ();
		var staticProperties = new Array <String> ();
		
		for (importPath in definition.imports) {
			
			imports.push (importPath);
			
		}
		
		for (property in definition.properties) {
			
			if (!property.ignore) {
				
				properties.push (writeClassProperty (property, false));
				
			}
			
		}
		
		imports.sort (ExternGenerator.alphabeticalSorting);
		properties.sort (ExternGenerator.alphabeticalSorting);
		
		var output = File.write (targetPath, false);
		
		output.writeString ("package " + ExternGenerator.resolvePackageName (definition.className) + ";\n\n");
		
		var parentClassImport = resolveImport (definition.parentClassName);
		
		for (importPath in imports) {
			
			output.writeString ("import " + importPath + ";\n");
			
		}
		
		if (imports.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		output.writeString ('class ' + ExternGenerator.resolveClassName (definition.className));
		
		var parentClassName = "";
		
		if (definition.parentClassName != null && definition.parentClassName != "" && definition.parentClassName != "Object") {
			
			parentClassName = ExternGenerator.resolveClassName (definition.parentClassName);
			
			if (parentClassName == ExternGenerator.resolveClassName (definition.className)) {
				
				parentClassName = ExternGenerator.resolvePackageNameDot (definition.parentClassName) + parentClassName;
				
			}
			
		}
		
		if (parentClassName != "") {
			
			output.writeString (" extends " + parentClassName);
			
		} else {
			
			output.writeString (" implements Dynamic");
			
		}
		
		output.writeString (" {\n\n");
		
		for (property in properties) {
			
			output.writeString ("	" + property);
			
		}
		
		if (properties.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		output.writeString ("	public function new (properties:Dynamic = null):Void {\n");
		output.writeString ("		\n");
		
		if (parentClassName != "") {
			
			output.writeString ("		super (properties);\n");
			
		} else {
			
			output.writeString ("		untyped __js__ (\"this.__proto__ = {}.__proto__\");\n");
			output.writeString ("		\n");
			output.writeString ("		if (properties != null) {\n");
			output.writeString ("			\n");
			output.writeString ("			for (propertyName in Reflect.fields (properties)) {\n");
			output.writeString ("				\n");
			output.writeString ("				Reflect.setField (this, propertyName, Reflect.field (properties, propertyName));");
			output.writeString ("				\n");
			output.writeString ("			}\n");
			output.writeString ("			\n");
			output.writeString ("		}\n");
			
		}
		
		output.writeString ("		\n");
		output.writeString ("	}\n\n");
		
		output.writeString ("}");
		output.close ();
		
	}
	
	
	private function writeClass (definition:ClassDefinition, basePath:String):Void {
		
		var targetPath = basePath + ExternGenerator.resolvePackageNameDot (definition.className).split (".").join ("/") + ExternGenerator.resolveClassName (definition.className) + ".hx";
		
		ExternGenerator.print ("Writing " + targetPath);
		ExternGenerator.makeDirectory (targetPath);
		
		var imports = new Array <String> ();
		var methods = new Array <String> ();
		var properties = new Array <String> ();
		var staticMethods = new Array <String> ();
		var staticProperties = new Array <String> ();
		
		for (importPath in definition.imports) {
			
			imports.push (importPath);
			
		}
		
		for (method in definition.methods) {
			
			if (!method.ignore) {
				
				methods.push (writeClassMethod (method, false));
				
			}
			
		}
		
		for (property in definition.properties) {
			
			if (!property.ignore) {
				
				properties.push (writeClassProperty (property, false));
				
			}
			
		}
		
		for (method in definition.staticMethods) {
			
			if (!method.ignore) {
				
				methods.push (writeClassMethod (method, true));
				
			}
			
		}
		
		for (property in definition.staticProperties) {
			
			if (!property.ignore) {
				
				properties.push (writeClassProperty (property, true));
				
			}
			
		}
		
		imports.sort (ExternGenerator.alphabeticalSorting);
		methods.sort (ExternGenerator.alphabeticalSorting);
		properties.sort (ExternGenerator.alphabeticalSorting);
		staticMethods.sort (ExternGenerator.alphabeticalSorting);
		staticProperties.sort (ExternGenerator.alphabeticalSorting);
		
		var output = File.write (targetPath, false);
		
		output.writeString ("package " + ExternGenerator.resolvePackageName (definition.className) + ";\n\n");
		
		for (importPath in imports) {
			
			output.writeString ("import " + importPath + ";\n");
			
		}
		
		if (imports.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		output.writeString ('@:native ("' + definition.className + '")\n');
		output.writeString ('extern class ' + ExternGenerator.resolveClassName (definition.className));
		
		var parentClassName = "";
		
		if (definition.parentClassName != null && definition.parentClassName != "" && definition.parentClassName != "Object") {
			
			parentClassName = ExternGenerator.resolveClassName (definition.parentClassName);
			
			if (parentClassName == ExternGenerator.resolveClassName (definition.className)) {
				
				parentClassName = ExternGenerator.resolvePackageNameDot (definition.parentClassName) + parentClassName;
				
			}
			
		}
		
		if (parentClassName != "") {
			
			output.writeString (" extends " + parentClassName);
			
		}
		
		output.writeString (" {\n\n");
		
		for (property in staticProperties) {
			
			output.writeString ("	" + property);
			
		}
		
		if (staticProperties.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		for (property in properties) {
			
			output.writeString ("	" + property);
			
		}
		
		if (properties.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		for (method in staticMethods) {
			
			output.writeString ("	" + method);
			
		}
		
		if (staticMethods.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		for (method in methods) {
			
			output.writeString ("	" + method);
			
		}
		
		if (methods.length > 0) {
			
			output.writeString ("\n");
			
		}
		
		output.writeString ("}");
		output.close ();
		
	}
	
	
	public override function writeClasses (targetPath:String):Void {
		
		ExternGenerator.makeDirectory (targetPath);
		
		for (definition in definitions) {
			
			if (definition.isConfigClass) {
				
				writeConfigClass (definition, targetPath);
				
			} else {
				
				writeClass (definition, targetPath);
				
			}
			
		}
		
	}
	
	
	private function writeClassMethod (method:ClassMethod, isStatic:Bool):String {
		
		var output = "public ";
		
		if (isStatic) {
			
			output += "static ";
			
		}
		
		output += "function " + method.name + " (";
		
		for (i in 0...method.parameterNames.length) {
			
			if (i > 0) {
				
				output += ", ";
				
			}
			
			if (method.parameterOptional[i]) {
				
				output += "?";
				
			}
			
			output += method.parameterNames[i] + ":" + resolveType (method.parameterTypes[i]);
			
		}
		
		output += "):" + resolveType (method.returnType) + ";\n";
		
		if (method.hasConflict) {
			
			return "//" + output;
			
		} else {
			
			return output;
			
		}
		
	}
	
	
	private function writeClassProperty (property:ClassProperty, isStatic:Bool):String {
		
		var output = "public ";
		
		if (isStatic) {
			
			output += "static ";
			
		}
		
		output += "var " + property.name + ":" + resolveType (property.type) + ";\n";
		
		if (property.hasConflict) {
			
			return "//" + output;
			
		} else {
			
			return output;
			
		}
		
	}
	
	
}