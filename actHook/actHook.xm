#import "../definitions.h"
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/utsname.h>

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static NSMutableDictionary *theDict = nil;

static NSString *Model()
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}

Boolean (*old__ACT_IsPanoramaSupported)();

Boolean replaced__ACT_IsPanoramaSupported() {
	return val(prefDict, @"PanoEnabled", NO, BOOLEAN) ? YES : old__ACT_IsPanoramaSupported();
}

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama)();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama()
{
	theDict = [old__ACT_CopyDefaultConfigurationForPanorama() mutableCopy];
	NSString *model = Model();
	if (is8MPCamDevice && val(prefDict, @"Pano8MP", NO, BOOLEAN)) {
		setPanoProperty(theDict, @"ACTFrameWidth", 3264)
		setPanoProperty(theDict, @"ACTFrameHeight", 2448)
	}
	setPanoProperty(theDict, @"ACTPanoramaMaxWidth", val(prefDict, @"PanoramaMaxWidth", isNeedConfigDevice ? 4000 : 10800, INT))
	setPanoProperty(theDict, @"ACTPanoramaMaxFrameRate", val(prefDict, @"PanoramaMaxFrameRate", 15, INT))
	setPanoProperty(theDict, @"ACTPanoramaMinFrameRate", val(prefDict, @"PanoramaMinFrameRate", 15, INT))
	setPanoProperty(theDict, @"ACTPanoramaBufferRingSize", val(prefDict, @"PanoramaBufferRingSize", 6, INT)) 
	setPanoProperty(theDict, @"ACTPanoramaPowerBlurBias", val(prefDict, @"PanoramaPowerBlurBias", 30, INT))
	setPanoProperty(theDict, @"ACTPanoramaPowerBlurSlope", val(prefDict, @"PanoramaPowerBlurSlope", 16, INT))
	if (isiOS7)
		setPanoProperty(theDict, @"ACTPanoramaBPNRMode", val(prefDict, @"BPNR", NO, BOOLEAN) ? 1 : 0)
	return theDict;
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	MSHookFunction(((BOOL *)MSFindSymbol(NULL, "_ACT_IsPanoramaSupported")), (BOOL *)replaced__ACT_IsPanoramaSupported, (BOOL **)&old__ACT_IsPanoramaSupported);
	MSHookFunction((NSMutableDictionary *)MSFindSymbol(NULL, "_ACT_CopyDefaultConfigurationForPanorama"), (NSMutableDictionary *)replaced__ACT_CopyDefaultConfigurationForPanorama, (NSMutableDictionary **)&old__ACT_CopyDefaultConfigurationForPanorama);
	[pool drain];
}
