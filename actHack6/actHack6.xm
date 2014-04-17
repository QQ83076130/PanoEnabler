#import "../definitions.h"
#import <substrate.h>
#import "../PanoMod.h"

static BOOL shouldHook = NO;
static BOOL PanoEnabled;

// The following code saves the actual panoramic image in A4 iDevices which they won't do for some reasons
extern "C" id PLCreateThumbnailsFromJPEGData(PLIOSurfaceData *, id, id, BOOL);
MSHook(id, PLCreateThumbnailsFromJPEGData, PLIOSurfaceData *data, id r2, id r3, BOOL r4)
{
	if (shouldHook) {
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
		readBoolOption(@"PanoEnabled", PanoEnabled);
		shouldHook = NO;
		if (PanoEnabled) {
			UIImage *image = [[UIImage alloc] initWithData:data];
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
			[image release];
		}
	}
	return _PLCreateThumbnailsFromJPEGData(data, r2, r3, r4);
}

%hook PLCameraController

- (void)_panoramaDidStop
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	shouldHook = isSlow;
	%orig;
}

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (isiOS6) {
		MSHookFunction((void *)PLCreateThumbnailsFromJPEGData, (void *)$PLCreateThumbnailsFromJPEGData, (void **)&_PLCreateThumbnailsFromJPEGData);
		%init;
	}
	[pool drain];
}
