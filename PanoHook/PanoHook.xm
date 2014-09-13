#import <substrate.h>
#import <IOKit/IOKitLib.h>

typedef io_object_t io_registry_entry_t;
typedef UInt32 IOOptionBits;

extern "C" CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

static CFTypeRef (*orig_registryEntry)(io_registry_entry_t, CFStringRef, CFAllocatorRef, IOOptionBits);
CFTypeRef replaced_registryEntry(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options)
{
    CFTypeRef retval = NULL;
    retval = orig_registryEntry(entry, key, allocator, options);
    if (CFEqual(key, CFSTR("camera-panorama"))) {
    	const UInt8 enable[3] = {1, 0, 0};
        retval = CFDataCreate(kCFAllocatorDefault, enable, 4);
    }
    return retval;
}

Boolean (*orig__isDeviceTreePropertyPresent)(const char *, CFStringRef);
Boolean replaced__isDeviceTreePropertyPresent(const char *root, CFStringRef key)
{
	if (CFEqual(key, CFSTR("camera-panorama")))
    		return YES;
	return orig__isDeviceTreePropertyPresent(root, key);
}

__attribute__((constructor)) static void PanoHookInit()
{
	%init;
	MSHookFunction((void *)IORegistryEntryCreateCFProperty, (void *)replaced_registryEntry, (void **)&orig_registryEntry);
	MSHookFunction((void *)MSFindSymbol(NULL, "_isDeviceTreePropertyPresent"), (void *)replaced__isDeviceTreePropertyPresent, (void **)&orig__isDeviceTreePropertyPresent);
}
