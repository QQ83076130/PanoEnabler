#import "../definitions.h"
#import "../PanoMod.h"
#import <sys/utsname.h>

static BOOL PanoEnabled, PanoDarkFix, bluePanoBtn, FMisOn, LLBPano, Pano8MP, customText, hideArrow, hideLabel, hideLevelBar, panoZoom, PanoGridOn, hideLabelBG, hideGhostImg, BPNR, noArrowTail;

static BOOL autoOff = NO;
static BOOL isPanorama = NO;

static NSString *myText = nil;

static int defaultDirection;
static int PreviewWidth = 306;
static int PreviewHeight = 86;

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
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
	readBoolOption(@"panoGrid", PanoGridOn);
	readBoolOption(@"hideLabelBG", hideLabelBG);
	readBoolOption(@"hideGhostImg", hideGhostImg);
	readBoolOption(@"BPNR", BPNR);
	readBoolOption(@"Pano8MP", Pano8MP);
	readBoolOption(@"noArrowTail", noArrowTail);
	readIntOption(@"defaultDirection", defaultDirection, 0);
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

static void enableLLB(id self)
{
	if (!LLBPano)
		return;
	[[self currentDevice] lockForConfiguration:nil];
	if ([[self currentDevice] isLowLightBoostSupported])
		[[self currentDevice] setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
	[[self currentDevice] unlockForConfiguration];
}

%group FlashoramaCommonPre8

%hook PLCameraController

- (void)startPanoramaCapture
{
	if (FMisOn) {
		if (autoOff)
			[self fm_torch:1];
	}
	%orig;
}

%end

%hook PLCameraView

- (BOOL)_flashButtonShouldBeHidden
{
	return FMisOn && isPanorama ? NO : %orig;
}

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

%end

%end

%group FlashoramaCommon

%hook CAMERACONTROLLER

%new(v@:)
- (void)fm_torch:(int)type
{
	if ([[self currentDevice] hasTorch]) {
		[[self currentDevice] lockForConfiguration:nil];
		[[self currentDevice] setTorchMode:((type == 1) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
		[[self currentDevice] unlockForConfiguration];
	}
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
		[[%c(PLCameraController) sharedInstance] fm_torch:mode];
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

%group actHackiOS7UpPad

static BOOL padTextHook = NO;

%hook UIDevice

- (NSString *)model
{
	NSString *model = Model();
	return isiPad && padTextHook ? @"iPhone" : %orig;
}

%end

%hook PANORAMAVIEW

- (void)_updateInstructionalText:(NSString *)text
{
	NSString *model = Model();
	%orig(isiPad && padTextHook ? [text stringByReplacingOccurrencesOfString:@"iPhone" withString:@"iPad"] : text);
}

%end

%hook CAMERAVIEW

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	padTextHook = YES;
	%orig;
	padTextHook = NO;
}

%end

%end

%group actHackiOS7Up

%hook CAMERAVIEW

- (BOOL)_shouldHideGridView
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	%orig;
	id panoramaView = nil;
	panoramaView = isiOS8 ? (id)MSHookIvar<CAMPanoramaView *>(self, "_panoramaView") : (id)MSHookIvar<PLCameraPanoramaView *>(self, "_panoramaView");
	if (panoramaView != nil) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[panoramaView _arrowWasTapped:nil];
			int direction = MSHookIvar<int>(panoramaView, "_direction");
			if (defaultDirection != direction) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[(id)panoramaView _arrowWasTapped:nil];
				});
			}
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

%hook PLCameraView

- (void)flashButtonModeDidChange:(CAMFlashButton *)change
{
	if (!isPanorama) {
		%orig;
		return;
	}
	PLCameraController *cont = MSHookIvar<PLCameraController* >(self, "_cameraController");
	MSHookIvar<int>(cont, "_cameraMode") = 1;
	%orig;
	MSHookIvar<int>(cont, "_cameraMode") = 3;
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

%group FlashoramaiOS7Up

%hook CAMERACONTROLLER

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

%hook CAMERAVIEW

- (int)_currentFlashMode
{
	return [self cameraMode] == 3 ? [self videoFlashMode] : %orig;
}

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

%end

%group FlashoramaiOS8

%hook CAMFlashButton

- (void)setFlashMode:(int)mode
{
	%orig;
	autoOff = (mode == 0);
}

%end

%hook CAMCameraView

- (void)_capturePanorama
{
	if (FMisOn) {
		if (autoOff)
			[[%c(CAMCaptureController) sharedInstance] fm_torch:1];
	}
	%orig;
}

%new
- (void)cameraControllerWillStopPanoramaCapture:(id)cameraController
{
	if (FMisOn && autoOff)
		[self._flashButton setUserInteractionEnabled:YES];
}

%new
- (void)cameraControllerDidStartPanoramaCapture:(id)cameraController
{
	if (FMisOn && autoOff)
		[self._flashButton setUserInteractionEnabled:NO];
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
		enableLLB(self);
	}
}

