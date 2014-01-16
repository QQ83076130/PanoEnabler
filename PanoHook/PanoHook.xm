#import "../definitions.h"
#import <substrate.h>
#import <IOKit/IOKitLib.h>

static NSDictionary *prefDict = nil;

typedef mach_port_t io_object_t;
typedef io_object_t io_registry_entry_t;
typedef UInt32 IOOptionBits;
typedef const io_name_t plane;

extern "C" CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
extern "C" CFTypeRef IORegistryEntrySearchCFProperty(io_registry_entry_t entry, const io_name_t plane, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
//extern "C" kern_return_t IORegistryEntryCreateCFProperties(io_registry_entry_t entry, CFMutableDictionaryRef *properties, CFAllocatorRef allocator, IOOptionBits options);
extern "C" kern_return_t IORegistryEntrySetCFProperty(io_registry_entry_t entry, CFStringRef propertyName, CFTypeRef property);
/*static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}*/

static CFTypeRef (*orig_registryEntry)(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
CFTypeRef replaced_registryEntry(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) {
    CFTypeRef retval = NULL;
    NSLog(@"%@", key);
    retval = orig_registryEntry(entry, key, allocator, options);
    NSLog(@"%@", retval);
    if (CFEqual(key, CFSTR("camera-panorama")) || CFEqual(key, CFSTR("panorama"))) {
    	if (val(prefDict, @"PanoEnabled", NO, BOOLEAN)) {
    		const UInt8 enable[3] = {0, 0, 0};
        	retval = CFDataCreate(kCFAllocatorDefault, enable, 4);
        }
    }
    return retval;
}


/*extern "C" CFTypeRef MGCopyAnswer(NSString*, id);
static CFTypeRef (*orig_MGCopyAnswer)(NSString *str, id);
CFTypeRef replaced_MGCopyAnswer(NSString* str, id r) {
CFTypeRef retval = orig_MGCopyAnswer(str, r);
    NSLog(@"%@", str);
    return retval;
}*/
extern "C" Boolean ACT_IsPanoramaSupported();
static Boolean (*orig_ACT_IsPanoramaSupported)();
Boolean replaced_ACT_IsPanoramaSupported()
{
	return orig_ACT_IsPanoramaSupported();
}


/*extern "C" void ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize();
static void (*orig_ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize)();
void replaced_ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize(){
//MSHookFunction((void *)MGCopyAnswer, (void *)replaced_MGCopyAnswer, (void **)&orig_MGCopyAnswer);
orig_ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize();
}*/


__attribute__((constructor)) static void PanoHookInit() {
	//prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	//CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	MSHookFunction((void *)IORegistryEntryCreateCFProperty, (void *)replaced_registryEntry, (void **)&orig_registryEntry);
	MSHookFunction((BOOL *)ACT_IsPanoramaSupported, (BOOL *)replaced_ACT_IsPanoramaSupported, (BOOL **)&orig_ACT_IsPanoramaSupported);
	//MSHookFunction((void *)ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize, (void *)replaced_ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize, (void **)&orig_ACT_FigSampleBufferProcessorCreateForPanoramaWithOptionsAndPreviewSize);
	//MSHookFunction((void *)IORegistryEntryCreateCFProperties, (void *)replaced_registryEntries, (void **)&orig_registryEntries);
}
