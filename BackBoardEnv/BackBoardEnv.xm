#import "../definitions.h"

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static BOOL shouldInject = NO;

@interface SBApplicationIcon : NSObject
- (NSString *)applicationBundleID;
@end

%hook SBApplicationIcon

- (void)launch
{
	shouldInject = NO;
	NSString *app = [self applicationBundleID];
	if ([app isEqualToString:@"com.apple.camera"])
		shouldInject = YES;
	%orig;
}

%end

%hook BKSApplicationLaunchSettings

- (void)setEnvironment:(NSDictionary *)arg1
{ 
	if (shouldInject && Bool(prefDict, @"PanoEnabled", NO)) {
		DebugLog(@"BackBoardEnv: Adding Panorama Capability to Camera.app");
		NSMutableDictionary *dict = [arg1 mutableCopy];
		[dict setObject:@"/usr/lib/libPano.dylib" forKey:@"DYLD_INSERT_LIBRARIES"];
		[dict setObject:@"1" forKey:@"DYLD_FORCE_FLAT_NAMESPACE"];
 	 	%orig((NSDictionary *)dict);
  		[dict release];
  	}
  	else %orig;
}

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}