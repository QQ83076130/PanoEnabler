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
    	NSString *platformPathWithFile = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/CameraSetup.plist", modelFile];
    	NSMutableDictionary *root = [[NSDictionary dictionaryWithContentsOfFile:platformPathWithFile] mutableCopy];
    	if (root == nil) return NO;
    	NSMutableDictionary *tuningParameters = [[root objectForKey:@"TuningParameters"] mutableCopy];
    	if (tuningParameters == nil) return NO;
    	NSMutableDictionary *portTypeBack = [[tuningParameters objectForKey:@"PortTypeBack"] mutableCopy];
    	if (portTypeBack == nil) return NO;
    
    	NSString *port = nil;
    	NSMutableDictionary *cameraProperties = nil;
    	if ([portTypeBack objectForKey:@"0x3650"] != nil) {
    		cameraProperties = [[portTypeBack objectForKey:@"0x3650"] mutableCopy];
    		port = @"0x3650";
    	}
    	else if ([portTypeBack objectForKey:@"0x9726"] != nil) {
    		cameraProperties = [[portTypeBack objectForKey:@"0x9726"] mutableCopy];
    		port = @"0x9726";
    	}
    	else if ([portTypeBack objectForKey:@"0x5651"] != nil) {
    		cameraProperties = [[portTypeBack objectForKey:@"0x5651"] mutableCopy];
    		port = @"0x5651";
    	}
    	else if ([portTypeBack objectForKey:@"0x5690"] != nil) {
    		cameraProperties = [[portTypeBack objectForKey:@"0x5690"] mutableCopy];
    		port = @"0x5690";
    	}
	else return NO;

   	if ([cameraProperties objectForKey:@"panoramaMaxIntegrationTime"] == nil)
        	[cameraProperties setObject:num(17) forKey:@"panoramaMaxIntegrationTime"];

    	if ([cameraProperties objectForKey:@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition"] == nil)
        	[cameraProperties setObject:num(4096) forKey:@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition"];

    	if ([cameraProperties objectForKey:@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition"] == nil)
        	[cameraProperties setObject:num(1000) forKey:@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition"];

    	if ([cameraProperties objectForKey:@"panoramaAEMinGain"] == nil)
        	[cameraProperties setObject:num(1024) forKey:@"panoramaAEMinGain"];

    	if ([cameraProperties objectForKey:@"panoramaAEMaxGain"] == nil)
        	[cameraProperties setObject:num(4096) forKey:@"panoramaAEMaxGain"];

    	[portTypeBack setObject:cameraProperties forKey:port];
    	[tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
    	[root setObject:tuningParameters forKey:@"TuningParameters"];
    	[root writeToFile:platformPathWithFile atomically:YES];
    
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
		[createDict setObject:insideDict forKey:[self modelAP]];
		[createDict writeToFile:firebreakFile atomically:YES];
		[insideDict release];
		[createDict release];
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

