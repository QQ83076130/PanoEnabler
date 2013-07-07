#import "../definitions.h"
#import <CoreFoundation/CoreFoundation.h>
//#import <mach-o/nlist.h>
#import <substrate.h>

/*#define setPanoProperty(dict, key, intValue) [dict setObject:[NSNumber numberWithInteger:intValue] forKey:key];

static NSDictionary *prefDict = nil;
static NSMutableDictionary *theDict = nil;
static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}*/

MSHook(const void*, CFDictionaryGetValue, CFDictionaryRef *dict, const void *key) {
    const void* ret = _CFDictionaryGetValue(dict, key);
    NSLog(@"GetValue: [%@] %@", key, ret);
    return ret;
}

extern "C" id FigSampleBufferProcessorCreateForAutofocus(CFAllocatorRef allocator, id x, CFDictionaryRef dict, int a);

MSHook(id, FigSampleBufferProcessorCreateForAutofocus, CFAllocatorRef allocator, id x, CFDictionaryRef dict, int a) {
	MSHookFunction((void *)&CFDictionaryGetValue, (void *)$CFDictionaryGetValue, (void **)&CFDictionaryGetValue);
	return _FigSampleBufferProcessorCreateForAutofocus(allocator, x, dict, a);
}


%ctor {
	MSHookFunction(FigSampleBufferProcessorCreateForAutofocus, MSHake(FigSampleBufferProcessorCreateForAutofocus));
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	//CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	//[pool release];
}
