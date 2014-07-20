#import "../definitions.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

#include <objc/runtime.h>
#include <sys/sysctl.h>
#import <notify.h>

@interface PSViewController (PanoMod)
- (void)setView:(id)view;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
@end

@interface UITableViewCell (PanoMod)
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier;
@end

@interface PSTableCell (PanoMod)
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier;
@end

#define kFontSize 14.0f
#define CELL_CONTENT_MARGIN 20.0f
#define PanoModBrief \
@"Enable Panorama on every unsupported iOS 6 - 7 devices.\n\
Then Customize the interface and properties of Panorama with PanoMod."

#define Id [[spec properties] objectForKey:@"id"]

#define getSpec(mySpec, string)	if ([Id isEqualToString:string]) \
                			self.mySpec = [spec retain];


#define updateValue(targetSpec, sliderSpec, string) 		[self.targetSpec setProperty:[NSString stringWithFormat:string, [[self readPreferenceValue:self.sliderSpec] intValue]] forKey:@"footerText"]; \
  															[self reloadSpecifier:self.targetSpec animated:YES]; \
  															[self reloadSpecifier:self.sliderSpec animated:YES];

#define updateFloatValue(targetSpec, sliderSpec, string) 	[self.targetSpec setProperty:[NSString stringWithFormat:string, round([[self readPreferenceValue:self.sliderSpec] floatValue]*100.0)/100.0] forKey:@"footerText"]; \
  															[self reloadSpecifier:self.targetSpec animated:YES]; \
  															[self reloadSpecifier:self.sliderSpec animated:YES];

#define resetValue(intValue, spec, inputSpec) 	[self setPreferenceValue:@(intValue) specifier:self.spec]; \
												[self setPreferenceValue:[@(intValue) stringValue] specifier:self.inputSpec]; \
												[self reloadSpecifier:self.spec animated:YES]; \
												[self reloadSpecifier:self.inputSpec animated:YES];

#define orig	[self setPreferenceValue:value specifier:spec]; \
				[[NSUserDefaults standardUserDefaults] synchronize];
				
static void openLink(NSString *url)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
				
#define rangeFix(min, max) \
	int value2 = @([value intValue]).intValue; \
	if (value2 > max) \
		value = @(max); \
	else if (value2 < min) \
		value = @(min); \
	else value = @([value intValue]);

#define rangeFixFloat(min, max) \
	float value2 = @([value floatValue]).floatValue; \
	if (value2 > max) \
		value = @(max); \
	else if (value2 < min) \
		value = @(min); \
	else value = @(round([value floatValue]*100)/100);
									
static void setAvailable(BOOL available, PSSpecifier *spec)
{
	[spec setProperty:@(available) forKey:@"enabled"];
}

static void update()
{
	/*if (isiOS7) {
		CFPropertyListRef settings = CFPreferencesCopyValue(CFSTR("CameraStreamInfo"), CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("CameraStreamInfo"), settings, CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize(CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
	}*/
	system("killall Camera");
	notify_post("com.ps.panomod.roothelper");
}

static NSString *Model()
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char* answer = (char *)malloc(size);
	sysctlbyname("hw.machine", answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}


@interface actHackPreferenceController : PSListController
@property (nonatomic, retain) PSSpecifier *PanoEnabledSpec;
@end

@implementation actHackPreferenceController

- (void)setBoolAndKillCam:(id)value specifier:(PSSpecifier *)spec
{
	orig
	update();
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"PanoPreferences" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(PanoEnabledSpec, @"PanoEnabled")
		}
        
		NSString *model = Model();
		if (isiPhone4S || isiPhone5Up || isiPod5)
			[specs removeObject:self.PanoEnabledSpec];
	
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@interface BannerCell : PSTableCell <UITextViewDelegate> {
	UIView *headerImageViewContainer;
	UIImageView *headerImageView;
}
@end
 
