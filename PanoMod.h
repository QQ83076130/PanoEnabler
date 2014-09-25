#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#include <substrate.h>

#define isiOS67 (isiOS6 || isiOS7)
#define isiOS78 (isiOS7 || isiOS8)

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@property(assign, nonatomic) int cameraMode;
@end

@interface PLCameraController (Flashorama)
- (void)fm_torch:(int)type;
@end

@interface CAMCaptureController
@property(assign) AVCaptureDevice *currentDevice;
@property(assign, nonatomic) int cameraMode;
@end

@interface CAMCaptureController (Flashorama)
- (void)fm_torch:(int)type;
@end

@interface PLCameraSettingsView : UIView
@end

@interface PLIOSurfaceData : NSData
@end

@interface PLCameraFlashButton : UIButton
- (void)_expandAnimated:(BOOL)animated;
- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated;
@end

@interface PLCameraPanoramaView : UIView
- (void)setCaptureDirection:(int)direction;
- (void)_arrowWasTapped:(id)arg1;
@end

@interface CAMPanoramaView : UIView
- (void)setCaptureDirection:(int)direction;
- (void)_arrowWasTapped:(id)arg1;
@end

@interface PLCameraSettingsGroupView : UIView
@property(retain, nonatomic) UISwitch* accessorySwitch;
@end

@interface CAMFlashButton : UIControl
@property(assign, nonatomic) int flashMode;
@end

@interface CAMTopBar : UIView
- (void)setBackgroundStyle:(int)style animated:(BOOL)animated;
@end

@interface PLCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int videoFlashMode;
@property(readonly, assign, nonatomic) CAMFlashButton *_flashButton;
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@end

@interface CAMCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int videoFlashMode;
@property(readonly, assign, nonatomic) CAMFlashButton *_flashButton;
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@end

@interface UIImage (Addition)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end