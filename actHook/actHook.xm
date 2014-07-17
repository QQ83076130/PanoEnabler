#import "../definitions.h"
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#include <sys/sysctl.h>

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static NSMutableDictionary *theDict = nil;

static NSString *Model(const char *typeSpecifier)
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	char *answer = (char *)malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

Boolean (*old__ACT_IsPanoramaSupported)();

Boolean replaced__ACT_IsPanoramaSupported()
{
	return val(prefDict, @"PanoEnabled", NO, BOOLEAN) ? YES : old__ACT_IsPanoramaSupported();
}

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama)();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama()
{

	theDict = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7 ? [NSString stringWithFormat:@"/%@/", [Model("hw.model") stringByReplacingOccurrencesOfString:@"AP" withString:@""]] : @"/"]] mutableCopy];
	NSString *model = Model("hw.machine");
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
	NSLog(@"%@", theDict);
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
