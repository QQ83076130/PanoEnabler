#import "../definitions.h"
#import <substrate.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#include <sys/sysctl.h>

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@end

@interface PLCameraController (Flashorama)
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

// iOS 7+
@interface CAMFlashButton : UIControl
@end

@interface CAMTopBar : UIView
- (void)setBackgroundStyle:(int)style animated:(BOOL)animated;
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

static BOOL PanoDarkFix;
static BOOL bluePanoBtn;
static BOOL FMisOn;
static BOOL LLBPano;
static BOOL Pano8MP;
static BOOL customText;
static BOOL hideArrow;
static BOOL hideLabel;
static BOOL hideLevelBar;
static BOOL panoZoom;
static BOOL PanoGridOn;
static BOOL hideLabelBG;
static BOOL hideGhostImg;
static BOOL BPNR;

static BOOL autoOff = NO;
static BOOL isPanorama = NO;

static NSString *myText;

static int defaultDirection;
static int PreviewWidth = 306;
static int PreviewHeight = 86;

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	#define readBoolOption(prename, name) \
		name = [[dict objectForKey:prename] boolValue];
	#define readIntOption(prename, name, defaultValue) \
		name = [dict objectForKey:prename] ? [[dict objectForKey:prename] intValue] : defaultValue;
	readBoolOption(@"PanoDarkFix", PanoDarkFix);
	readBoolOption(@"bluePanoBtn", bluePanoBtn);
	readBoolOption(@"FMisOn", FMisOn);
	readBoolOption(@"LLBPano", LLBPano);
	readBoolOption(@"customText", customText);
	readBoolOption(@"hideArrow", hideArrow);
	readBoolOption(@"hideLabel", hideLabel);
	readBoolOption(@"hideLevelBar", hideLevelBar);
	readBoolOption(@"panoZoom", panoZoom);
	readBoolOption(@"PanoGridOn", PanoGridOn);
	readBoolOption(@"hideLabelBG", hideLabelBG);
	readBoolOption(@"hideGhostImg", hideGhostImg);
	readBoolOption(@"BPNR", BPNR);
	readBoolOption(@"Pano8MP", Pano8MP);
	readIntOption(@"defaultDirection", defaultDirection, 1);
	readIntOption(@"PreviewWidth", PreviewWidth, 306);
	readIntOption(@"PreviewHeight", PreviewHeight, 86);

	myText = (NSString *)[dict objectForKey:@"myText"];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	PanoModLoader();
}

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


%hook AVCaptureFigVideoDevice

// Fix dark problem in Panorama mode
- (void)setImageControlMode:(int)mode
{
	if (PanoDarkFix && mode == 4) {
		%orig(1);
		return;
	}
	%orig;
}

%end

%group FlashoramaCommon

%hook PLCameraView

// Unlock Flash Button after Panorama capture
- (void)cameraControllerWillStopPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn && autoOff) {
		if (isiOS7)
			[self._flashButton setUserInteractionEnabled:YES];
		else
			[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:YES];
	}
}

// Lock Flash Button when start Panorama capture
- (void)cameraControllerDidStartPanoramaCapture:(id)cameraController
{
	%orig;
	if (FMisOn && autoOff) {
		if (isiOS7)
			[self._flashButton setUserInteractionEnabled:NO];
		else
			[MSHookIvar<PLCameraFlashButton *>(self, "_flashButton") setUserInteractionEnabled:NO];
	}
}

// Ability to use Flash button in Panorama mode
- (BOOL)_flashButtonShouldBeHidden
{
	return FMisOn && isPanorama ? NO : %orig;
}

%end

%end

%group FlashoramaiOS6

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

%end

%hook PLCameraFlashButton

// Implementing Torch in Flash Button in Panorama mode
- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	if (FMisOn && isPanorama) {
		autoOff = (mode == 0);
		[[%c(PLCameraController) sharedInstance] torch:mode];
	}
}

%end

%end

%group actHackiOS6

%hook PLCameraView