@implementation BannerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier
{	
	if (self == [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier specifier:specifier]) {
		headerImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		headerImageViewContainer.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			headerImageViewContainer.layer.cornerRadius = 5;

		headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"banner.png" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/PanoPreferences.bundle"]]];
		headerImageViewContainer.backgroundColor = [UIColor clearColor];
		headerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[headerImageViewContainer addSubview:headerImageView];
		[self addSubview:headerImageViewContainer];
	}
	return self;
}

@end

@interface PanoFAQViewController : PSViewController
- (UITableView *)tableView;
@end

@interface PanoFAQViewController () <UITableViewDelegate, UITableViewDataSource> {}
@end

@implementation PanoFAQViewController

- (NSString *)title
{
	return @"FAQ";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0: return @"PanoMod";
		case 1: return @"(iPad) Sometimes camera view flashes frequently when taking Panorama";
		case 2: return @"Panorama sometimes still dark even with \"Pano Dark Fix\" enabled";
		case 3: return @"(iOS 7, unsupported devices) Panorama doesn't work in Lockscreen Camera";
		case 4: return @"Supported iOS Versions";
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PanoFAQCell"];
    
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"PanoFAQCell"] autorelease];
		[cell.textLabel setNumberOfLines:0];
		[cell.textLabel setBackgroundColor:[UIColor clearColor]];
		[cell.textLabel setFont:[UIFont systemFontOfSize:kFontSize]];
		[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
	}
    
	switch (indexPath.section)
	{
		case 0:	[cell.textLabel setText:PanoModBrief]; break;
		case 1: [cell.textLabel setText:@"This issue related with AE or Auto Exposure of Panorama, if you lock AE (Long tap the camera preview) will temporary fix the issue."]; break;
		case 2: [cell.textLabel setText:@"This issue related with memory and performance."]; break;
		case 3: [cell.textLabel setText:@"The limitation of hooking methods in iOS 7 causes this."]; break;
		case 4: [cell.textLabel setText:@"iOS 6.0 - 7.1"]; break;
    }
    return cell;
}

@end

@interface PanoGuideViewController : PSViewController
- (UITableView *)tableView;
@end

@interface PanoGuideViewController () <UITableViewDelegate, UITableViewDataSource> {}
@end

@implementation PanoGuideViewController

