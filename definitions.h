#define isiPhone4 		[model hasPrefix:@"iPhone3"]
#define isiPhone4S 		[model hasPrefix:@"iPhone4"]
#define isiPhone5Up 	[model hasPrefix:@"iPhone5"]
#define isiPod4			[model hasPrefix:@"iPod4"]
#define isiPod5 		[model hasPrefix:@"iPod5"]
#define isiPad2 		([model isEqualToString:@"iPad2,1"] || [model isEqualToString:@"iPad2,2"] || [model isEqualToString:@"iPad2,3"] || [model isEqualToString:@"iPad2,4"])
#define isiPadMini1G	([model hasPrefix:@"iPad2"] && !isiPad2)
#define isiPad3or4 		[model hasPrefix:@"iPad3"]
#define isNeedConfigDevice 	(isiPad2 || isiPod4 || isiPhone4)
#define isSlow			(isiPod4 || isiPhone4)

#define PreferencesChangedNotification "com.PS.actHack.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.actHack.plist"
#define firebreakFile @"/System/Library/PrivateFrameworks/ACTFramework.framework/firebreak-Configuration.plist"
#define floatFromKey(dict, key, defaultValue) ([dict objectForKey:key] ? [[dict objectForKey:key] floatValue] : defaultValue)
#define Bool(dict, key, defaultBoolValue) ([dict objectForKey:key] ? [[dict objectForKey:key] boolValue] : defaultBoolValue)
#define Int(dict, key, defaultIntValue) ([dict objectForKey:key] ? [[dict objectForKey:key] intValue] : defaultIntValue)
#define num(intValue) [NSNumber numberWithInt:intValue]
#define setPanoProperty(dict, key, intValue) [dict setObject:num(intValue) forKey:key];
