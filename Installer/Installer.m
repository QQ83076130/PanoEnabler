#import "../definitions.h"
#include <sys/sysctl.h>

@interface PanoInstaller : NSObject
@end

@implementation PanoInstaller

- (NSString *)getSysInfoByName:(char *)typeSpecifier
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	char *answer = (char *)malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

- (NSString *)modelAP
{
	return [self getSysInfoByName:"hw.model"];
}

- (NSString *)model
{
	return [self getSysInfoByName:"hw.machine"];
}

- (NSString *)modelFile
{
	return [[self modelAP] stringByReplacingOccurrencesOfString:@"AP" withString:@""];
}

- (BOOL)addPanoProperties
{
	NSString *model = [self model];
	NSString *modelFile = [self modelFile];
	
	#define setObject(value, key) \
		if ([cameraProperties objectForKey:key] == nil) \
			[cameraProperties setObject:num(value) forKey:key];

	#define setObjectFloat(value, key) \
		if ([cameraProperties objectForKey:key] == nil) \
			[cameraProperties setObject:FLOAT(value) forKey:key];

	if (isNeedConfigDevice || isNeedConfigDevice7) {
		NSString *platformPathWithFile = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/CameraSetup.plist", modelFile];
		NSMutableDictionary *root = [[NSDictionary dictionaryWithContentsOfFile:platformPathWithFile] mutableCopy];
		if (root == nil) return NO;
		NSMutableDictionary *tuningParameters = [[root objectForKey:@"TuningParameters"] mutableCopy];
		if (tuningParameters == nil) return NO;
		NSMutableDictionary *portTypeBack = [[tuningParameters objectForKey:@"PortTypeBack"] mutableCopy];
		if (portTypeBack == nil) return NO;
	 
		NSString *port = nil;
		NSMutableDictionary *cameraProperties = nil;
		for (NSString *portName in [portTypeBack allKeys]) {
			if ([portName hasPrefix:@"0x"]) {
				port = portName;
				break;
			} else
				return NO;
		}
		cameraProperties = [[portTypeBack objectForKey:port] mutableCopy];
		
		setObject(isiPad ? 17 : 10, @"panoramaMaxIntegrationTime")
		setObject(4096, @"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition")
		setObject(1000, @"panoramaAEIntegrationTimeForUnityGainToMinGainTransition")
		setObject(1024, @"panoramaAEMinGain")
		setObject(4096, @"panoramaAEMaxGain")

		if (isiOS7) {
			setObject(65, @"panoramaAELowerExposureDelta")
			setObject(256, @"panoramaAEUpperExposureDelta")
			setObject(12, @"panoramaAEMaxPerFrameExposureDelta")
			setObjectFloat(0.34999999999999998, @"PanoramaFaceAEHighKeyCorrection")
			setObjectFloat(0.29999999999999999, @"PanoramaFaceAELowKeyCorrection")
		}

		[portTypeBack setObject:cameraProperties forKey:port];
		[tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
		[root setObject:tuningParameters forKey:@"TuningParameters"];
		[root writeToFile:platformPathWithFile atomically:YES];
    
    	NSString *firebreakFile = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7 ? [NSString stringWithFormat:@"/%@/", modelFile] : @"/"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:firebreakFile]) {
			NSLog(@"Adding firebreak-Configuration.plist to system.");
			NSMutableDictionary *createDict = [[NSMutableDictionary alloc] init];
			NSMutableDictionary *insideDict = [[NSMutableDictionary alloc] init];
			setPanoProperty(insideDict, @"ACTFrameHeight", isNeedConfigDevice ? 720 : 1936)
			setPanoProperty(insideDict, @"ACTFrameWidth", isNeedConfigDevice ? 960 : 2592)
			setPanoProperty(insideDict, @"ACTPanoramaMaxWidth", isNeedConfigDevice ? 4000 : 10800)
			setPanoProperty(insideDict, @"ACTPanoramaDefaultDirection", 1)
			setPanoProperty(insideDict, @"ACTPanoramaMaxFrameRate", 15)
			setPanoProperty(insideDict, @"ACTPanoramaMinFrameRate", 15)
			setPanoProperty(insideDict, @"ACTPanoramaBufferRingSize", 6) 
			setPanoProperty(insideDict, @"ACTPanoramaPowerBlurBias", 30)
			setPanoProperty(insideDict, @"ACTPanoramaPowerBlurSlope", 16)
			setPanoProperty(insideDict, @"ACTPanoramaSliceWidth", 240)
			if (isiOS7)
				setPanoProperty(insideDict, @"ACTPanoramaBPNRMode", 0)
			[createDict setObject:insideDict forKey:[self modelAP]];
			[createDict writeToFile:firebreakFile atomically:YES];
			[insideDict release];
			[createDict release];
		}
	}
    
    NSString *avSession = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/AVCaptureSession.plist", modelFile];
    NSMutableDictionary *avRoot = [[NSMutableDictionary dictionaryWithContentsOfFile:avSession] mutableCopy];
    if (avRoot == nil) return NO;
    NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
	if (avCap == nil) return NO;
	NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
	if (index0 == nil) return NO;
	NSDictionary *presetPhoto = [index0 objectForKey:@"AVCaptureSessionPresetPhoto"];
	if (presetPhoto == nil) return NO;
   	
	NSMutableDictionary *presetPhotoToAdd = [presetPhoto mutableCopy];
	NSMutableDictionary *liveSourceOptions = [[presetPhotoToAdd objectForKey:@"LiveSourceOptions"] mutableCopy];
	if (isNeedConfigDevice) {
		NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									num(960), @"Width",
    									@"420f", @"PixelFormatType",
    									num(720), @"Height", nil];
		[liveSourceOptions setObject:res forKey:@"Sensor"];
		[liveSourceOptions setObject:res forKey:@"Capture"];
		[liveSourceOptions setObject:res forKey:@"Preview"];
		[presetPhotoToAdd setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
		[index0 setObject:presetPhotoToAdd forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
		[avCap replaceObjectAtIndex:0 withObject:index0];
		[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
		[avRoot writeToFile:avSession atomically:YES];
	}
	return YES;
}

- (BOOL)install
{
	BOOL success = YES;
	NSLog(@"Adding Panorama Properties.");
	success = [self addPanoProperties];
	if (!success) {
		NSLog(@"Failed adding Panorama Properties.");
		return success;
	}
	NSLog(@"Done!");
	return success;
}

@end


int main(int argc, char **argv, char **envp) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PanoInstaller *installer = [[PanoInstaller alloc] init];
	BOOL success = [installer install];
	[installer release];
	[pool release];
	return (success ? 0 : 1);
}
