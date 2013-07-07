#import "../definitions.h"
#import <substrate.h>
#include <sys/sysctl.h>

// Very bad code i think, please tell me if you can improve it !

#define setPanoProperty(dict, key, intValue) [dict setObject:[NSNumber numberWithInteger:intValue] forKey:key];

static NSDictionary *prefDict = nil;
static NSMutableDictionary *theDict = nil;
static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

NSString *getSysInfoByName(char *typeSpecifier)
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = (char *)malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    free(answer);
    return (NSString *)results;
}

NSString *modelAP()
{
    return getSysInfoByName((char *)"hw.model");
}

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama) ();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama ()
{
	BOOL filemissing = (old__ACT_CopyDefaultConfigurationForPanorama() == nil);
	if (filemissing) {
		NSLog(@"actHook: firebreak-Configuration.plist is missing from the system, adding it.");
		NSMutableDictionary *createDict = [[NSMutableDictionary alloc] init];
		NSString *model = modelAP();
		setPanoProperty(createDict, @"ACTFrameHeight", isiPad2 ? 720 : 1936)
		setPanoProperty(createDict, @"ACTFrameWidth", isiPad2 ? 960 : 2592)
		setPanoProperty(createDict, @"ACTPanoramaMaxWidth", isiPad2 ? 4000 : filemissing ? 10800 : valueFromKey(prefDict, @"PanoramaMaxWidth", 10800))
		setPanoProperty(createDict, @"ACTPanoramaDefaultDirection", 1)
		setPanoProperty(createDict, @"ACTPanoramaMaxFrameRate", filemissing ? 15 : valueFromKey(prefDict, @"PanoramaMaxFrameRate", 15))
		setPanoProperty(createDict, @"ACTPanoramaMinFrameRate", filemissing ? 15 : valueFromKey(prefDict, @"PanoramaMinFrameRate", 15))
		setPanoProperty(createDict, @"ACTPanoramaBufferRingSize", filemissing ? 6 : valueFromKey(prefDict, @"PanoramaBufferRingSize", 6)) 
		setPanoProperty(createDict, @"ACTPanoramaPowerBlurBias", filemissing ? 30 : valueFromKey(prefDict, @"PanoramaPowerBlurBias", 30))
		setPanoProperty(createDict, @"ACTPanoramaPowerBlurSlope", filemissing ? 16 : valueFromKey(prefDict, @"PanoramaPowerBlurSlope", 16))
		setPanoProperty(createDict, @"ACTPanoramaSliceWidth", 240)
		return createDict;
	} else {
		NSLog(@"actHook: Editing firebreak-Configuration values.");
		theDict = [old__ACT_CopyDefaultConfigurationForPanorama() mutableCopy];
		setPanoProperty(theDict, @"ACTPanoramaMaxWidth", valueFromKey(prefDict, @"PanoramaMaxWidth", 10800))
		setPanoProperty(theDict, @"ACTPanoramaMaxFrameRate", valueFromKey(prefDict, @"PanoramaMaxFrameRate", 15))
		setPanoProperty(theDict, @"ACTPanoramaMinFrameRate", valueFromKey(prefDict, @"PanoramaMinFrameRate", 15))
		setPanoProperty(theDict, @"ACTPanoramaBufferRingSize", valueFromKey(prefDict, @"PanoramaBufferRingSize", 6)) 
		setPanoProperty(theDict, @"ACTPanoramaPowerBlurBias", valueFromKey(prefDict, @"PanoramaPowerBlurBias", 30))
		setPanoProperty(theDict, @"ACTPanoramaPowerBlurSlope", valueFromKey(prefDict, @"PanoramaPowerBlurSlope", 16))
		return theDict;
	}
}

%hook SBAwayController

- (void)_removeCameraPreviewViews
{
	NSLog(@"actHook: Cleaning up.");
	theDict = nil;
	%orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	MSHookFunction((NSMutableDictionary *)MSFindSymbol(NULL, "_ACT_CopyDefaultConfigurationForPanorama"), (NSMutableDictionary *)replaced__ACT_CopyDefaultConfigurationForPanorama, (NSMutableDictionary **)&old__ACT_CopyDefaultConfigurationForPanorama);
	[pool release];
}
