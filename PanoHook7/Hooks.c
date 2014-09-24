#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#define DYLD_INTERPOSE(_replacment,_replacee) \
   __attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
            __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee };

CFTypeRef MGCopyAnswer(CFStringRef KeyToCopy);

CFTypeRef _MGCopyAnswer(CFStringRef KeyToCopy)
{
	CFTypeRef ReturnData;
    if (CFStringCompare(KeyToCopy, CFSTR("PanoramaCameraCapability"), 0) == 0)
        return kCFBooleanTrue;
    ReturnData = MGCopyAnswer(KeyToCopy);
    return ReturnData;
}

DYLD_INTERPOSE(_MGCopyAnswer, MGCopyAnswer)

int main () {
	return 0;
}