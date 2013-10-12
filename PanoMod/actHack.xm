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
@property(assign) AVCaptureDevice *currentDevice;
- (void)torch:(int)type;
@end

@interface PLCameraSettingsView
@end

@interface PLCameraFlashButton : UIButton
- (void)_expandAnimated:(BOOL)animated;
- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated;
@end

@interface PLCameraPanoramaView
- (void)setCaptureDirection:(int)direction;
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

%hook AVCaptureFigVideoDevice

// Fix dark problem in Panorama mode
- (void)setImageControlMode:(int)mode
{
	if (Bool(prefDict, @"PanoDarkFix", NO)) {
		if (mode == 4)
			%orig(1);
		else %orig;
	} else %orig;
}

%end

%hook PLCameraFlashButton

// Implementing Torch in Flash Button in Panorama mode
- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	if (FMisOn) {
		if (isPanorama) {
			autoOff = (mode == 0) ? YES : NO;
			[[%c(PLCameraController) sharedInstance] torch:mode];
		}
	}
}

%end

%hook PLCameraController

%new(v@:)

- (void)torch:(int)type
{
// type 1 = on, type -1 = off
	if ([self.currentDevice hasTorch]) {
    		[self.currentDevice lockForConfiguration:nil];
		[self.currentDevice setTorchMode:((type == 1) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
        	[self.currentDevice unlockForConfiguration];
	}
}


// Enable Low Light Boost if in Panorama mode
- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (mode == 2 && device == 0) {
   		[self.currentDevice lockForConfiguration:nil];
    		if ([self.currentDevice isLowLightBoostSupported])
    			[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:Bool(prefDict, @"LLBPano", nil)];
    		[self.currentDevice unlockForConfiguration];
    	}
}

// Set Panorama Preview Size
// Default value is {306, 86}
// iPad recommended maximum width is 576 px
// iPhone recommended maximum height is 640 px
- (struct CGSize)panoramaPreviewSize
{
	return CGSizeMake(valueFromKey(prefDict, @"PreviewWidth", 306), valueFromKey(prefDict, @"PreviewHeight", 86));
}

// Detect Camera mode
- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isPanorama = (mode == 2 && device == 0) ? YES : NO;
	%orig;
}

// Turn on Torch when start Panorama capture
- (void)startPanoramaCapture
{
	if (FMisOn) {
		if (autoOff)
			[self torch:1];
	}
	%orig;
}

// Turn off Torch when stop Panorama capture
- (void)stopPanoramaCapture
{
	if (FMisOn) {
		if (autoOff)
			[self torch:-1];
	}
	%orig;
}

%end

%hook PLCameraLargeShutterButton

// Changing Panorama button images (For 4-inches iDevices)
+ (id)backgroundPanoOffPressedImageName
{
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h" : %orig;
}

+ (id)backgroundPanoOffImageName
{
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOn_2only_-568h" : %orig;
}

%end

%hook PLCameraPanoramaView

// Use this method to show or hide instructional text background and ghost image view
- (void)updateUI
{
	%orig;
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
	if (isSlow) {
		NSMutableDictionary *dict = [panorama mutableCopy];
		UIImage *image = (UIImage *)[dict objectForKey:@"kPLCameraPhotoPreviewImageKey"];
		UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
	}
	%orig;
}

- (void)_showSettings:(BOOL)settings sender:(id)sender
{
	%orig;
	if (PanoGridOn) {
		if (settings) {
			PLCameraSettingsView *settingsView = MSHookIvar<PLCameraSettingsView *>(self, "_settingsView");
			[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_panoramaGroup") setHidden:(isPanorama ? YES : NO)];
			[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_hdrGroup").accessorySwitch setEnabled:(isPanorama ? NO : YES)];
		}
	}
}

// Unlock Flash Button after Panorama capture
- (void)cameraControllerWillStopPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn) {
		if (autoOff)
			[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:YES];
	}
}

// Lock Flash Button when start Panorama capture
- (void)cameraControllerDidStartPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn) {
		if (autoOff)
			[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:NO];
	}
}

// Ability to zoom in Panorama mode
- (BOOL)_zoomIsAllowed
{
	if (Bool(prefDict, @"panoZoom", NO)) {
		if (isPanorama)
			return YES;
		return %orig;
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
	if (FMisOn) {
		if (isPanorama)
			return NO;
		return %orig;
	}
	return %orig;
}

// Flash and options button orientation or Panorama orientation in iPad should be only 1 (Portrait)
- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	if (isPanorama && (FMisOn || PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad))
		return 1;
	return %orig;
}

%end

%hook PLCameraLevelView

// Show or Hide Panorama Level Bar
- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideLevelBar", NO)];
	return self;
}

%end

%hook PLCameraPanoramaBrokenArrowView

// Show or Hide Panorama Arrow
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideArrow", NO)];
	return self;
}

%end

%hook PLCameraPanoramaView

- (id)initWithFrame:(CGRect)frame centerYOffset:(float)offset panoramaPreviewScale:(float)scale panoramaPreviewSize:(CGSize)size
{
	self = %orig;
	if (self) {
		[self setCaptureDirection:Int(prefDict, @"defaultDirection", 1)];
	}
	return self;
}

%end

%hook PLCameraPanoramaTextLabel

// Show/Hide Panorama instructional text
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideLabel", NO)];
	return self;
}

// Hooking Panorama instructional text
- (void)setText:(NSString *)text
{
	if (Bool(prefDict, @"customText", NO))
		%orig([prefDict objectForKey:@"myText"] ? [[prefDict objectForKey:@"myText"] description] : text);
	else %orig;
}

%end

%hook NSBundle

// Supported only English
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    if ([key isEqual:@"PANO_INSTRUCTIONAL_TEXT_iPad"])
    	return @"Move iPad continuously when taking a Panorama.";
    return %orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool drain];
}
