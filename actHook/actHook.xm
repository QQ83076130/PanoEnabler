#import "../definitions.h"
#import <substrate.h>
#include <sys/sysctl.h>

static NSMutableDictionary *theDict = nil;

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama) ();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama ()
{
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
