#import "../definitions.h"
#import <substrate.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@property(assign, nonatomic) int cameraMode;
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

@interface CAMFlashButton : UIControl
@end

@interface CAMTopBar : UIView
- (void)setBackgroundStyle:(int)style animated:(BOOL)animated;
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

static BOOL PanoEnabled, PanoDarkFix, bluePanoBtn, FMisOn, LLBPano, Pano8MP, customText, hideArrow, hideLabel, hideLevelBar, panoZoom, PanoGridOn, hideLabelBG, hideGhostImg, BPNR;

static BOOL autoOff = NO;
static BOOL isPanorama = NO;

static NSString *myText = nil;

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
	readBoolOption(@"PanoEnabled", PanoEnabled);
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
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}


%hook AVCaptureFigVideoDevice

- (void)setImageControlMode:(int)mode
{
	%orig((PanoDarkFix && mode == 4) ? 1 : mode);
}

%end

%group FlashoramaCommon

%hook PLCameraController

%new(v@:)
- (void)torch:(int)type
{
	if ([self.currentDevice hasTorch]) {
		[self.currentDevice lockForConfiguration:nil];
		[self.currentDevice setTorchMode:((type == 1) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
		[self.currentDevice unlockForConfiguration];
	}
}

%end

%hook PLCameraView

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

- (BOOL)_flashButtonShouldBeHidden
{
	return FMisOn && isPanorama ? NO : %orig;
}

%end

%end

%group FlashoramaiOS6

%hook PLCameraFlashButton

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

- (BOOL)_optionsButtonShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

%end

%hook PLCameraPanoramaView

- (id)initWithFrame:(CGRect)frame centerYOffset:(float)offset panoramaPreviewScale:(float)scale panoramaPreviewSize:(CGSize)size
{
	self = %orig;
	if (self)
		[self setCaptureDirection:defaultDirection];
	return self;
}

%end

%end

%group actHackiOS7Pad

static BOOL padTextHook = NO;

%hook UIDevice

- (NSString *)model
{
	NSString *model = Model();
	return isiPad && padTextHook ? @"iPhone" : %orig;
}

%end

%hook PLCameraPanoramaView

- (void)_updateInstructionalText:(NSString *)text
{
	NSString *model = Model();
	%orig(isiPad && padTextHook ? [text stringByReplacingOccurrencesOfString:@"iPhone" withString:@"iPad"] : text);
}

%end

%hook PLCameraView

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	padTextHook = YES;
	%orig;
	padTextHook = NO;
}

%end

%end

%group actHackiOS7

%hook PLCameraView

- (BOOL)_shouldHideGridView
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	%orig;
	PLCameraPanoramaView *panoramaView = MSHookIvar<PLCameraPanoramaView *>(self, "_panoramaView");
	if (panoramaView != nil) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[panoramaView setCaptureDirection:defaultDirection];
		});
	}
}

%end

%hook CAMPadApplicationSpec

- (BOOL)shouldCreatePanoramaView
{
	return PanoEnabled ? YES : %orig;
}

%end

%end

%group BetterPanoButton

%hook PLCameraLargeShutterButton

+ (id)backgroundPanoOffPressedImageName
{
	return bluePanoBtn ? @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h" : %orig;
}

+ (id)backgroundPanoOffImageName
{
	return bluePanoBtn ? @"PLCameraLargeShutterButtonPanoOn_2only_-568h" : %orig;
}

%end

%end

%group FlashoramaiOS7

%hook PLCameraController

- (void)_setFlashMode:(int)mode force:(BOOL)force
{
	if (self.cameraMode == 3) {
		MSHookIvar<int>(self, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(self, "_cameraMode") = 3;
		return;
	}
	%orig;
}

%end

%hook PLCameraView

- (int)_topBarBackgroundStyleForMode:(int)mode
{
	return mode == 3 && FMisOn ? 3 : %orig;
}

- (BOOL)_shouldEnableFlashButton
{
	return isPanorama && FMisOn ? YES : %orig;
}

- (BOOL)_shouldHideFlashButtonForMode:(int)mode
{
	return mode == 3 && FMisOn ? NO : %orig;
}

- (BOOL)_shouldHideTopBarForMode:(int)mode
{
	return mode == 3 && FMisOn ? NO : %orig;
}

%end

%hook CAMFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)arg2
{
	%orig;
	autoOff = (mode == 0);
}

%end

%end

%group LLBPanoCommon

%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported
{
	return LLBPano ? YES : %orig;
}

%end

%end

%group LLBPanoiOS6

%hook PLCameraController

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
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		if (!LLBPano)
			return;
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

%group PanoFPS

%hook AVCaptureSession

+ (NSDictionary *)avCaptureSessionPlist
{
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSMutableDictionary *avRoot = [%orig mutableCopy];
	NSMutableArray *avCap = [[avRoot objectForKey:@"AVCaptureDevices"] mutableCopy];
	NSMutableDictionary *index0 = [[avCap objectAtIndex:0] mutableCopy];
	NSMutableDictionary *presetPhoto = [[index0 objectForKey:@"AVCaptureSessionPresetPhoto2592x1936"] mutableCopy];
	if (presetPhoto == nil)
		return %orig;
	NSMutableDictionary *liveSourceOptions = [[presetPhoto objectForKey:@"LiveSourceOptions"] mutableCopy];
	[liveSourceOptions setObject:num(val(prefDict, @"PanoramaMaxFrameRate", 24, INT)) forKey:@"MaxFrameRate"];
	[liveSourceOptions setObject:num(val(prefDict, @"PanoramaMinFrameRate", 15, INT)) forKey:@"MinFrameRate"];
	[presetPhoto setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
	[index0 setObject:presetPhoto forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	[avCap replaceObjectAtIndex:0 withObject:index0];
	[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
	return (NSDictionary *)avRoot;
}

%end

%end

%hook PLCameraController

// Default value is {306, 86}
// iPad recommended maximum width is 576 px
// iPhone recommended maximum height is 640 px
- (struct CGSize)panoramaPreviewSize
{
	return CGSizeMake(PreviewWidth, PreviewHeight);
}

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

- (void)startPanoramaCapture
{
	if (FMisOn) {
		if (autoOff)
			[self torch:1];
	}
	%orig;
}

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

// Super important hooking to save Panoramic image in A4 iDevices!
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

- (BOOL)_zoomIsAllowed
{
	return panoZoom && isPanorama ? YES : %orig;
}

- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	return (isPanorama && (FMisOn || PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? 1 : %orig;
}

%end

%hook PLCameraLevelView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLevelBar];
	return self;
}

%end

%hook PLCameraPanoramaBrokenArrowView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideArrow];
	return self;
}

%end

%hook PLCameraPanoramaTextLabel

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLabel];
	return self;
}

- (void)setText:(NSString *)text
{
	%orig((customText && myText != nil) ? myText : text);
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	NSString *model = Model();
	if (isiOS6) {
		%init(actHackiOS6);
		%init(FlashoramaiOS6);
		%init(BetterPanoButton);
		%init(LLBPanoiOS6);
	}
	else if (isiOS7) {
		%init(actHackiOS7);
		if (isiPad) {
			%init(actHackiOS7Pad);
		}
		%init(FlashoramaiOS7);
		%init(LLBPanoiOS7);
	}
	%init(LLBPanoCommon);
	%init(FlashoramaCommon);
	if (is8MPCamDevice && Pano8MP) {
		%init(Pano8MP);
	}
	%init(PanoFPS);
	%init();
	[pool drain];
}
