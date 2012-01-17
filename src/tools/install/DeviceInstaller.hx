package tools.install;

import neko.Lib;
import tools.install.installers.InstallerBase;
import tools.install.installers.WebInstaller;
import tools.install.installers.WebOSInstaller;


/**
 * ...
 * @author Joshua Granick
 */

class DeviceInstaller {
	
	
	public static var traceEnabled:Bool;
	
	
	public function new (command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool) {
		
		var installer:InstallerBase = null;
		
		switch (target) {
			
			case "webos":
				
				installer = new WebOSInstaller ();
			
			case "web":
				
				installer = new WebInstaller ();
			
			default:
				
				Lib.println ("The specified target is not supported: " + target);
				return;
			
		}
		
		installer.create (BuildJS.buildjs, command, defines, includePaths, projectFile, target, targetFlags, debug);
		
	}	
	
	
}