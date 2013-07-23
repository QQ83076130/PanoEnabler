#import "../definitions.h"
#import <substrate.h>
#import <AVFoundation/AVFoundation.h>

#include <sys/sysctl.h>

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

// Flashorama
#define FMisOn Bool(prefDict, @"FMisOn", NO)
static BOOL autoOff = NO;
static BOOL isPanorama = NO;

// Grid in Panorama
#define PanoGridOn Bool(prefDict, @"panoGrid", NO)

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice; // Correct ?
- (void)torch:(int)type;
@end

@interface PLCameraSettingsView
@end

@interface PLCameraSettingsGroupView : UIView
@property(retain, nonatomic) UISwitch* accessorySwitch;
@end

static NSString *Model()
{
	size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = (char *)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    free(answer);
    return results;
}

%hook AVCaptureDevice

// Low Light Boost capability for Panorama
- (BOOL)isLowLightBoostSupported
{
	return Bool(prefDict, @"LLBPano", NO) ? YES : %orig;
}

%end

/*%hook AVCaptureConnection

-(BOOL)isVideoRetainedBufferCountHintSupported { return isPanorama ? YES : %orig; }

%end*/

%hook AVCaptureFigVideoDevice

// Adding Panorama preset to iDevices without 5MP Camera
- (id)devicePropertiesDictionary
{
	NSString *model = Model();
	if (isNon5MP && Bool(prefDict, @"PanoEnabled", NO)) {
		NSLog(@"PanoMod: Adding Panorama Preset to non-5MP Camera iDevice.");
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

// Fix dark problem in Panorama mode
- (void)setImageControlMode:(int)mode
{
	%orig(mode == 4 && Bool(prefDict, @"PanoDarkFix", NO) ? 1 : mode);
}

%end

%hook PLCameraFlashButton

// Implementing Torch in Flash Button in Panorama mode
- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	if (isPanorama && FMisOn) {
		autoOff = (mode == 0) ? YES : NO;
		[[%c(PLCameraController) sharedInstance] torch:((mode == 1) ? 1 : 2)];
	}
}

%end

%hook PLCameraController

%new

- (void)torch:(int)type
{
// type 1 = on, type 2 = off
	if ([self.currentDevice hasTorch]) {
		NSLog(@"Flashorama: Setting Torch Mode: %@", type == 1 ? @"On" : @"Off");
    	[self.currentDevice lockForConfiguration:nil];
        [self.currentDevice setTorchMode:((type == 1) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
        [self.currentDevice unlockForConfiguration];
	}
}

// Enable Low Light Boost if in Panorama mode
- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
    [self.currentDevice lockForConfiguration:nil];
    if ([self.currentDevice isLowLightBoostSupported]) {
    	NSLog(@"LLBPano: Enabling Low-light mode in Panorama.");
    	[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:Bool(prefDict, @"LLBPano", nil)];
    }
    [self.currentDevice unlockForConfiguration];
}

// Set Panorama Preview Size
// Default value is {306, 86}
// iPad recommended maximum width is 576
// iPhone recommended maximum height is 640
- (struct CGSize)panoramaPreviewSize
{
	NSLog(@"PanoMod: Hooking Panorama preview size.");
	return CGSizeMake(valueFromKey(prefDict, @"PreviewWidth", 306), valueFromKey(prefDict, @"PreviewHeight", 86));
}

// Detect Camera mode
- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isPanorama = NO;
	if (mode == 2 && device == 0) {
		NSLog(@"PanoMod: Entering Panorama mode.");
		isPanorama = YES;
	}
	%orig;
}

// Turn on Torch when start Panorama capture
- (void)startPanoramaCapture
{
	if (autoOff && FMisOn) {
		NSLog(@"Flashorama: Auto turn on Torch.");
		[self torch:1];
	}
	%orig;
}

// Turn off Torch when stop Panorama capture
- (void)stopPanoramaCapture
{
	if (autoOff && FMisOn) {
		NSLog(@"Flashorama: Auto turn off Torch.");
		[self torch:2];
	}
	%orig;
}

%end

%hook PLCameraLargeShutterButton

// Changing Panorama button images (For 4-inches iDevices)
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

%end

%hook PLCameraPanoramaView

// Use this method to show/hide instructional text background and ghost image view
- (void)_updateInstructionalText:(NSString *)text
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

// Super important hooking to save Panoramic image in A4 iDevices !
// But problem is we can get only a thumbnail of it, not fully image
- (void)cameraController:(PLCameraController *)controller capturedPanorama:(NSDictionary *)panorama error:(NSError *)error
{
	NSString *model = Model();
	if (isA4) {
		NSMutableDictionary *dict = [panorama mutableCopy];
		UIImage *image = (UIImage *)[dict objectForKey:@"kPLCameraPhotoPreviewImageKey"];
		UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
	}
	%orig;
}

- (void)_showSettings:(BOOL)settings sender:(id)sender
{
	%orig;
	if (settings && PanoGridOn) {
		PLCameraSettingsView *settingsView = MSHookIvar<PLCameraSettingsView *>(self, "_settingsView");
		[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_panoramaGroup") setHidden:(isPanorama ? YES : NO)];
		[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_hdrGroup").accessorySwitch setEnabled:(isPanorama ? NO : YES)];
	}
}

// Unlock Flash Button after Panorama capture
- (void)cameraControllerWillStopPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn && autoOff)
		[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:YES];
}

// Lock Flash Button when start Panorama capture
- (void)cameraControllerDidStartPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn && autoOff)
		[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:NO];
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

// Enable access Grid Option in Panorama mode
- (BOOL)_optionsButtonShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

// Ability to enable grid in Panorama mode
- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

// Ability to use Flash button in Panorama mode
- (BOOL)_flashButtonShouldBeHidden
{
	if (isPanorama && FMisOn) {
		NSLog(@"Flashorama: Preventing Flash Button from being hidden in Panorama mode.");
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

// Show/Hide Panorama Level Bar
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

// Show/Hide Panorama Arrow
- (id)initWithFrame:(struct CGRect)frame
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

// Show/Hide Panorama instructional text
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self && Bool(prefDict, @"hideLabel", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Labels.");
		[self setHidden:YES];
	}
	return self;
}

// Hooking Panorama instructional text
- (void)setText:(NSString *)text
{
	if (Bool(prefDict, @"customText", NO)) {
		NSLog(@"PanoMod: Hooking Panorama Text.");
		%orig([prefDict objectForKey:@"myText"] ? [[prefDict objectForKey:@"myText"] description] : text);
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
