#import "../definitions.h"
#include <sys/sysctl.h>
#import <sys/utsname.h>

NSString *getSysInfoByName(const char *typeSpecifier)
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	char *answer = (char *)malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

NSString *ModelAP()
{
	return getSysInfoByName("hw.model");
}

NSString *Model()
{
	return getSysInfoByName("hw.machine");
}

NSString *ModelFile()
{
	return [ModelAP() stringByReplacingOccurrencesOfString:@"AP" withString:@""];
}

BOOL Modify()
{
	NSString *model = Model();
	NSString *modelFile = ModelFile();
    NSString *firebreakFile = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7 ? [NSString stringWithFormat:@"/%@/", ModelFile()] : @"/"];
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSMutableDictionary *firebreakDict = [[NSDictionary dictionaryWithContentsOfFile:firebreakFile] mutableCopy];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:firebreakFile]) {
		if (is8MPCamDevice) {
			BOOL is8MP = val(prefDict, @"Pano8MP", NO, BOOLEAN);
			setIntegerProperty(firebreakDict, @"ACTFrameWidth", is8MP ? 3264 : 2592)
			setIntegerProperty(firebreakDict, @"ACTFrameHeight", is8MP ? 2448 : 1936)
		}
		setIntegerProperty(firebreakDict, @"ACTPanoramaMaxWidth", val(prefDict, @"PanoramaMaxWidth", isNeedConfigDevice ? 4000 : 10800, INT))
		setIntegerProperty(firebreakDict, @"ACTPanoramaMaxFrameRate", val(prefDict, @"PanoramaMaxFrameRate", (isiPhone4S || isiPhone5Up || isiPad3or4 || isiPadAir || isiPadMini2G) ? 20 : 15, INT))
		setIntegerProperty(firebreakDict, @"ACTPanoramaMinFrameRate", val(prefDict, @"PanoramaMinFrameRate", 15, INT))
		setIntegerProperty(firebreakDict, @"ACTPanoramaBufferRingSize", val(prefDict, @"PanoramaBufferRingSize", 6, INT)) 
		setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurBias", val(prefDict, @"PanoramaPowerBlurBias", 30, INT))
		setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurSlope", val(prefDict, @"PanoramaPowerBlurSlope", 16, INT))
		if (isiOS7) {
			setIntegerProperty(firebreakDict, @"ACTPanoramaBPNRMode", val(prefDict, @"BPNR", 1, INT))
        }
		[firebreakDict writeToFile:firebreakFile atomically:YES];
	}

    NSString *avSession = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/AVCaptureSession.plist", modelFile];
    NSMutableDictionary *avRoot = [[NSMutableDictionary dictionaryWithContentsOfFile:avSession] mutableCopy];
    if (avRoot == nil) return NO;
    NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
	if (avCap == nil) return NO;
	NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
	if (index0 == nil) return NO;
	NSMutableDictionary *presetPhoto = [[index0 objectForKey:@"AVCaptureSessionPresetPhoto2592x1936"] mutableCopy];
	if (presetPhoto == nil) return NO;
   	
	NSMutableDictionary *liveSourceOptions = [[presetPhoto objectForKey:@"LiveSourceOptions"] mutableCopy];
	[liveSourceOptions setObject:@(val(prefDict, @"PanoramaMaxFrameRate", 24, INT)) forKey:@"MaxFrameRate"];
	[liveSourceOptions setObject:@(val(prefDict, @"PanoramaMinFrameRate", 15, INT)) forKey:@"MinFrameRate"];
	if (is8MPCamDevice) {
		BOOL is8MP = val(prefDict, @"Pano8MP", NO, BOOLEAN);
		NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									is8MP ? @(3264) : @(2592), @"Width",
    									@"420f", @"PixelFormatType",
    									is8MP ? @(2448) : @(1936), @"Height", nil];
		[liveSourceOptions setObject:res forKey:@"Sensor"];
		[liveSourceOptions setObject:res forKey:@"Capture"];
	}
	[presetPhoto setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
	[index0 setObject:presetPhoto forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	[avCap replaceObjectAtIndex:0 withObject:index0];
	[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
	[avRoot writeToFile:avSession atomically:YES];

	return YES;
}

NSMutableArray *arrayByFixingPano(NSMutableArray *sensorArray)
{
	NSMutableDictionary *dictionaryOfPortTypeBack = [(NSDictionary *)[sensorArray objectAtIndex:0] mutableCopy];
	NSMutableArray *formatArray = [[dictionaryOfPortTypeBack objectForKey:@"SupportedFormatsArray"] mutableCopy];
	
	for (int i=0;i<[formatArray count];i++) {
		NSMutableDictionary *formatDict = [[formatArray objectAtIndex:i] mutableCopy];
		struct utsname systemInfo;
		uname(&systemInfo);
		NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
		if (is8MPCamDevice) {
			NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
			BOOL is8MP = val(prefDict, @"Pano8MP", NO, BOOLEAN);
			int width = is8MP ? 3264 : 2592;
			int height = is8MP ? 2448 : 1936;
			NSDictionary *cropRect = [NSDictionary dictionaryWithObjects:@[@(height), @(width), @0, @0] forKeys:@[@"Height", @"Width", @"X", @"Y"]];
			
			int r1 = [[formatDict objectForKey:@"Width"] intValue];
			int r2 = [[formatDict objectForKey:@"VideoMaxWidth"] intValue];
			if (r1 + r2 == 3264 + 2592) {
				[formatDict setObject:@(width) forKey:@"Width"];
				[formatDict setObject:@(width) forKey:@"VideoMaxWidth"];
				[formatDict setObject:cropRect forKey:@"VideoCropRect"];
			}
			
			int r3 = [[formatDict objectForKey:@"Height"] intValue];
			int r4 = [[formatDict objectForKey:@"VideoMaxHeight"] intValue];
			if (r3 + r4 == 2448 + 1936) {
				[formatDict setObject:@(height) forKey:@"Height"];
				[formatDict setObject:@(height) forKey:@"VideoMaxHeight"];
				[formatDict setObject:cropRect forKey:@"VideoCropRect"];
			}
			[formatArray replaceObjectAtIndex:i withObject:formatDict];
			[dictionaryOfPortTypeBack setObject:formatArray forKey:@"SupportedFormatsArray"];
			[sensorArray replaceObjectAtIndex:0 withObject:dictionaryOfPortTypeBack];
		}
	}
	return sensorArray;
}

BOOL Flush()
{
	NSLog(@"PanoMod: FLUSH");
	NSString *celestialPath = @"/var/mobile/Library/Preferences/com.apple.celestial.plist";
	NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:celestialPath] mutableCopy];
	if (dict != nil) {
		[dict setObject:arrayByFixingPano([[dict objectForKey:@"CameraStreamInfo"] mutableCopy]) forKey:@"CameraStreamInfo"];
		[dict writeToFile:celestialPath atomically:YES];
		CFPreferencesSynchronize(CFSTR("com.apple.celestial"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	}
	return YES;
}

void modify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
      Modify();
}

void flush(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
      Flush();
}


int main(int argc, char **argv, char **envp)
{
	setuid(0); setgid(0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, modify, CFSTR("com.ps.panomod.roothelper"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, flush, CFSTR("com.ps.panomod.flush"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFRunLoopRun();
	return 0;
}
