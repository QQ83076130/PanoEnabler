#import <Foundation/Foundation.h>

#define isiPhone4 		[model hasPrefix:@"iPhone3"]
#define isiPhone4S 		[model hasPrefix:@"iPhone4"]
#define isiPhone5		[model hasPrefix:@"iPhone5"]
#define isiPhone5s		[model hasPrefix:@"iPhone6"]
#define isiPhone5Up		(isiPhone5 || isiPhone5s)
#define isiPod4			[model hasPrefix:@"iPod4"]
#define isiPod5 		[model hasPrefix:@"iPod5"]
#define isiPad			[model hasPrefix:@"iPad"]
#define isiPad2 		([model isEqualToString:@"iPad2,1"] || [model isEqualToString:@"iPad2,2"] || [model isEqualToString:@"iPad2,3"] || [model isEqualToString:@"iPad2,4"])
#define isiPadMini1G	([model hasPrefix:@"iPad2"] && !isiPad2)
#define isiPadMini2G	([model isEqualToString:@"iPad4,4"] || [model isEqualToString:@"iPad4,5"])
#define isiPad3or4 		[model hasPrefix:@"iPad3"]
#define isiPadAir		[model hasPrefix:@"iPad4"]
#define isNeedConfigDevice 	(isiPad2 || isiPod4 || isiPhone4)
#define isNeedConfigDevice7 (isiPad || isiPhone4)
#define isSlow			(isiPod4 || isiPhone4)
#define is8MPCamDevice	(isiPhone4S || isiPhone5Up)

#define INT intValue
#define aFLOAT floatValue
#define BOOLEAN boolValue

#define PreferencesChangedNotification "com.PS.actHack.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.actHack.plist"
#define val(dict, key, defaultValue, type) ([dict objectForKey:key] ? [[dict objectForKey:key] type] : defaultValue)
#define num(intValue) [NSNumber numberWithInt:intValue]
#define FLOAT(floatValue) [NSNumber numberWithFloat:floatValue]
#define setPanoProperty(dict, key, intValue) [dict setObject:num(intValue) forKey:key];
#define isiOS6 (kCFCoreFoundationVersionNumber == 793.00)
#define isiOS7 (kCFCoreFoundationVersionNumber >= 847.20)
#define isiOS70 (isiOS7 && kCFCoreFoundationVersionNumber < 847.23)