- (NSString *)title
{
	return @"Guide";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 1: return @"Enable Panorama";
		case 2: return @"Panoramic Images Maximum Width";
		case 3: return @"Preview Width & Preview Height";
		case 4: return @"Min & Max Framerate";
		case 5: return @"ACTPanorama(BufferRingSize, PowerBlurBias, PowerBlurSlope)";
		case 6: return @"Panorama Default Direction";
		case 7: return @"Instructional Text";
		case 8: return @"Enable Zoom";
		case 9: return @"Enable Grid";
		case 10: return @"Blue Button";
		case 11: return @"Panorama Low Light Boost";
		case 12: return @"Fix Dark issue";
		case 13: return @"Ability to Toggle Torch";
		case 14: return @"White Arrow";
		case 15: return @"Blue line in the middle";
		case 16: return @"White Border";
		case 17: return @"Panorama 8 MP";
		case 18: return @"Panorama BPNR Mode";
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   	return 19;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *ident = [NSString stringWithFormat:@"j%li", (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil) {
    	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
    	[cell.textLabel setNumberOfLines:0];
    	[cell.textLabel setBackgroundColor:[UIColor clearColor]];
    	[cell.textLabel setFont:[UIFont systemFontOfSize:kFontSize]];
        [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    }
	switch (indexPath.section) {
		case 0:
			[cell.textLabel setText:@"We will explain each option how they work."]; break;
		case 1:
			[cell.textLabel setText:@"Only available if iDevice doesn't support Panorama by default, by injecting some code that tell Camera this device supported Panorama."]; break;
		case 2:
			[cell.textLabel setText:@"Adjust the maximum panoramic image width."]; break;
 		case 3:
			[cell.textLabel setText:@"Adjust the Panorama Preview sizes in the middle, default value, 306 pixel Width and 86 pixel Height.\nKeep in mind that this function doesn’t work well with iPads when Preview Width is more than the original value."]; break;
		case 4:
			[cell.textLabel setText:@"Adjust the FPS of Panorama, but keep in mind in that don’t set it too high or too low or you may face the pink preview issue or camera crashing."]; break;
		case 5:
			[cell.textLabel setText:@"Some Panorama properties, just included them if you want to play around."]; break;
		case 6:
			[cell.textLabel setText:@"Set the default arrow direction when you enter Panorama mode."]; break;
		case 7:
			[cell.textLabel setText:@"This is what Panorama talks to you, when you capture Panorama, this function provided some customization including Hide Text, Hide BG (Hide Black translucent background, iOS 6 only) and Custom Text. (Set it to whatever you want)"]; break;
		case 8:
			[cell.textLabel setText:@"Enabling ability to zoom in Panorama mode.\nNOTE: This affects on panoramic image in iOS 7"]; break;
		case 9:
			[cell.textLabel setText:@"Showing grid in Panorama mode."]; break;
		case 10:
			[cell.textLabel setText:@"iOS 6 only, like \"Better Pano Button\" that changes your Panorama button color for 4-inches Tall-iDevices to blue."]; break;
  		case 11:
			[cell.textLabel setText:@"Like \"LLBPano\", works only in Low Light Boost-capable iDevices or only iPhone 5 and iPod touch 5G, fix dark issue using Low Light Boost method.\nFor iPod touch 5G users, you must have tweak \"LLBiPT5\" installed first."]; break;
		case 12:
			[cell.textLabel setText:@"For those iDevices without support Low Light Boost feature, this function will fix the dark issue in the another way and it works for all iDevices and you will see the big different in camera brightness/lighting performance.\nBut reason why Apple limits the brightness is simple, to fix Panorama overbright issue that you can face it in daytime."]; break;
		case 13:
			[cell.textLabel setText:@"Like \"Flashorama\" that allows you to toggle torch using Flash button in Panorama mode.\nSupported for iPhone or iPod with LED-Flash capable."]; break;
		case 14:
			[cell.textLabel setText:@"The white arrow that follows you when you move around to capture Panorama, you can hide it or remove its tail animation."]; break;
		case 15:
			[cell.textLabel setText:@"Hiding the blue (iOS 6) or yellow (iOS 7) horizontal line at the middle of screen, if you don't want it."]; break;
		case 16:
			[cell.textLabel setText:@"iOS 6 only, Hiding the border crops the small Panorama preview, sometimes this function is recommended to enable when you set Panoramic images maximum width into different values."]; break;
		case 17:
			[cell.textLabel setText:@"By default, the Panorama sensor resolution is 5 MP, this option can changes the sensor resolution to 8 MP if your device is capable. (iPhone 4S or newer) This makes the panoramic images more clear."]; break;
		case 18:
			[cell.textLabel setText:@"iOS 7 only, \"BPNR\" or Auto exposure adjustments during the pan of Panorama capture, was introduced in iPhone 5s, to even out exposure in scenes where brightness varies across the frame."]; break;
  	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), MAXFLOAT);
	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] textLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
	return size.height + CELL_CONTENT_MARGIN;
}

@end

@interface PanoCreditsViewController : PSViewController
- (UITableView *)tableView;
@end

@interface PanoCreditsViewController () <UITableViewDelegate, UITableViewDataSource> {}
@end

@implementation PanoCreditsViewController

