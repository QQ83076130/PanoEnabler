#import "../definitions.h"

static BOOL shouldInject = NO;

@interface SBApplication : UIApplication
- (NSString *)bundleIdentifier;
@end

%hook SBApplication

- (void)setActivationSetting:(id)arg1 flag:(id)arg2
{
	NSString *app = [self bundleIdentifier];
	if ([app isEqualToString:@"com.apple.camera"])
		shouldInject = YES;
	%orig;
	shouldInject = NO;
}

%end

%hook BKSApplicationLaunchSettings

- (void)setEnvironment:(NSDictionary *)env
{
	if (shouldInject && val([NSDictionary dictionaryWithContentsOfFile:PREF_PATH], @"PanoEnabled", NO, BOOLEAN)) {
		NSMutableDictionary *dict = [env mutableCopy];
		[dict setObject:@"/usr/lib/PanoHook7.dylib" forKey:@"DYLD_INSERT_LIBRARIES"];
		[dict setObject:@"1" forKey:@"DYLD_FORCE_FLAT_NAMESPACE"];
 	 	%orig((NSDictionary *)dict);
  		[dict release];
  	}
  	else %orig;
}

%end
