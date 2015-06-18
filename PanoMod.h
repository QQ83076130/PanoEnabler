#import "../PS.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#include <substrate.h>
#import <sys/utsname.h>

#define isiPhone4 		[model hasPrefix:@"iPhone3"]
#define isiPhone4S 		[model hasPrefix:@"iPhone4"]
#define isiPhone5		[model hasPrefix:@"iPhone5"]
#define isiPhone5s		[model hasPrefix:@"iPhone6"]
#define isiPhone6		[model hasPrefix:@"iPhone7"]
#define isiPhone5Up		(isiPhone5 || isiPhone5s || isiPhone6)
#define isiPod4			[model hasPrefix:@"iPod4"]
#define isiPod5 		[model hasPrefix:@"iPod5"]
#define isiPad			[model hasPrefix:@"iPad"]
#define isiPad2 		([model isEqualToString:@"iPad2,1"] || [model isEqualToString:@"iPad2,2"] || [model isEqualToString:@"iPad2,3"] || [model isEqualToString:@"iPad2,4"])
#define isiPadMini1G	([model hasPrefix:@"iPad2"] && !isiPad2)
#define isiPadMini2G	([model isEqualToString:@"iPad4,4"] || [model isEqualToString:@"iPad4,5"])
#define isiPad3or4 		[model hasPrefix:@"iPad3"]
#define isiPad4			([model isEqualToString:@"iPad3,4"] || [model isEqualToString:@"iPad3,5"] || [model isEqualToString:@"iPad3,6"])
#define isiPadAir		[model hasPrefix:@"iPad4"]
#define isiPadAir2		[model hasPrefix:@"iPad5"]
#define isNeedConfigDevice 	(isiPad2 || isiPod4 || isiPhone4)
#define isNeedConfigDevice7 (isiPad || isiPhone4)
#define isSlow			(isiPod4 || isiPhone4)
#define is8MPCamDevice	(isiPhone4S || isiPhone5Up)

#define INT intValue
#define aFLOAT floatValue
#define BOOLEAN boolValue

#define val(dict, key, defaultValue, type) (dict[key] ? [dict[key] type] : defaultValue)
#define setIntegerProperty(dict, key, intValue) [dict setObject:@(intValue) forKey:key];

#define readBoolOption(prename, name) \
		name = [dict[prename] boolValue];
#define readIntOption(prename, name, defaultValue) \
		name = dict[prename] ? [dict[prename] intValue] : defaultValue;

CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.actHack.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.actHack.plist";