- (NSString *)title
{
	return @"Thanks";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 14;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	switch (indexPath.row)
	{
		case 0:
			openLink(@"https://twitter.com/PoomSmart"); break;
		case 1:
			openLink(@"https://twitter.com/Pix3lDemon"); break;
		case 2:
			openLink(@"https://twitter.com/BassamKassem1"); break;
		case 3:
			openLink(@"https://twitter.com/H4lfSc0p3R"); break;
		case 4:
			openLink(@"https://twitter.com/iPMisterX"); break;
		case 5:
			openLink(@"https://twitter.com/nenocrack"); break;
		case 6:
			openLink(@"https://twitter.com/Raem0n"); break;
		case 7:
			openLink(@"https://twitter.com/NTD123"); break;
		case 8:
			openLink(@"https://www.facebook.com/itenb?fref=ts"); break;
		case 9:
			openLink(@"https://twitter.com/xtoyou"); break;
		case 10:
			openLink(@"https://twitter.com/n4te2iver"); break;
		case 11:
			openLink(@"https://twitter.com/NavehIDL"); break;
		case 12:
			openLink(@"https://www.facebook.com/omkung?fref=ts"); break;
		case 13:
			openLink(@"https://twitter.com/iPFaHaD"); break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *const ident = [NSString stringWithFormat:@"u%li", (long)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
		cell.textLabel.numberOfLines = 0;
		cell.detailTextLabel.numberOfLines = 0;
		[cell.textLabel setBackgroundColor:[UIColor clearColor]];
		[cell.textLabel setFont:[UIFont boldSystemFontOfSize:kFontSize + 2]];
		[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
	}
	
	#define addPerson(numCase, TextLabel, DetailTextLabel) \
	case numCase: \
	{ \
		cell.detailTextLabel.text = DetailTextLabel; \
		cell.textLabel.text = TextLabel; \
		break; \
	}
	
	switch (indexPath.row)
	{
		addPerson(0, 	@"@PoomSmart (Main Dev)", 	@"Tested: iPod touch 4G, iPod touch 5G, iPhone 4S, iPad 2G (GSM).")
		addPerson(1, 	@"@Pix3lDemon (Translator)", 	@"Tested: iPhone 3GS, iPhone 4, iPod touch 4G, iPad 2G, iPad 3G.")
		addPerson(2,	@"@BassamKassem1", 	@"Tested: iPhone 4 GSM.")
		addPerson(3,	@"@H4lfSc0p3R",		@"Tested: iPhone 4 GSM, iPhone 4S, iPod touch 4G.")
		addPerson(4, 	@"@iPMisterX", 		@"Tested: iPhone 3GS.")
		addPerson(5,	@"@nenocrack", 		@"Tested: iPhone 4 GSM.")
		addPerson(6, 	@"@Raemon", 		@"Tested: iPhone 4 GSM, iPad mini 1G (Global).")
		addPerson(7, 	@"@Ntd123",		@"Tested: iPhone 4 GSM.")
		addPerson(8, 	@"Liewlom Bunnag",	@"Tested: iPad 2G (Wi-Fi).")
		addPerson(9, 	@"@Xtoyou",		@"Tested: iPad 3G (Global), iPad mini 2G.")
		addPerson(10, 	@"@n4te2iver",		@"Tested: iPad 4G (Wi-Fi).")
		addPerson(11, 	@"@NavehIDL",		@"Tested: iPad mini 1G (Wi-Fi).")
		addPerson(12, 	@"Srsw Omegax Akrw",	@"Tested: iPad mini 1G (GSM).")
		addPerson(13,	@"@iPFaHaD",		@"Tested: iPhone 4 GSM.")
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

@end

@interface PanoSlidersController : PSListController <UIActionSheetDelegate> {}
@property (nonatomic, retain) PSSpecifier *maxWidthSpec;
@property (nonatomic, retain) PSSpecifier *maxWidthSliderSpec;
@property (nonatomic, retain) PSSpecifier *maxWidthInputSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthSliderSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthInputSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightSliderSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightInputSpec;
@property (nonatomic, retain) PSSpecifier *minFPSSpec;
@property (nonatomic, retain) PSSpecifier *minFPSSliderSpec;
@property (nonatomic, retain) PSSpecifier *minFPSInputSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSSliderSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeInputSpec;
@end

@implementation PanoSlidersController

- (void)reset
{
	NSString *model = Model();
	resetValue(isNeedConfigDevice ? 4000 : 10800, maxWidthSliderSpec, maxWidthInputSpec)
	resetValue((isiPhone4S || isiPhone5Up || isiPad3or4 || isiPadAir || isiPadMini2G) ? 20 : 15, maxFPSSliderSpec, maxFPSInputSpec)
	resetValue(15, minFPSSliderSpec, minFPSInputSpec)
	resetValue((isiPhone5Up || isiPad3or4) ? 5 : 7, PanoramaBufferRingSizeSliderSpec, PanoramaBufferRingSizeInputSpec)

	if (isiPhone5Up || isiPad3or4 || isiPadMini2G || isiPadAir) {
		resetValue(15, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	} else if (isiPod5 || isiPadMini1G || isiPad2 || isiPod4) {
		resetValue(13, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	} else {
		resetValue(20, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}

	resetValue(306, previewWidthSliderSpec, previewWidthInputSpec)
	resetValue(86, previewHeightSliderSpec, previewHeightInputSpec)
	resetValue(30, PanoramaPowerBlurBiasSliderSpec, PanoramaPowerBlurBiasInputSpec)
	
	updateValue(maxWidthSpec, maxWidthSliderSpec, @"Current Width: %d pixels")
	updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"Current Width: %.2f pixels")
	updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"Current Height: %.2f pixels")
	updateValue(minFPSSpec, minFPSSliderSpec, @"Current Framerate: %d FPS")
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"Current Framerate: %d FPS")
	updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"Current Value: %d")
	updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"Current Value: %d")
	updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"Current Value: %d")
	[[NSUserDefaults standardUserDefaults] synchronize];
	update();
}

- (void)selectOption
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
		@"🔄 Reset",
		@"⬇ Hide KB",
		nil];
	sheet.tag = 95969597;
	[sheet showInView:self.view];
	[sheet release];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (popup.tag == 95969597) {
		switch (buttonIndex) {
			case 0:
				[self reset];
				break;
			case 1:
				[[super view] endEditing:YES];
				break;
		}
	}
}

