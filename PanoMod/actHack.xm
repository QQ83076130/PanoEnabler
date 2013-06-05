#import "../definitions.h"
#import <substrate.h>
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


%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported
{
	return Bool(prefDict, @"LLBPano", NO) ? YES : %orig;
}

%end

%hook AVCaptureFigVideoDevice

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
	NSMutableDictionary *cameraProperties = [captureOptionsDictionary mutableCopy];
	NSMutableDictionary *liveSourceOptions = [[cameraProperties objectForKey:@"LiveSourceOptions"] mutableCopy];
	if (([[[cameraProperties objectForKey:@"Description"] description] isEqualToString:@"Back Facing 5MP Photo"] ||
		[[[cameraProperties objectForKey:@"Description"] description] isEqualToString:@"Back Facing 1MP Photo"] ||
		[[[cameraProperties objectForKey:@"Description"] description] isEqualToString:@"3MP Photo"]) &&
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
	if (lockFlashButton && FMisOn);
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
	return CGSizeMake(valueFromKey(prefDict, @"PreviewWidth", 306), valueFromKey(prefDict, @"PreviewHeight", 86));
}

// Flashorama works only in Panorama mode
- (void)_setCameraMode:(int)mode cameraDevice:(int)arg2
{
	if (mode == 2 && arg2 == 0)
		isPanorama = YES;
	else
		isPanorama = NO;
	%orig;
}

- (void)startPanoramaCapture
{
	if (autoOff && FMisOn) {
		[[%c(PLCameraController) sharedInstance] torch:1];
		lockFlashButton = YES;
	}
	%orig;
}

- (void)stopPanoramaCapture
{
	if (autoOff && FMisOn) {
		[[%c(PLCameraController) sharedInstance] torch:2];
		lockFlashButton = NO;
	}
	%orig;
}

%end

%hook PLCameraLargeShutterButton

+ (id)backgroundPanoOffPressedImageName
{
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h" : %orig;
}

+ (id)backgroundPanoOffImageName
{
	return Bool(prefDict, @"bluePanoBtn", NO) ? @"PLCameraLargeShutterButtonPanoOn_2only_-568h" : %orig;
}

- (void)setIsCapturing:(BOOL)arg1 { if (arg1) isCapturing = YES; else isCapturing = NO; %orig; }

%end

%hook PLCameraButton

- (void)setIsCapturing:(BOOL)arg1 { if (arg1) isCapturing = YES; else isCapturing = NO; %orig; }

%end

%hook PLCameraPanoramaView

- (void)_updateInstructionalText:(id)arg1
{
	%orig;
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
    if ([device isLowLightBoostSupported])
    	[device setAutomaticallyEnablesLowLightBoostWhenAvailable:Bool(prefDict, @"LLBPano", nil)];
    [device unlockForConfiguration];
}

// Ability to zoom in Panorama mode
- (BOOL)_zoomIsAllowed
{
	return isPanorama && Bool(prefDict, @"panoZoom", NO) ? YES : %orig;
}

// Ability to use Flash button in Panorama mode
- (BOOL)_flashButtonShouldBeHidden
{
	return isPanorama && FMisOn ? NO : %orig;
}

// Flash button orientation and Panorama orientation in iPad should be only 1 (Portrait)
- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	return isPanorama && (FMisOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1 : %orig;
}

%end

%hook PLCameraLevelView

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideLevelBar", NO)];
	return self;
}

%end

%hook PLCameraPanoramaBrokenArrowView

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideArrow", NO)];
	return self;
}

%end

%hook PLCameraPanoramaTextLabel

- (id)initWithFrame:(struct CGRect)arg1
{
	self = %orig;
	if (self)
		[self setHidden:Bool(prefDict, @"hideLabel", NO)];
	return self;
}

- (void)setText:(id)text
{
	if (Bool(prefDict, @"customText", NO))
		%orig([[prefDict objectForKey:@"myText"] description] ?: text);
	else %orig;
}

%end

%hook NSBundle

// Supported only English
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    if ([key isEqual:@"PANO_INSTRUCTIONAL_TEXT_iPad"]) return @"Move iPad continuously when taking a Panorama.";
    return %orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}

// vim:ft=objc
