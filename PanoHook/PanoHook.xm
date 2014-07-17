#import "../definitions.h"
#import <substrate.h>
#import <IOKit/IOKitLib.h>

static NSDictionary *prefDict = nil;

typedef io_object_t io_registry_entry_t;
typedef UInt32 IOOptionBits;

//extern "C" CFTypeRef MGCopyAnswer(CFStringRef property);
extern "C" CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static CFTypeRef (*orig_registryEntry)(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
CFTypeRef replaced_registryEntry(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options)
{
    CFTypeRef retval = NULL;
    retval = orig_registryEntry(entry, key, allocator, options);
    if (CFEqual(key, CFSTR("camera-panorama"))) {
    	if (val(prefDict, @"PanoEnabled", NO, BOOLEAN)) {
    		const UInt8 enable[3] = {1, 0, 0};
        	retval = CFDataCreate(kCFAllocatorDefault, enable, 4);
        }
    }
    return retval;
}

Boolean (*orig__isDeviceTreePropertyPresent)(const char *root, CFStringRef key);
Boolean replaced__isDeviceTreePropertyPresent(const char *root, CFStringRef key)
{
	if (CFEqual(key, CFSTR("camera-panorama"))) {
    	if (val(prefDict, @"PanoEnabled", NO, BOOLEAN)) {
    		return YES;
        }
    }
	return orig__isDeviceTreePropertyPresent(root, key);
}

/*CFTypeRef (*orig_MGCopyAnswer)(CFStringRef key);
CFTypeRef replace_MGCopyAnswer(CFStringRef key)
{      
        //NSLog(@"my hookfunction");                                     
        return orig_MGCopyAnswer(key);         
}*/

/*%hook MobileGestaltHelperListener

-(void)getServerAnswerForQuestion:(id)arg1 reply:(^block id)arg2
{
%log; %orig;
}

%end*/


__attribute__((constructor)) static void PanoHookInit() {
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	%init;
	MSHookFunction((void *)IORegistryEntryCreateCFProperty, (void *)replaced_registryEntry, (void **)&orig_registryEntry);
	MSHookFunction((void *)MSFindSymbol(NULL, "_isDeviceTreePropertyPresent"), (void *)replaced__isDeviceTreePropertyPresent, (void **)&orig__isDeviceTreePropertyPresent);
	//MSHookFunction(MGCopyAnswer,replace_MGCopyAnswer,&orig_MGCopyAnswer);
}
