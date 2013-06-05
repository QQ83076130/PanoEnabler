#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>

#ifndef __in
#define __in
#endif

typedef void *PVOID;

CFTypeRef MGCopyAnswer(__in CFStringRef KeyToCopy);
    
#define DYLD_INTERPOSE(_replacment,_replacee) \
   __attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
            __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee };

CFTypeRef _MGCopyAnswer(__in CFStringRef KeyToCopy)
{
    CFTypeRef ReturnData;

    if (!CFStringCompare(KeyToCopy, CFSTR("PanoramaCameraCapability"), 0))
        return kCFBooleanTrue;
    /*if (!CFStringCompare(KeyToCopy, CFSTR("InternalBuild"), 0))
        return kCFBooleanTrue;*/

    ReturnData = MGCopyAnswer(KeyToCopy);
    
    return ReturnData;
}

DYLD_INTERPOSE(_MGCopyAnswer, MGCopyAnswer)

/*
CFTypeRef _IORegistryEntryCreateCFProperty(__in PVOID Entry, __in CFStringRef Key, __in CFAllocatorRef Allocator, __in PVOID Options)
{
	const UInt8 enable[8] = {0, 1, 0, 0, 0, 0, 0, 0};
    CFDataRef DataValue;
    
	if (CFStringCompare(Key, CFSTR("camera-panorama"), 0)) {
    	DataValue = CFDataCreate(kCFAllocatorDefault, enable, 8);
        return DataValue;
    }

    return IORegistryEntryCreateCFProperty((io_registry_entry_t)Entry, Key, Allocator, (IOOptionBits)Options);
}

DYLD_INTERPOSE(_IORegistryEntryCreateCFProperty, IORegistryEntryCreateCFProperty)
*/


int main(int argc, char **argv, char **envp) {
	return 0;
}

// vim:ft=objc
