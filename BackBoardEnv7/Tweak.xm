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

- (void)setEnvironment:(NSDictionary *)env
{
	if (shouldInject && !val([NSDictionary dictionaryWithContentsOfFile:PREF_PATH], @"PanoEnabled", NO, BOOLEAN)) {
		NSMutableDictionary *dict = [env mutableCopy];
		//[dict setObject:@"/usr/lib/PanoHook7.dylib" forKey:@"DYLD_INSERT_LIBRARIES"];
		//[dict setObject:@"1" forKey:@"DYLD_FORCE_FLAT_NAMESPACE"];
		[dict setObject:@"/var/Acid/Cache4S" forKey:@"DYLD_SHARED_CACHE_DIR"];
		[dict setObject:@"1" forKey:@"DYLD_SHARED_CACHE_DONT_VALIDATE"];
		[dict setObject:@"private" forKey:@"DYLD_SHARED_REGION"];
 	 	%orig((NSDictionary *)dict);
  		[dict release];
  	}
  	else %orig;
}

%end