%end

%end

%group LLBPanoiOS7

%hook PLCameraController

- (void)_setupPanoramaForDevice:(id)device output:(id)output options:(id)options
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		enableLLB(self);
	});
}

%end

%end

%group LLBPanoiOS8

%hook CAMCaptureController

- (void)_deviceConfigurationForPanoramaOptions:(NSDictionary *)options captureDevice:(id)device deviceFormat:(id *)format minFrameDuration:(id *)min maxFrameDuration:(id *)max
{
	%orig;
	enableLLB(self);
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
    									Pano8MP ? @(3264) : @(2592), @"Width",
    									@"420f", @"PixelFormatType",
    									Pano8MP ? @(2448) : @(1936), @"Height", nil];
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

%group Common

%hook AVCaptureFigVideoDevice

- (void)setImageControlMode:(int)mode
{
	%orig((PanoDarkFix && mode == 4) ? 1 : mode);
}

%end

%hook CAMERACONTROLLER

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
		if (isiOS7Up) {
			if (mode == 3)
				isPanorama = YES;
		} else {
			if (mode == 2)
				isPanorama = YES;
		}
	}
	%orig;
}

- (void)stopPanoramaCapture
{
	if (FMisOn) {
		if (autoOff)
			[self fm_torch:-1];
	}
	%orig;
}

%end

%hook CAMERAVIEW

- (BOOL)_zoomIsAllowed
{
	return panoZoom && isPanorama ? YES : %orig;
}

- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	return (isPanorama && (FMisOn || PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? 1 : %orig;
}

%end

%end

%group CommonPre8

%hook PLCameraView

- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
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

- (CGPathRef)_newTailPiecesPathOfWidth:(float *)width
{
	return noArrowTail ? nil : %orig;
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

%hook PLCameraLevelView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLevelBar];
	return self;
}

%end

%end

%group Common8

%hook CAMCameraView

- (BOOL)_shouldHideGridView
{
	if (isPanorama && PanoGridOn) {
		MSHookIvar<int>([%c(CAMCaptureController) sharedInstance], "_cameraMode") = 0;
		BOOL r = %orig;
		MSHookIvar<int>([%c(CAMCaptureController) sharedInstance], "_cameraMode") = 3;
		return r;
	}
	return %orig;
}

%end

%hook CAMPanoramaArrowView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideArrow];
	return self;
}

- (CGPathRef)_newTailPiecesPathOfWidth:(float *)width
{
	return noArrowTail ? nil : %orig;
}

%end

%hook CAMPanoramaView

- (void)updateUI
{
	%orig;
	UIView *labelBG = MSHookIvar<UIView *>(self, "_instructionalTextBackground");
	UIImageView *ghostImg = MSHookIvar<UIImageView *>(self, "_previewGhostImageView");
	[labelBG setHidden:hideLabelBG];
	[ghostImg setHidden:hideGhostImg];
}

%end

%hook CAMPanoramaLabel

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

%hook CAMPanoramaLevelView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		[self setHidden:hideLevelBar];
	return self;
}

%end

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	NSString *model = Model();
	Class CameraController = isiOS8 ? objc_getClass("CAMCaptureController") : objc_getClass("PLCameraController");
	Class CameraView = isiOS8 ? objc_getClass("CAMCameraView") : objc_getClass("PLCameraView");
	if (isiOS6) {
		%init(actHackiOS6);
		%init(FlashoramaiOS6);
		%init(BetterPanoButton);
		%init(LLBPanoiOS6);
	}
	else if (isiOS7) {
		%init(FlashoramaiOS7);
		%init(LLBPanoiOS7);
	}
	else if (isiOS8) {
		%init(Common8);
		%init(FlashoramaiOS8);
		%init(LLBPanoiOS8);
	}
	
	if (isiOS67) {
		%init(FlashoramaCommonPre8);
		%init(CommonPre8);
	}
	if (isiOS78) {
		%init(actHackiOS7Up, CAMERAVIEW = CameraView);
		%init(FlashoramaiOS7Up, CAMERAVIEW = CameraView, CAMERACONTROLLER = CameraController);
		if (isiPad) {
			%init(actHackiOS7UpPad, CAMERAVIEW = CameraView, PANORAMAVIEW = isiOS8 ? objc_getClass("CAMPanoramaView") : objc_getClass("PLCameraPanoramaView"));
		}
	}

	%init(LLBPanoCommon);
	%init(FlashoramaCommon, CAMERACONTROLLER = CameraController);
	if (is8MPCamDevice) {
		%init(Pano8MP);
	}
	%init(Common, CAMERAVIEW = CameraView, CAMERACONTROLLER = CameraController);
	[pool drain];
}
