#import "../definitions.h"
#import <substrate.h>
#include <sys/sysctl.h>
#import <AVFoundation/AVFoundation.h>

static NSDictionary *prefDict = nil;

// Flashorama
#define FMisOn Bool(prefDict, @"FMisOn", NO)
static BOOL autoOff = NO;
static BOOL lockFlashButton = NO;
static BOOL isPanorama;

static BOOL isCapturing = NO;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice; // Correct ?
- (void)torch:(int)type;
@end


NSString *getSysInfoByName(char *typeSpecifier)
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = (char *)malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    free(answer);
    return (NSString *)results;
}

NSString *modelAP()
{
    return getSysInfoByName((char *)"hw.model");
}

%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported
{
	return Bool(prefDict, @"LLBPano", NO) ? YES : %orig;
}

%end

%hook AVCaptureFigVideoDevice

- (id)devicePropertiesDictionary
{
	NSString *model = modelAP();
	if (isiPad2) {
		NSLog(@"PanoMod: Adding Panorama Preset to iPad 2.");
		NSMutableDictionary *avRoot = [(NSDictionary *)%orig mutableCopy];
		if (avRoot == nil) return %orig;
		NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
   		if (avCap == nil) return %orig;
   		NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
   		if (index0 == nil) return %orig;
   		NSDictionary *presetPhoto = [index0 objectForKey:@"AVCaptureSessionPresetPhoto"];
   		if (presetPhoto == nil) return %orig;
   	
   		NSMutableDictionary *presetPhotoToAdd = [presetPhoto mutableCopy];
   		NSMutableDictionary *liveSourceOptions = [[presetPhotoToAdd objectForKey:@"LiveSourceOptions"] mutableCopy];
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
		return (id)avRoot;
    }
	return %orig;
}

- (void)setImageControlMode:(int)mode
{
	if (mode == 4 && Bool(prefDict, @"PanoDarkFix", NO))
		%orig(1);
	else %orig;
}

%end

%hook AVResolvedCaptureOptions

- (id)initWithCaptureOptionsDictionary:(id)captureOptionsDictionary
{
	NSLog(@"PanoMod: Hooking Panorama FrameRate.");
	NSMutableDictionary *cameraProperties = [captureOptionsDictionary mutableCopy];
	NSMutableDictionary *liveSourceOptions = [[cameraProperties objectForKey:@"LiveSourceOptions"] mutableCopy];
	if ([[[cameraProperties objectForKey:@"Description"] description] isEqualToString:@"Back Facing 5MP Photo"] &&
		[liveSourceOptions objectForKey:@"HDRSavePreBracketedFrameAsEV0"] == nil)
		{
			[liveSourceOptions setObject:[NSNumber numberWithInteger:valueFromKey(prefDict, @"PanoramaMinFrameRate", 15)] forKey:@"MinFrameRate"];
			[liveSourceOptions setObject:[NSNumber numberWithInteger:valueFromKey(prefDict, @"PanoramaMaxFrameRate", 15)] forKey:@"MaxFrameRate"];
			[cameraProperties setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
			return %orig(cameraProperties);
		}
	return %orig;
}

%end

%hook PLCameraFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	if (isPanorama && FMisOn) {
		autoOff = (mode == 0) ? YES : NO;
		[[%c(PLCameraController) sharedInstance] torch:((mode == 1) ? 1 : 2)];
	}
}

// Lock Flash button usage when capturing Panorama in Auto mode
- (void)_expandAnimated:(BOOL)arg1
{
	if (lockFlashButton && FMisOn)
		NSLog(@"Flashorama: Locking Flash Button.");
	else %orig;
}

%end

%hook PLCameraController

