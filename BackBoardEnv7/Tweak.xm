#import "../definitions.h"

static BOOL shouldInject = NO;

%hook SBApplication

- (BOOL)icon:(id)icon launchFromLocation:(int)location
{
	shouldInject = NO;
	NSString *app = [self bundleIdentifier];
	if ([app isEqualToString:@"com.apple.camera"])
		shouldInject = YES;
	return %orig;
}

%end

%hook BKSApplicationLaunchSettings

- (void)setEnvironment:(NSDictionary *)arg1
{
	if (shouldInject && val([NSDictionary dictionaryWithContentsOfFile:PREF_PATH], @"PanoEnabled", NO, BOOLEAN)) {
		NSMutableDictionary *dict = [arg1 mutableCopy];
		[dict setObject:@"/usr/lib/PanoHook7.dylib" forKey:@"DYLD_INSERT_LIBRARIES"];
		[dict setObject:@"1" forKey:@"DYLD_FORCE_FLAT_NAMESPACE"];
 	 	%orig((NSDictionary *)dict);
  		[dict release];
  	}
  	else %orig;
}

%end