- (void)addBtn
{
	UIBarButtonItem *btn = [[UIBarButtonItem alloc]
        initWithTitle:@"⭕" style:UIBarButtonItemStyleBordered
        target:self action:@selector(selectOption)];
	((UINavigationItem *)[super navigationItem]).rightBarButtonItem = btn;
	[btn release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self addBtn];
}

- (void)setWidth:(id)value specifier:(PSSpecifier *)spec
{
	NSString *model = Model();
	if (isSlow) {
		rangeFix(1000, 4096)
	}
	else {
		rangeFix(3000, 21600)
	}
	orig
	updateValue(maxWidthSpec, maxWidthSliderSpec, @"Current Width: %d pixels")
	update();
}

- (void)setPreviewWidth:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(100, 576)
	orig
	updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"Current Width: %.2f pixels")
	update();
}

- (void)setPreviewHeight:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(40, 576)
	orig
	updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"Current Height: %.2f pixels")
	update();
}


- (void)setMinFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.maxFPSSliderSpec] intValue] < [value intValue]) {
		resetValue([value intValue], maxFPSSliderSpec, maxFPSInputSpec)
	}

	rangeFix(1, 30)
	orig
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"Current Framerate: %d FPS")
	updateValue(minFPSSpec, minFPSSliderSpec, @"Current Framerate: %d FPS")
	update();
}

- (void)setMaxFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.minFPSSliderSpec] intValue] > [value intValue]) {
		resetValue([value intValue], minFPSSliderSpec, minFPSInputSpec)
	}
	
	rangeFix(15, 60)
	orig
	updateValue(minFPSSpec, minFPSSliderSpec, @"Current Framerate: %d FPS")
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"Current Framerate: %d FPS")
	update();
}

- (void)setPanoramaBufferRingSize:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 30)
	orig
	updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"Current Value: %d")
	update();
}

- (void)setPanoramaPowerBlurBias:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 60)
	orig
	updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"Current Value: %d")
	update();
}

