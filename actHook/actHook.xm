#import "../definitions.h"
#import <substrate.h>
#include <sys/sysctl.h>

static NSString *getSysInfoByName(const char *typeSpecifier)
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = (char *)malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

static NSString *ModelAP()
{
	return [getSysInfoByName("hw.model") stringByReplacingOccurrencesOfString:@"AP" withString:@""];
}

NSMutableDictionary* (*old__ACT_CopyDefaultConfigurationForPanorama)();
NSMutableDictionary* replaced__ACT_CopyDefaultConfigurationForPanorama()
{
	NSString *preFirebreakPath = @"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist";
	NSString *firebreakPath = [NSString stringWithFormat:preFirebreakPath, isiOS7 ? [NSString stringWithFormat:@"/%@/", ModelAP()] : @"/"];
	NSMutableDictionary *firebreakDict = [[NSDictionary dictionaryWithContentsOfFile:firebreakPath] mutableCopy];
	return firebreakDict;
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	MSHookFunction((NSMutableDictionary *)MSFindSymbol(NULL, "_ACT_CopyDefaultConfigurationForPanorama"), (NSMutableDictionary *)replaced__ACT_CopyDefaultConfigurationForPanorama, (NSMutableDictionary **)&old__ACT_CopyDefaultConfigurationForPanorama);
	[pool drain];
}
