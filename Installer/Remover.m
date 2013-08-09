#import "../definitions.h"
#include <sys/sysctl.h>

@interface PanoRemover : NSObject @end

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
	
   	if ([cameraProperties objectForKey:@"panoramaMaxIntegrationTime"] != nil && !(isiPad3or4 || isiPadMini1G)) {
        [cameraProperties removeObjectForKey:@"panoramaMaxIntegrationTime"];
    }

    if ([cameraProperties objectForKey:@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition"] != nil) {
        [cameraProperties removeObjectForKey:@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition"];
    }
    
    if ([cameraProperties objectForKey:@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition"] != nil) {
        [cameraProperties removeObjectForKey:@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition"];
    }
    
    if ([cameraProperties objectForKey:@"panoramaAEMinGain"] != nil) {
        [cameraProperties removeObjectForKey:@"panoramaAEMinGain"];
    }
    
    if ([cameraProperties objectForKey:@"panoramaAEMaxGain"] != nil) {
        [cameraProperties removeObjectForKey:@"panoramaAEMaxGain"];
    }
    
    [portTypeBack setObject:cameraProperties forKey:port];
    [tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
    [root setObject:tuningParameters forKey:@"TuningParameters"];
    [root writeToFile:platformPathWithFile atomically:YES];
    
    [[NSFileManager defaultManager] removeItemAtPath:firebreakFile error:nil];
    
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