- (void)setPanoramaPowerBlurSlope:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 60)
	orig
	updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"Current Value: %d")
	update();
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"Sliders" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(maxWidthSpec, @"MaxWidth")
			getSpec(maxWidthSliderSpec, @"MaxWidthSlider")
			getSpec(maxWidthInputSpec, @"MaxWidthInput")
			getSpec(previewWidthSpec, @"PreviewWidth")
			getSpec(previewWidthSliderSpec, @"PreviewWidthSlider")
			getSpec(previewWidthInputSpec, @"PreviewWidthInput")
			getSpec(previewHeightSpec, @"PreviewHeight")
			getSpec(previewHeightSliderSpec, @"PreviewHeightSlider")
			getSpec(previewHeightInputSpec, @"PreviewHeightInput")
			getSpec(minFPSSpec, @"MinFrameRate")
			getSpec(minFPSSliderSpec, @"MinFrameRateSlider")
			getSpec(minFPSInputSpec, @"MinFPSInput")
			getSpec(maxFPSSpec, @"MaxFrameRate")
			getSpec(maxFPSSliderSpec, @"MaxFrameRateSlider")
			getSpec(maxFPSInputSpec, @"MaxFPSInput")
			getSpec(minFPSInputSpec, @"MinFrameRateInput")
			getSpec(PanoramaBufferRingSizeSpec, @"PanoramaBufferRingSize")
			getSpec(PanoramaBufferRingSizeSliderSpec, @"PanoramaBufferRingSizeSlider")
			getSpec(PanoramaBufferRingSizeInputSpec, @"RingSizeInput")
			getSpec(PanoramaPowerBlurBiasSpec, @"PanoramaPowerBlurBias")
			getSpec(PanoramaPowerBlurBiasSliderSpec, @"PanoramaPowerBlurBiasSlider")
			getSpec(PanoramaPowerBlurBiasInputSpec, @"BlurBiasInput")
			getSpec(PanoramaPowerBlurSlopeSpec, @"PanoramaPowerBlurSlope")
			getSpec(PanoramaPowerBlurSlopeSliderSpec, @"PanoramaPowerBlurSlopeSlider")
			getSpec(PanoramaPowerBlurSlopeInputSpec, @"BlurSlopeInput")
		}
        
		NSString *model = Model();
		if (isSlow)
			[self.maxWidthSliderSpec setProperty:@4096 forKey:@"max"];
		else {
			[self.maxWidthSliderSpec setProperty:@21600 forKey:@"max"];
			[self.maxWidthSliderSpec setProperty:@3000 forKey:@"min"];
		}

		updateValue(maxWidthSpec, maxWidthSliderSpec, @"Current Width: %d pixels")
		updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"Current Width: %.2f pixels")
		updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"Current Height: %.2f pixels")
		updateValue(minFPSSpec, minFPSSliderSpec, @"Current Framerate: %d FPS")
		updateValue(maxFPSSpec, maxFPSSliderSpec, @"Current Framerate: %d FPS")
		updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"Current Value: %d")
		updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"Current Value: %d")
		updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"Current Value: %d")
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@interface PanoUIController : PSListController
@property (nonatomic, retain) PSSpecifier *hideTextSpec;
@property (nonatomic, retain) PSSpecifier *hideBGSpec;
@property (nonatomic, retain) PSSpecifier *customTextSpec;
@property (nonatomic, retain) PSSpecifier *inputTextSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonDescSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonSwitchSpec;
@property (nonatomic, retain) PSSpecifier *borderSpec;
@property (nonatomic, retain) PSSpecifier *borderDescSpec;
@end

@implementation PanoUIController

- (void)hideKeyboard
{
	[[super view] endEditing:YES];
}

- (void)addBtn
{
	UIBarButtonItem *hideKBBtn = [[UIBarButtonItem alloc] initWithTitle:@"⏬" style:UIBarButtonItemStyleBordered target:self action:@selector(hideKeyboard)];
	((UINavigationItem *)[super navigationItem]).rightBarButtonItem = hideKBBtn;
	[hideKBBtn release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self addBtn];
}

