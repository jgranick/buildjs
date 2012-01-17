package tools.install.installers;


import neko.io.Path;
import neko.Lib;
import tools.install.data.Asset;


class WebInstaller extends InstallerBase {

	
	private var sdkDir:String;
   
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/web/bin/";
		mkdir (buildDirectory + "/web/obj");
		mkdir (destination);
		
		recursiveCopy (BUILDJS + "/install/haxe", buildDirectory + "/web/haxe");
		
		var hxml:String = buildDirectory + "/web/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		copyIfNewer (buildDirectory + "/web/obj/" + defines.get ("APP_MAIN") + ".js", buildDirectory + "/web/bin/" + defines.get ("APP_MAIN") + ".js");
		
	}
	
	
	override function run ():Void {
		
		if (BuildJS.isWindows) {
			
			runCommand (buildDirectory + "/web/bin", defines.get ("APP_FILE"), []);
			
		} else {
			
			runCommand (buildDirectory + "/web/bin", "open", [ defines.get ("APP_FILE") ] );
			
		}
		
	}
	
	
	override function traceMessages ():Void {
		
		//runPalmCommand (false, "log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/web/bin/";
		mkdir (destination);
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			copyIfNewer (asset.sourcePath, destination + asset.targetPath);
			
		}
		
	}
	
	
}
