#import "../definitions.h"
#include <sys/sysctl.h>

@interface PanoRemover : NSObject
@end

@implementation PanoRemover

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

- (BOOL)removePanoProperties
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
	for (NSString *portName in [portTypeBack allKeys]) {
		if ([portName hasPrefix:@"0x"]) {
			port = portName;
			break;
		} else
			return NO;
	}
	
	#define removeObject(key) \
		if ([cameraProperties objectForKey:key] != nil) \
			[cameraProperties removeObjectForKey:key];

	if (!isiPad) {
		removeObject(@"panoramaMaxIntegrationTime")
	}
	removeObject(@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition")
	removeObject(@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition")
	removeObject(@"panoramaAEMinGain")
	removeObject(@"panoramaAEMaxGain")
	if (isiOS7) {
		removeObject(@"panoramaAELowerExposureDelta")
		removeObject(@"panoramaAEUpperExposureDelta")
		removeObject(@"panoramaAEMaxPerFrameExposureDelta")
		removeObject(@"PanoramaFaceAEHighKeyCorrection")
		removeObject(@"PanoramaFaceAELowKeyCorrection")
	}

	[portTypeBack setObject:cameraProperties forKey:port];
	[tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
	[root setObject:tuningParameters forKey:@"TuningParameters"];
	[root writeToFile:platformPathWithFile atomically:YES];
    
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7 ? [NSString stringWithFormat:@"/%@/", modelFile] : @"/"] error:nil];
    
	if (isNeedConfigDevice) {
		NSString *avSession = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/AVCaptureSession.plist", modelFile];
		NSMutableDictionary *avRoot = [[NSMutableDictionary dictionaryWithContentsOfFile:avSession] mutableCopy];
   		if (avRoot == nil) return NO;
		NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
   		if (avCap == nil) return NO;
   		NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
   		if (index0 == nil) return NO;
   		NSDictionary *presetToDelete = [index0 objectForKey:@"AVCaptureSessionPresetPhoto2592x1936"];
   		if (presetToDelete == nil) return YES;

		[index0 removeObjectForKey:@"AVCaptureSessionPresetPhoto2592x1936"];
		[avCap replaceObjectAtIndex:0 withObject:index0];
		[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
		[avRoot writeToFile:avSession atomically:YES];
	}
	return YES;
}

- (BOOL)remove
{
	BOOL success = YES;
	NSLog(@"Removing Panorama Properties.");
	success = [self removePanoProperties];
	if (!success) {
		NSLog(@"Failed removing Panorama Properties.");
		return success;
	}
	NSLog(@"Done!");
	return success;
}

@end


int main(int argc, char **argv, char **envp) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PanoRemover *remover = [[PanoRemover alloc] init];
	BOOL success = [remover remove];
	[remover release];
	[pool release];
	return (success ? 0 : 1);
}
