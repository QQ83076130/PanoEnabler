#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#include <substrate.h>

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@property(assign, nonatomic) int cameraMode;
@end

@interface PLCameraController (Flashorama)
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

@interface PLCameraPanoramaView
- (void)setCaptureDirection:(int)direction;
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
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

@interface UIImage (Addition)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end