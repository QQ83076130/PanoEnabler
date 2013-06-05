#import "../definitions.h"
#import <substrate.h>

// Very bad code i think, please tell me if you can improve it !

#define setPanoProperty(dict, key, intValue) [dict setObject:[NSNumber numberWithInteger:intValue] forKey:key];

static NSDictionary *prefDict = nil;
static NSMutableDictionary *theDict = nil;
static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}


NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama) ();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama ()
{
	theDict = [old__ACT_CopyDefaultConfigurationForPanorama() mutableCopy];
	setPanoProperty(theDict, @"ACTPanoramaMaxWidth", valueFromKey(prefDict, @"PanoramaMaxWidth", 10800))
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
