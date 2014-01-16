#import "../definitions.h"
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#include <sys/sysctl.h>

%config(generator=MobileSubstrate);

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static NSString *Model()
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *answer = (char *)malloc(size);
	sysctlbyname("hw.machine", answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

static NSMutableDictionary *theDict = nil;

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama) ();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama ()
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
		setPanoProperty(theDict, @"ACTPanoramaBPNRMode", val(prefDict, @"BPNRMode", 0, INT))
	return theDict;
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	MSHookFunction((NSMutableDictionary *)MSFindSymbol(NULL, "_ACT_CopyDefaultConfigurationForPanorama"), (NSMutableDictionary *)replaced__ACT_CopyDefaultConfigurationForPanorama, (NSMutableDictionary **)&old__ACT_CopyDefaultConfigurationForPanorama);
	[pool drain];
}
