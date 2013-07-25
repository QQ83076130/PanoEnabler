#import "../definitions.h"
#import <substrate.h>

#include <sys/sysctl.h>

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
	NSLog(@"actHook: Editing firebreak-Configuration values.");
	theDict = [old__ACT_CopyDefaultConfigurationForPanorama() mutableCopy];
	NSString *model = Model();
	setPanoProperty(theDict, @"ACTPanoramaMaxWidth", valueFromKey(prefDict, @"PanoramaMaxWidth", isNon5MP ? 4000 : 10800))
	setPanoProperty(theDict, @"ACTPanoramaMaxFrameRate", valueFromKey(prefDict, @"PanoramaMaxFrameRate", 15))
	setPanoProperty(theDict, @"ACTPanoramaMinFrameRate", valueFromKey(prefDict, @"PanoramaMinFrameRate", 15))
	setPanoProperty(theDict, @"ACTPanoramaBufferRingSize", valueFromKey(prefDict, @"PanoramaBufferRingSize", 6)) 
	setPanoProperty(theDict, @"ACTPanoramaPowerBlurBias", valueFromKey(prefDict, @"PanoramaPowerBlurBias", 30))
	setPanoProperty(theDict, @"ACTPanoramaPowerBlurSlope", valueFromKey(prefDict, @"PanoramaPowerBlurSlope", 16))
	return theDict;
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