- (void)_showSettings:(BOOL)settings sender:(id)sender
{
	%orig;
	if (PanoGridOn) {
		if (settings) {
			PLCameraSettingsView *settingsView = MSHookIvar<PLCameraSettingsView *>(self, "_settingsView");
			[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_panoramaGroup") setHidden:isPanorama];
			[MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_hdrGroup").accessorySwitch setEnabled:!isPanorama];
		}
	}
}

// Enable access Grid Option in Panorama mode
- (BOOL)_optionsButtonShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

%end

%hook PLCameraPanoramaView

- (id)initWithFrame:(CGRect)frame centerYOffset:(float)offset panoramaPreviewScale:(float)scale panoramaPreviewSize:(CGSize)size
{
	self = %orig;
	if (self) {
		[self setCaptureDirection:defaultDirection];
	}
	return self;
}

%end

%end

%group actHackiOS7

%hook PLCameraView

// Ability to enable grid in Panorama mode, iOS 7 specific
- (BOOL)_shouldHideGridView
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

%end

%hook CAMPadApplicationSpec

- (BOOL)shouldCreatePanoramaView
{
	return YES;
}

%end

%hook PLCameraPanoramaView

- (id)initWithFrame:(CGRect)frame centerYOffset:(float)offset panoramaPreviewScale:(float)scale
{
	self = %orig;
	if (self) {
		[self setCaptureDirection:defaultDirection];
	}
	return self;
}

%end

%end

%group BetterPanoButton

%hook PLCameraLargeShutterButton

// Changing Panorama button images (For 4-inches iDevices)
+ (id)backgroundPanoOffPressedImageName
{
	return @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h";
}

+ (id)backgroundPanoOffImageName
{
	return @"PLCameraLargeShutterButtonPanoOn_2only_-568h";
}

%end

%end

%group FlashoramaiOS7

%hook PLCameraController

- (void)_setFlashMode:(int)mode force:(BOOL)force
{
	if (isPanorama) {
		MSHookIvar<int>(self, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(self, "_cameraMode") = 3;
	} else
		%orig;
}

%end

%hook PLCameraView

- (BOOL)_shouldHideFlashButtonForMode:(int)mode
{
	return mode == 3 ? NO : %orig;
}

- (void)_setFlashMode:(int)mode
{
	if (isPanorama) {
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 3;
	} else
		%orig;
}

- (void)_updateFlashModeIfNecessary
{
	if (isPanorama) {
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 3;
	} else
		%orig;
}

// Add top bar in panorama mode to make the UI looks nice
- (void)_hideControlsForChangeToMode:(int)mode animated:(BOOL)animated
{
	%orig;
	if (mode == 3) {
		[self._topBar setHidden:NO];
		[self._topBar setBackgroundStyle:0 animated:YES];
	}
}

%end

%hook CAMFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	if (isPanorama)
		autoOff = (mode == 0);
}

%end

%end

%group LLBPanoCommon

%hook AVCaptureDevice

// Low Light Boost capability for Panorama
- (BOOL)isLowLightBoostSupported
{
	return YES;
}

%end

%end

%group LLBPanoiOS6

%hook PLCameraController

// Enable Low Light Boost if in Panorama mode
- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (mode == 2 && device == 0) {
		[self.currentDevice lockForConfiguration:nil];
		if ([self.currentDevice isLowLightBoostSupported])
			[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
		[self.currentDevice unlockForConfiguration];
	}
}

%end

%end

%group LLBPanoiOS7

%hook PLCameraController

- (void)_setupPanoramaForDevice:(id)device output:(id)output options:(id)options
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[self.currentDevice lockForConfiguration:nil];
		if ([self.currentDevice isLowLightBoostSupported])
			[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
		[self.currentDevice unlockForConfiguration];
	});
}

%end

%end

%group Pano8MP

%hook AVCaptureSession

+ (NSDictionary *)avCaptureSessionPlist
{
	NSMutableDictionary *avRoot = [%orig mutableCopy];
	NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
	NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
	NSMutableDictionary *presetPhoto = [[index0 objectForKey:@"AVCaptureSessionPresetPhoto2592x1936"] mutableCopy];
	if (presetPhoto == nil)
		return %orig;
	NSMutableDictionary *liveSourceOptions = [[presetPhoto objectForKey:@"LiveSourceOptions"] mutableCopy];
	NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									num(3264), @"Width",
    									@"420f", @"PixelFormatType",
    									num(2448), @"Height", nil];
	[liveSourceOptions setObject:res forKey:@"Sensor"];
	[liveSourceOptions setObject:res forKey:@"Capture"];
	[presetPhoto setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
	[index0 setObject:presetPhoto forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	[avCap replaceObjectAtIndex:0 withObject:index0];
	[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
	return (NSDictionary *)avRoot;
}

%end

%end

%hook PLCameraController

// Set Panorama Preview Size
// Default value is {306, 86}
// iPad recommended maximum width is 576 px
// iPhone recommended maximum height is 640 px
- (struct CGSize)panoramaPreviewSize
{
	return CGSizeMake(PreviewWidth, PreviewHeight);
}

// Detect Camera mode
- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isPanorama = NO;
	if (device == 0) {
		if (isiOS7) {
			if (mode == 3)
				isPanorama = YES;
		} else {
			if (mode == 2)
				isPanorama = YES;
		}
	}
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

%hook PLCameraPanoramaView

// Use this method to show or hide instructional text background and ghost image view
- (void)updateUI
{
	%orig;
	UIView *labelBG = MSHookIvar<UIView *>(self, "_instructionalTextBackground");
	UIImageView *ghostImg = MSHookIvar<UIImageView *>(self, "_previewGhostImageView");
	[labelBG setHidden:hideLabelBG];
	[ghostImg setHidden:hideGhostImg];
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

// Ability to zoom in Panorama mode
- (BOOL)_zoomIsAllowed
{
	return panoZoom && isPanorama ? YES : %orig;
}

// Ability to enable grid in Panorama mode
- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

// Flash and options button orientation or Panorama orientation in iPad should be only 1 (Portrait)
- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	return (isPanorama && (FMisOn || PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? 1 : %orig;
}

%end

%hook PLCameraLevelView

// Show or Hide Panorama Level Bar
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLevelBar];
	return self;
}

%end

%hook PLCameraPanoramaBrokenArrowView

// Show or Hide Panorama Arrow
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideArrow];
	return self;
}

%end

%hook PLCameraPanoramaTextLabel

// Show/Hide Panorama instructional text
- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLabel];
	return self;
}

// Hooking Panorama instructional text
- (void)setText:(NSString *)text
{
	if (customText)
		%orig((myText != nil) ? myText : text);
	else
		%orig;
}

%end

%hook NSBundle

// Supported only English
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    return [key isEqualToString:@"PANO_INSTRUCTIONAL_TEXT_iPad"] ? @"Move iPad continuously when taking a Panorama." : %orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	if (isiOS6) {
		%init(actHackiOS6);
		%init(FlashoramaiOS6);
		%init(BetterPanoButton);
		%init(LLBPanoiOS6);
	}
	else if (isiOS7) {
		%init(actHackiOS7);
		%init(FlashoramaiOS7);
		%init(LLBPanoiOS7);
	}
	%init(LLBPanoCommon);
	%init(FlashoramaCommon);
	NSString *model = Model();
	if (is8MPCamDevice && Pano8MP) {
		%init(Pano8MP);
	}
	%init();
	[pool drain];
}