%new(v@:)
- (void)torch:(int)type
{
// type 1 = on, type 2 = off
	AVCaptureDevice *device = self.currentDevice;
	if ([device hasTorch]) {
		NSLog(@"Flashorama: Setting Torch Mode: %@", type == 1 ? @"On" : @"Off");
    	[device lockForConfiguration:nil];
        [device setTorchMode:((type == 1) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
        [device unlockForConfiguration];
	}
}

- (struct CGSize)panoramaPreviewSize
{
	// Default value is {306, 86}
	// iPad recommended maximum width is 576
	// iPhone recommended maximum height is 640
	NSLog(@"PanoMod: Hooking Panorama preview size.");
	return CGSizeMake(valueFromKey(prefDict, @"PreviewWidth", 306), valueFromKey(prefDict, @"PreviewHeight", 86));
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)arg2
{
	if (mode == 2 && arg2 == 0) {
		NSLog(@"PanoMod: Entering Panorama mode.");
		isPanorama = YES;
	}
	else
		isPanorama = NO;
	%orig;
}

- (void)startPanoramaCapture
{
	if (autoOff && FMisOn) {
		NSLog(@"Flashorama: Auto turn on Torch.");
		[[%c(PLCameraController) sharedInstance] torch:1];
		lockFlashButton = YES;
	}
	%orig;
}

- (void)stopPanoramaCapture
{
	if (autoOff && FMisOn) {
		NSLog(@"Flashorama: Auto turn off Torch.");
		[[%c(PLCameraController) sharedInstance] torch:2];
		lockFlashButton = NO;
	}
	%orig;
}

%end

%hook PLCameraLargeShutterButton

+ (id)backgroundPanoOffPressedImageName
{
	NSLog(@"Better Pano Button: Hooking Panorama button.");
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h" : %orig;
}

+ (id)backgroundPanoOffImageName
{
	NSLog(@"Better Pano Button: Hooking Panorama button.");
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOn_2only_-568h" : %orig;
}

- (void)setIsCapturing:(BOOL)arg1
{
	isCapturing = arg1 ? YES : NO;
	%orig;
}

%end

%hook PLCameraButton

- (void)setIsCapturing:(BOOL)arg1
{
	isCapturing = arg1 ? YES : NO;
	%orig;
}

%end

%hook PLCameraPanoramaView

- (void)_updateInstructionalText:(id)arg1
{
	%orig;
	NSLog(@"PanoMod: Hooking Instruction Text Background and Ghost Image View.");
	UIView *labelBG = MSHookIvar<UIView *>(self, "_instructionalTextBackground");
	UIImageView *ghostImg = MSHookIvar<UIImageView *>(self, "_previewGhostImageView");
	[labelBG setHidden:Bool(prefDict, @"hideLabelBG", NO)];
	[ghostImg setHidden:Bool(prefDict, @"hideGhostImg", NO)];
}

%end

%hook PLCameraView

- (void)_updatePanoramaButtonBar
{
	%orig;
	PLCameraController *cameraController = MSHookIvar<PLCameraController *>(self, "_cameraController");
	AVCaptureDevice *device = cameraController.currentDevice;
    [device lockForConfiguration:nil];
    if ([device isLowLightBoostSupported]) {
    	NSLog(@"LLBPano: Enabling Low-light mode in Panorama.");
    	[device setAutomaticallyEnablesLowLightBoostWhenAvailable:Bool(prefDict, @"LLBPano", nil)];
    }
    [device unlockForConfiguration];
}

// Ability to zoom in Panorama mode
- (BOOL)_zoomIsAllowed
{
	if (isPanorama && Bool(prefDict, @"panoZoom", NO)) {
		NSLog(@"PanoMod: Enabling Zoom in Panorama mode.");
		return YES;
	}
	return %orig;
}

// Ability to use Flash button in Panorama mode
- (BOOL)_flashButtonShouldBeHidden
{
	if (isPanorama && FMisOn) {
		NSLog(@"Flashorama: Preventing Flash Button from being hidden.");
		return NO;
	}
	return %orig;
}

// Flash button orientation and Panorama orientation in iPad should be only 1 (Portrait)
- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	if (isPanorama && (FMisOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
		NSLog(@"Flashorama: Fixing Flash Button Orientation.");
		return 1;
	}
	return %orig;
}

%end

%hook PLCameraLevelView

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self && Bool(prefDict, @"hideLevelBar", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Level Bar.");
		[self setHidden:YES];
	}
	return self;
}

%end

%hook PLCameraPanoramaBrokenArrowView

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self && Bool(prefDict, @"hideArrow", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Arrow");
		[self setHidden:YES];
	}
	return self;
}

%end

%hook PLCameraPanoramaTextLabel

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self && Bool(prefDict, @"hideLabel", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Labels.");
		[self setHidden:YES];
	}
	return self;
}

- (void)setText:(id)text
{
	if (Bool(prefDict, @"customText", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Text.");
		%orig([[prefDict objectForKey:@"myText"] description] ?: text);
	}
	else %orig;
}

%end

%hook NSBundle

// Supported only English
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    if ([key isEqual:@"PANO_INSTRUCTIONAL_TEXT_iPad"]) {
    	NSLog(@"Hooking Instructional Text for iPad. (English Only)");
    	return @"Move iPad continuously when taking a Panorama.";
    }
    return %orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}
