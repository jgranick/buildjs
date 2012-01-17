package tools.install.installers;


import data.Asset;
import neko.FileSystem;
import neko.io.Path;


/**
 * ...
 * @author Joshua Granick
 */

class HTML5Installer extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/html5/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/install-tool/html5/haxe", buildDirectory + "/html5/haxe");
		recursiveCopy (NME + "/install-tool/html5/hxml", buildDirectory + "/html5/haxe");
		
		var hxml:String = buildDirectory + "/html5/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
	}
	
	
	private function generateFontData (font:Asset, destination:String):Void {
		
		var sourcePath = font.sourcePath;
		var targetPath = destination + font.targetPath;
		
		runCommand (Path.directory (targetPath), "neko", [ NME + "/install-tool/html5/hxswfml.n", "ttf2hash", FileSystem.fullPath (sourcePath) ] );
		
		context.HAXE_FLAGS += "\n-resource " + FileSystem.fullPath (sourcePath) + ".hash@" + font.flatName;
		
	}
	
	
	override function run ():Void {
		
		var destination:String = buildDirectory + "/html5/bin";
		var dotSlash:String = "./";
		
		if (defines.exists ("windows")) {
			
			dotSlash = ".\\";
			
		}
		
		runCommand (destination, dotSlash + "index.html", []);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/html5/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/install-tool/html5/template", destination);
		
		/*for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("webOS", ndll.name + ".so"), destination + ndll.name + ".so" );
			
		}*/
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != "font") {
				
				copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			} else {
				
				generateFontData (asset, destination);
				
			}
			
		}
		
	}
	
	
}