- (void)setTextHide:(id)value specifier:(PSSpecifier *)spec
{
	orig
	setAvailable(![value boolValue], self.customTextSpec);
	setAvailable(![value boolValue], self.inputTextSpec);
	[self reloadSpecifier:self.customTextSpec];
	[self reloadSpecifier:self.inputTextSpec];
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"UI" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(hideTextSpec, @"hideText")
			getSpec(hideBGSpec, @"hideBG")
			getSpec(customTextSpec, @"customText")
			getSpec(inputTextSpec, @"inputText")
			getSpec(blueButtonDescSpec, @"blueButtonDesc")
			getSpec(blueButtonSwitchSpec, @"blueButtonSwitch")
			getSpec(borderSpec, @"border")
			getSpec(borderDescSpec, @"borderDesc")
		}
        
		NSString *model = Model();
		if (isiOS7) {
			[specs removeObject:self.hideBGSpec];
			[specs removeObject:self.borderSpec];
			[specs removeObject:self.borderDescSpec];
		}
		if (!(isiPhone5Up || isiPod5) || isiOS7) {
			[specs removeObject:self.blueButtonDescSpec];
			[specs removeObject:self.blueButtonSwitchSpec];
		}
		
		setAvailable(![[self readPreferenceValue:self.hideTextSpec] boolValue], self.customTextSpec);
		setAvailable(![[self readPreferenceValue:self.hideTextSpec] boolValue], self.inputTextSpec);
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@interface PanoSysController : PSListController
@property (nonatomic, retain) PSSpecifier *LLBPanoDescSpec;
@property (nonatomic, retain) PSSpecifier *LLBPanoSwitchSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixDescSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixSwitchSpec;
@property (nonatomic, retain) PSSpecifier *FMDescSpec;
@property (nonatomic, retain) PSSpecifier *FMSwitchSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPDescSpec;
@property (nonatomic, retain) PSSpecifier *BPNRSpec;
@property (nonatomic, retain) PSSpecifier *BPNRDescSpec;
@end

@implementation PanoSysController

- (void)update:(id)value specifier:(PSSpecifier *)spec
{
	orig
	update();
}

- (void)fixCelestial:(id)param
{
	//CFPropertyListRef settings = CFPreferencesCopyValue(CFSTR("CameraStreamInfo"), CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
	notify_post("com.ps.panomod.flush");
	//system("killall mediaserverd");
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"Sys" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(LLBPanoDescSpec, @"LLBPanoDesc")
			getSpec(LLBPanoSwitchSpec, @"LLBPanoSwitch")
			getSpec(PanoDarkFixDescSpec, @"PanoDarkFixDesc")
			getSpec(PanoDarkFixSwitchSpec, @"PanoDarkFixSwitch")
			getSpec(FMDescSpec, @"FMDesc")
			getSpec(FMSwitchSpec, @"FMSwitch")
			getSpec(Pano8MPSpec, @"8MPs")
			getSpec(Pano8MPDescSpec, @"8MP")
			getSpec(BPNRSpec, @"BPNRs")
			getSpec(BPNRDescSpec, @"BPNR")
		}
        
		NSString *model = Model();
		if (!isiOS7 || isiPhone5s) {
			[specs removeObject:self.BPNRSpec];
			[specs removeObject:self.BPNRDescSpec];
		}
		if (!(isiPhone5 || isiPod5)) {
			[specs removeObject:self.LLBPanoDescSpec];
			[specs removeObject:self.LLBPanoSwitchSpec];
		}
		if (isiPad || isiPod4) {
			[specs removeObject:self.FMDescSpec];
			[specs removeObject:self.FMSwitchSpec];
		}
		if (!is8MPCamDevice) {
			[specs removeObject:self.Pano8MPSpec];
			[specs removeObject:self.Pano8MPDescSpec];
		}
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end
