#import "../definitions.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextViewTableCell.h>

#include <objc/runtime.h>
#include <sys/sysctl.h>

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

#define addPerson(numCase, lineCount, TextLabel, DetailTextLabel) 	case numCase: \
    									{ \
    										[cell.detailTextLabel setText:DetailTextLabel]; \
    										[cell.textLabel setText:TextLabel]; \
    										cell.detailTextLabel.numberOfLines = lineCount; \
    										break; \
    									}
#define getSpec(mySpec, string)	if ([Id isEqualToString:string]) \
                			self.mySpec = spec;


#define updateValue(targetSpec, sliderSpec, targetKey, string) 		[self.targetSpec setProperty:[NSString stringWithFormat:string, [[self readPreferenceValue:self.sliderSpec] intValue]] forKey:targetKey]; \
  																		[self reloadSpecifier:self.targetSpec]; \
  																		[self reloadSpecifier:self.sliderSpec];

#define updateFloatValue(targetSpec, sliderSpec, targetKey, string) 	[self.targetSpec setProperty:[NSString stringWithFormat:string, round([[self readPreferenceValue:self.sliderSpec] floatValue]*100.0)/100.0] forKey:targetKey]; \
  																		[self reloadSpecifier:self.targetSpec]; \
  																		[self reloadSpecifier:self.sliderSpec];

#define resetValue(intValue, spec, inputSpec) 	[self setPreferenceValue:[NSNumber numberWithInteger:intValue] specifier:self.spec]; \
						[self setPreferenceValue:[[NSNumber numberWithInteger:intValue] stringValue] specifier:self.inputSpec]; \
						[self reloadSpecifier:self.spec]; \
						[self reloadSpecifier:self.inputSpec]; \
						[[NSUserDefaults standardUserDefaults] synchronize];

#define orig	[self setPreferenceValue:value specifier:spec]; \
		[[NSUserDefaults standardUserDefaults] synchronize];
				
static void openLink(NSString *url)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
				
#define rangeFix(min, max) \
	int value2 = [NSNumber numberWithInteger:[value intValue]].intValue; \
	if (value2 > max) \
		value = [NSNumber numberWithInteger:max]; \
	else if (value2 < min) \
		value = [NSNumber numberWithInteger:min]; \
	else value = [NSNumber numberWithInteger:([value intValue])];

#define rangeFixFloat(min, max) \
	float value2 = [NSNumber numberWithFloat:[value floatValue]].floatValue; \
	if (value2 > max) \
		value = [NSNumber numberWithFloat:max]; \
	else if (value2 < min) \
		value = [NSNumber numberWithFloat:min]; \
	else value = [NSNumber numberWithFloat:(round([value floatValue]*100.0)/100.0)];
									
static void setAvailable(BOOL available, PSSpecifier *spec)
{
	[spec setProperty:[NSNumber numberWithBool:available] forKey:@"enabled"];
}


@interface actHackPreferenceController : PSListController {
	PSSpecifier *PanoEnabledSpec;
	PSSpecifier *maxWidthSpec;
	PSSpecifier *maxWidthSliderSpec;
	PSSpecifier *maxWidthInputSpec;
	PSSpecifier *previewWidthSpec;
	PSSpecifier *previewWidthSliderSpec;
	PSSpecifier *previewWidthInputSpec;
	PSSpecifier *previewHeightSpec;
	PSSpecifier *previewHeightSliderSpec;
	PSSpecifier *previewHeightInputSpec;
	PSSpecifier *minFPSSpec;
	PSSpecifier *minFPSSliderSpec;
	PSSpecifier *minFPSInputSpec;
	PSSpecifier *maxFPSSpec;
	PSSpecifier *maxFPSSliderSpec;
	PSSpecifier *maxFPSInputSpec;
	PSSpecifier *PanoramaBufferRingSizeSpec;
	PSSpecifier *PanoramaBufferRingSizeSliderSpec;
	PSSpecifier *PanoramaBufferRingSizeInputSpec;
	PSSpecifier *PanoramaPowerBlurBiasSpec;
	PSSpecifier *PanoramaPowerBlurBiasSliderSpec;
	PSSpecifier *PanoramaPowerBlurBiasInputSpec;
	PSSpecifier *PanoramaPowerBlurSlopeSpec;
	PSSpecifier *PanoramaPowerBlurSlopeSliderSpec;
	PSSpecifier *PanoramaPowerBlurSlopeInputSpec;
	PSSpecifier *hideTextSpec;
	PSSpecifier *hideBGSpec;
	PSSpecifier *customTextSpec;
	PSSpecifier *inputTextSpec;
	PSSpecifier *blueButtonDescSpec;
	PSSpecifier *blueButtonSwitchSpec;
	PSSpecifier *LLBPanoDescSpec;
	PSSpecifier *LLBPanoSwitchSpec;
	PSSpecifier *PanoDarkFixDescSpec;
	PSSpecifier *PanoDarkFixSwitchSpec;
	PSSpecifier *FMDescSpec;
	PSSpecifier *FMSwitchSpec;
	PSSpecifier *borderSpec;
	PSSpecifier *borderDescSpec;
	PSSpecifier *Pano8MPSpec;
	PSSpecifier *Pano8MPDescSpec;
	PSSpecifier *BPNRSpec;
	PSSpecifier *BPNRDescSpec;
}
@property (nonatomic, retain) PSSpecifier *PanoEnabledSpec;
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
@property (nonatomic, retain) PSSpecifier *hideTextSpec;
@property (nonatomic, retain) PSSpecifier *hideBGSpec;
@property (nonatomic, retain) PSSpecifier *customTextSpec;
@property (nonatomic, retain) PSSpecifier *inputTextSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonDescSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonSwitchSpec;
@property (nonatomic, retain) PSSpecifier *LLBPanoDescSpec;
@property (nonatomic, retain) PSSpecifier *LLBPanoSwitchSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixDescSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixSwitchSpec;
@property (nonatomic, retain) PSSpecifier *FMDescSpec;
@property (nonatomic, retain) PSSpecifier *FMSwitchSpec;
@property (nonatomic, retain) PSSpecifier *borderSpec;
@property (nonatomic, retain) PSSpecifier *borderDescSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPDescSpec;
@property (nonatomic, retain) PSSpecifier *BPNRSpec;
@property (nonatomic, retain) PSSpecifier *BPNRDescSpec;
@end

@implementation actHackPreferenceController

@synthesize PanoEnabledSpec;
@synthesize maxWidthSpec, maxWidthSliderSpec, maxWidthInputSpec;
@synthesize previewWidthSpec, previewWidthSliderSpec, previewWidthInputSpec;
@synthesize previewHeightSpec, previewHeightSliderSpec, previewHeightInputSpec;
@synthesize minFPSSpec, minFPSSliderSpec, minFPSInputSpec;
@synthesize maxFPSSpec, maxFPSSliderSpec, maxFPSInputSpec;
@synthesize PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, PanoramaBufferRingSizeInputSpec;
@synthesize PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, PanoramaPowerBlurBiasInputSpec;
@synthesize PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec;
@synthesize hideTextSpec, hideBGSpec, customTextSpec, inputTextSpec;
@synthesize blueButtonDescSpec, blueButtonSwitchSpec;
@synthesize LLBPanoDescSpec, LLBPanoSwitchSpec;
@synthesize PanoDarkFixDescSpec, PanoDarkFixSwitchSpec;
@synthesize FMDescSpec, FMSwitchSpec;
@synthesize borderSpec, borderDescSpec;
@synthesize Pano8MPSpec, Pano8MPDescSpec;
@synthesize BPNRSpec, BPNRDescSpec;

- (NSString *)model
{
	size_t size;
    	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    	char* answer = (char *)malloc(size);
    	sysctlbyname("hw.machine", answer, &size, NULL, 0);
    	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    	free(answer);
    	return results;
}

- (void)hideKeyboard
{
	[[super view] endEditing:YES];
}

- (void)addBtn
{
	UIBarButtonItem *hideKBBtn = [[UIBarButtonItem alloc]
        initWithTitle:@"Hide KB" style:UIBarButtonItemStyleBordered
        target:self action:@selector(hideKeyboard)];
	((UINavigationItem *)[super navigationItem]).rightBarButtonItem = hideKBBtn;
	[hideKBBtn release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self addBtn];
}

- (void)viewDidUnload
{
	NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"PanoPreferences" target:self]];
	for (PSSpecifier *spec in specs) {
		if ([Id length] > 0)
		spec = nil;
	}
    	[super viewDidUnload];
}

- (void)setWidth:(id)value specifier:(PSSpecifier *)spec
{
	NSString *model = [self model];
	if (isSlow) {
		rangeFix(1000, 4096)
	}
	else {
		rangeFix(3000, 21600)
	}
	orig
	updateValue(maxWidthSpec, maxWidthSliderSpec, @"footerText", @"Current Width: %i pixels")
}

- (void)setPreviewWidth:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(100, 576)
	orig
	updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"footerText", @"Current Width: %.2f pixels")
}

- (void)setPreviewHeight:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(40, 576)
	orig
	updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"footerText", @"Current Height: %.2f pixels")
}


- (void)setMinFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.maxFPSSliderSpec] intValue] < [NSNumber numberWithInt:[value intValue]].intValue) {
		resetValue([value intValue], maxFPSSliderSpec, maxFPSInputSpec)
	}

	rangeFix(1, 30)
	orig
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
	updateValue(minFPSSpec, minFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
}

- (void)setMaxFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.minFPSSliderSpec] intValue] > [NSNumber numberWithInt:[value intValue]].intValue) {
		resetValue([value intValue], minFPSSliderSpec, minFPSInputSpec)
	}
	
	rangeFix(15, 60)
	orig
	updateValue(minFPSSpec, minFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
}

- (void)setPanoramaBufferRingSize:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 30)
	orig
	updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"footerText", @"Current Value: %i")
}

- (void)setPanoramaPowerBlurBias:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 60)
	orig
	updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"footerText", @"Current Value: %i")
}

- (void)setPanoramaPowerBlurSlope:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(1, 60)
	orig
	updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"footerText", @"Current Value: %i")
}

- (void)setTextHide:(id)value specifier:(PSSpecifier *)spec
{
	orig
	setAvailable(![value boolValue], self.customTextSpec);
	setAvailable(![value boolValue], self.inputTextSpec);
	[self reloadSpecifier:self.customTextSpec];
	[self reloadSpecifier:self.inputTextSpec];
}

- (void)resetValues:(id)param
{
	NSString *model = [self model];
	resetValue(isNeedConfigDevice ? 4000 : 10800, maxWidthSliderSpec, maxWidthInputSpec)

	resetValue((isiPhone5Up || isiPad3or4 || isiPadAir || isiPadMini2G) ? 20 : 15, maxFPSSliderSpec, maxFPSInputSpec)

	resetValue(15, minFPSSliderSpec, minFPSInputSpec)

	resetValue((isiPhone5Up || isiPad3or4) ? 5 : 7, PanoramaBufferRingSizeSliderSpec, PanoramaBufferRingSizeInputSpec)

	if (isiPhone5Up || isiPad3or4 || isiPadMini2G || isiPadAir) {
		resetValue(15, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	else if (isiPod5 || isiPadMini1G || isiPad2 || isiPod4) {
		resetValue(13, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	else if (isiPhone4S || isiPhone4) {
		resetValue(20, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	
	resetValue(306, previewWidthSliderSpec, previewWidthInputSpec)
	resetValue(86, previewHeightSliderSpec, previewHeightInputSpec)
	resetValue(30, PanoramaPowerBlurBiasSliderSpec, PanoramaPowerBlurBiasInputSpec)
	
	updateValue(maxWidthSpec, maxWidthSliderSpec, @"footerText", @"Current Width: %i pixels")
	updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"footerText", @"Current Width: %.2f pixels")
	updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"footerText", @"Current Height: %.2f pixels")
	updateValue(minFPSSpec, minFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
	updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"footerText", @"Current Value: %i")
	updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"footerText", @"Current Value: %i")
	updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"footerText", @"Current Value: %i")
}

- (void)setBoolAndKillCam:(id)value specifier:(PSSpecifier *)spec
{
	orig
	system("killall Camera");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"PanoPreferences" target:self]];
		
		for (PSSpecifier *spec in specs) {
			getSpec(PanoEnabledSpec, @"PanoEnabled")
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
			getSpec(hideTextSpec, @"hideText")
			getSpec(hideBGSpec, @"hideBG")
			getSpec(customTextSpec, @"customText")
			getSpec(inputTextSpec, @"inputText")
			getSpec(blueButtonDescSpec, @"blueButtonDesc")
			getSpec(blueButtonSwitchSpec, @"blueButtonSwitch")
			getSpec(LLBPanoDescSpec, @"LLBPanoDesc")
			getSpec(LLBPanoSwitchSpec, @"LLBPanoSwitch")
			getSpec(PanoDarkFixDescSpec, @"PanoDarkFixDesc")
			getSpec(PanoDarkFixSwitchSpec, @"PanoDarkFixSwitch")
			getSpec(FMDescSpec, @"FMDesc")
			getSpec(FMSwitchSpec, @"FMSwitch")
			getSpec(borderSpec, @"border")
			getSpec(borderDescSpec, @"borderDesc")
			getSpec(Pano8MPSpec, @"Pano8MPs")
			getSpec(Pano8MPDescSpec, @"Pano8MP")
			getSpec(BPNRSpec, @"BPNRs")
			getSpec(BPNRDescSpec, @"BPNR")
		}
        
		NSString *model = [self model];
		if (!(isiPhone5Up || isiPod5)) {
			[specs removeObject:self.blueButtonDescSpec];
			[specs removeObject:self.blueButtonSwitchSpec];
			[specs removeObject:self.LLBPanoDescSpec];
			[specs removeObject:self.LLBPanoSwitchSpec];
		} else {
			if (isiOS7) {
				[specs removeObject:self.blueButtonDescSpec];
				[specs removeObject:self.blueButtonSwitchSpec];
			}
		}
		if (!(isiPhone4 || isiPhone4S || isiPhone5Up || isiPod5)) {
			[specs removeObject:self.FMDescSpec];
			[specs removeObject:self.FMSwitchSpec];
		}
		if (isiPhone4S || isiPhone5Up || isiPod5) {
			[specs removeObject:self.PanoEnabledSpec];
		}
		if (isiOS7) {
			[specs removeObject:self.hideBGSpec];
			[specs removeObject:self.borderSpec];
			[specs removeObject:self.borderDescSpec];
		}
		if (!is8MPCamDevice) {
			[specs removeObject:self.BPNRSpec];
			[specs removeObject:self.BPNRDescSpec];
		}
		
		setAvailable(![[self readPreferenceValue:self.hideTextSpec] boolValue], self.customTextSpec);
		setAvailable(![[self readPreferenceValue:self.hideTextSpec] boolValue], self.inputTextSpec);
		
		if (isSlow)
			[self.maxWidthSliderSpec setProperty:[NSNumber numberWithFloat:4096] forKey:@"max"];
		else {
			[self.maxWidthSliderSpec setProperty:[NSNumber numberWithFloat:21600] forKey:@"max"];
			[self.maxWidthSliderSpec setProperty:[NSNumber numberWithFloat:3000] forKey:@"min"];
		}

		updateValue(maxWidthSpec, maxWidthSliderSpec, @"footerText", @"Current Width: %i pixels")
		updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"footerText", @"Current Width: %.2f pixels")
		updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"footerText", @"Current Height: %.2f pixels")
		updateValue(minFPSSpec, minFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
		updateValue(maxFPSSpec, maxFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
		updateValue(PanoramaBufferRingSizeSpec, PanoramaBufferRingSizeSliderSpec, @"footerText", @"Current Value: %i")
		updateValue(PanoramaPowerBlurBiasSpec, PanoramaPowerBlurBiasSliderSpec, @"footerText", @"Current Value: %i")
		updateValue(PanoramaPowerBlurSlopeSpec, PanoramaPowerBlurSlopeSliderSpec, @"footerText", @"Current Value: %i")
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@interface BannerCell : PSTextViewTableCell {
	UILabel *label;
}
@end
 
@implementation BannerCell

- (id)initWithSpecifier:(PSSpecifier*)specifier
{	
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Banner" specifier:specifier];
	if (self) {
		CGRect frame = [self frame];
		label = [[UILabel alloc] initWithFrame:frame];
		[label setText:@"PanoMod"];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setFont:[UIFont fontWithName:@"HelveticaNeue" size:60]];
		[label setTextAlignment:NSTextAlignmentCenter];
		[label setAutoresizingMask:2];
		[label setTextColor:[UIColor colorWithRed:.4 green:.4 blue:.49 alpha:1]];
		[label setShadowColor:[UIColor whiteColor]];
		[label setShadowOffset:CGSizeMake(0, 1)];
		[self addSubview:label];
		[label release];
	}
	return self;
}

- (void)layoutSubviews
{
}

- (float)preferredHeightForWidth:(float)width
{
    return 50.0f;
}

@end

@interface PanoFAQViewController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *_tableView;
}
@end

@implementation PanoFAQViewController

- (NSString *)title
{
	return @"FAQ";
}

- (id)view
{
   	return _tableView;
}

- (id)initForContentSize:(CGSize)size
{
	if ((self = [super initForContentSize:size]) != nil) {		
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416) style:UITableViewStyleGrouped];
		[_tableView setDataSource:self];
		[_tableView setDelegate:self];
		[_tableView setAutoresizingMask:1];
		[_tableView setEditing:NO];
		[_tableView setAllowsSelectionDuringEditing:NO];
		if ([self respondsToSelector:@selector(setView:)])
			[self setView:_tableView];
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   	return 6;
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
		case 1: return @"Will this fully working on A4 iDevices ?";
		case 2: return @"(iPad) Sometimes camera view flashes frequently when taking Panorama";
		case 3: return @"Panorama sometimes still dark even with \"Pano Dark Fix\" enabled";
		case 4: return @"(iOS 7, unsupported devices) Panorama doesn't work in Lockscreen Camera";
		case 5: return @"Supported iOS Versions";
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
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 460) reuseIdentifier:@"PanoFAQCell"] autorelease];
		[cell.textLabel setNumberOfLines:0];
		[cell.textLabel setBackgroundColor:[UIColor clearColor]];
		[cell.textLabel setFont:[UIFont systemFontOfSize:kFontSize]];
		[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
	}
    
	switch (indexPath.section)
	{
		case 0:	[cell.textLabel setText:PanoModBrief]; break;
		case 1: [cell.textLabel setText:@"The resolution of panoramic images in A4 iDevices are much lower than expect, due to some iOS compatibility reasons, I must use the thumbnail of panoramic image for saving in camera roll instead of using the actual but camera doesn't provide it.\nIt's not possible to make the full resolution because A4 iDevices use AppleH3CamIn driver, which doesn't provide Panorama processor."]; break;
		case 2: [cell.textLabel setText:@"This issue related with AE or Auto Exposure of Panorama, if you lock AE (Long tap the camera preview) will temporary fix the issue."]; break;
		case 3: [cell.textLabel setText:@"This issue related with memory and performance."]; break;
		case 4: [cell.textLabel setText:@"The limitation of hooking methods in iOS 7 causes this."]; break;
		case 5: [cell.textLabel setText:@"iOS 6.0 - 7.1"]; break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), 20000.0f);
  	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] textLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
  	return size.height + CELL_CONTENT_MARGIN;
}

- (void)dealloc
{
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	[_tableView release];
	[super dealloc];
}

@end

@interface PanoGuideViewController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *_tableView;
}
@end

@implementation PanoGuideViewController

- (NSString *)title
{
	return @"Guide";
}

- (id)view
{
   	return _tableView;
}

- (id)initForContentSize:(CGSize)size
{
	if ((self = [super initForContentSize:size]) != nil) {		
		 _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416) style:UITableViewStyleGrouped];
		[_tableView setDataSource:self];
		[_tableView setDelegate:self];
		[_tableView setAutoresizingMask:1];
		[_tableView setEditing:NO];
		[_tableView setAllowsSelectionDuringEditing:NO];
		if ([self respondsToSelector:@selector(setView:)])
			[self setView:_tableView];
	}
	return self;
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
		case 19: return @"Reset Sliders Values";
		case 20: return @"About Sliders and Inputs";
		case 21: return @"About \"Hide KB\" button at Top-right";
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   	return 22;
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
    	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PanoGuideCell"];
    
 	if (cell == nil) {
    		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 460) reuseIdentifier:@"PanoGuideCell"] autorelease];
    		[cell.textLabel setNumberOfLines:0];
    		[cell.textLabel setBackgroundColor:[UIColor clearColor]];
    		[cell.textLabel setFont:[UIFont systemFontOfSize:kFontSize]];
        	[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    	}
 	switch (indexPath.section) {
        	case 0:
  			[cell.textLabel setText:@"We will explain each function how they work."]; break;
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
  			[cell.textLabel setText:@"This is what Panorama talk to you, when you capture Panorama, this function provided some customization including Hide Text, Hide BG (Hide Black translucent background, iOS 6 only) and Custom Text. (Set it to whatever you want)"]; break;
  		case 8:
  			[cell.textLabel setText:@"Enabling ability to zoom in Panorama mode.\nNOTE: This affects on panoramic image in iOS 7"]; break;
  		case 9:
  			[cell.textLabel setText:@"Showing grid in Panorama mode."]; break;
  		case 10:
  			[cell.textLabel setText:@"Like \"Better Pano Button\" that changes your Panorama button color for 4-inches Tall-iDevices to blue."]; break;
  		case 11:
  			[cell.textLabel setText:@"Like \"LLBPano\", works only in Low Light Boost-capable iDevices or only iPhone 5 and iPod touch 5G, fix dark issue using Low Light Boost method.\nFor iPod touch 5G users, you must have tweak \"LLBiPT5\" version 1.0-4 or above installed first."]; break;
  		case 12:
  			[cell.textLabel setText:@"For those iDevices without support Low Light Boost feature, this function will fix the dark issue in the another way and it works for all iDevices (iPod touch 5G users, if you don’t want to install LLBiPT5, you can just enable this function) and you will see the big different in camera brightness/lighting performance.\nBut reason why Apple limits the brightness is simple, to fix Panorama overbright issue that you can face it in daytime."]; break;
  		case 13:
  			[cell.textLabel setText:@"Like \"Flashorama\" that allows you to toggle torch using Flash button in Panorama mode.\nSupported for iPhone or iPod with LED-Flash capable."]; break;
  		case 14:
  			[cell.textLabel setText:@"Hiding the white arrow that follows you when you move around to capture Panorama."]; break;
  		case 15:
  			[cell.textLabel setText:@"Hiding the blue (iOS 6) or yellow (iOS 7) horizontal line at the middle of screen, if you don't want it."]; break;
  		case 16:
  			[cell.textLabel setText:@"iOS 6 only, Hiding the border crops the small Panorama preview, sometimes this function is recommended to enable when you set Panoramic images maximum width into different values."]; break;
  		case 17:
  			[cell.textLabel setText:@"By default, the Panorama sensor resolution is 5 MP, this option can changes the sensor resolution to 8 MP if your device is capable. (iPhone 4S or newer) This makes the panoramic images more clear."]; break;
  		case 18:
  			[cell.textLabel setText:@"iOS 7 only, \"BPNR\" or Auto exposure adjustments during the pan of Panorama capture, was introduced in iPhone 5s, to even out exposure in scenes where brightness varies across the frame."]; break;
  		case 19:
  			[cell.textLabel setText:@"Reset all sliders values to their default."]; break;
  		case 20:
  			[cell.textLabel setText:@"Just adjust them, easy ?"]; break;
  		case 21:
  			[cell.textLabel setText:@"Simple button for hiding keyboard, useful in iPhone/iPod when you want to set many properties using input box."]; break;
  	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), MAXFLOAT);
  	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] textLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
  	return size.height + CELL_CONTENT_MARGIN;
}

- (void)dealloc
{
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	[_tableView release];
	[super dealloc];
}

@end

@interface PanoCreditsViewController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *_tableView;
}
@end

@implementation PanoCreditsViewController

- (NSString *)title
{
	return @"Credits";
}

- (id)view
{
   	return _tableView;
}

- (id)initForContentSize:(CGSize)size
{
	if ((self = [super initForContentSize:size]) != nil) {		
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416) style:UITableViewStyleGrouped];
		[_tableView setDataSource:self];
		[_tableView setDelegate:self];
		[_tableView setAutoresizingMask:1];
		[_tableView setEditing:NO];
		[_tableView setAllowsSelectionDuringEditing:NO];
		if ([self respondsToSelector:@selector(setView:)])
			[self setView:_tableView];
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 15;
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
		case 1:
			openLink(@"https://twitter.com/PoomSmart"); break;
		case 2:
			openLink(@"https://twitter.com/Pix3lDemon"); break; // Main dev but help exactly 5% :(
		case 3:
			openLink(@"https://twitter.com/BassamKassem1"); break;
		case 4:
			openLink(@"https://twitter.com/H4lfSc0p3R"); break;
		case 5:
			openLink(@"https://twitter.com/iPMisterX"); break;
		case 6:
			openLink(@"https://twitter.com/nenocrack"); break;
		case 7:
			openLink(@"https://twitter.com/Raem0n"); break;
		case 8:
			openLink(@"https://twitter.com/NTD123"); break;
		case 9:
			openLink(@"https://www.facebook.com/itenb?fref=ts"); break;
		case 10:
			openLink(@"https://twitter.com/xtoyou"); break;
		case 11:
			openLink(@"https://twitter.com/n4te2iver"); break;
		case 12:
			openLink(@"https://twitter.com/NavehIDL"); break;
		case 13:
			openLink(@"https://www.facebook.com/omkung?fref=ts"); break;
		case 14:
			openLink(@"https://twitter.com/iPFaHaD"); break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    	NSString *ident = [NSString stringWithFormat:@"u%li", (long)indexPath.row];
    
    	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    
    	if (cell == nil) {
    		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
    		[cell.textLabel setNumberOfLines:0];
    		[cell.textLabel setBackgroundColor:[UIColor clearColor]];
    		[cell.textLabel setFont:[UIFont boldSystemFontOfSize:(kFontSize + 2)]];
        	[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    	}
    
    	if (indexPath.row != 0) {
    		switch (indexPath.row)
    		{
    			addPerson(1, 3, 	@"@PoomSmart (Main Dev)", 	@"Tested tweak on iPod touch 4G, iPod touch 5G, iPhone 4S and iPad 2G (GSM).")
    			addPerson(2, 3, 	@"@Pix3lDemon (Translator)", 	@"Tested tweak on iPhone 3GS, iPhone 4, iPod touch 4G, iPad 2G and iPad 3G.")
    			addPerson(3, 1, 	@"@BassamKassem1", 	@"Tested tweak on iPhone 4 GSM.")
    			addPerson(4, 2,		@"@H4lfSc0p3R",		@"Tested tweak on iPhone 4 GSM, iPhone 4S and iPod touch 4G.")
    			addPerson(5, 1, 	@"@iPMisterX", 		@"Tested tweak on iPhone 3GS.")
				addPerson(6, 1, 	@"@nenocrack", 		@"Tested tweak on iPhone 4 GSM.")
    			addPerson(7, 2, 	@"@Raemon", 		@"Tested tweak on iPhone 4 GSM and iPad mini 1G (Global).")
    			addPerson(8, 1, 	@"@Ntd123",		@"Tested tweak on iPhone 4 GSM.")
    			addPerson(9, 2, 	@"Liewlom Bunnag",	@"Tested tweak on iPad 2G (Wi-Fi).")
    			addPerson(10, 2, 	@"@Xtoyou",		@"Tested tweak on iPad 3G (Global) and iPad mini 2G.")
    			addPerson(11, 2, 	@"@n4te2iver",		@"Tested tweak on iPad 4G (Wi-Fi).")
    			addPerson(12, 1, 	@"@NavehIDL",		@"Tested tweak on iPad mini 1G (Wi-Fi).")
    			addPerson(13, 1, 	@"Srsw Omegax Akrw",	@"Tested tweak on iPad mini 1G (GSM).")
    			addPerson(14, 1,	@"@iPFaHaD",		@"Tested tweak on iPhone 4 GSM.")
    		}
    	} else {
    		cell.detailTextLabel.text = @"The list of People help creating PanoMod, Thanks for your support :)";
    		cell.detailTextLabel.textColor = [UIColor blackColor];
    		cell.detailTextLabel.numberOfLines = 2;
    		[cell.detailTextLabel setFont:[UIFont systemFontOfSize:(kFontSize + 1)]];
   	}			
    	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), MAXFLOAT);
  	return 30.0f + [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] detailTextLabel] text] sizeWithFont:[UIFont systemFontOfSize:(kFontSize + 0.5)] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping].height;
}

- (void)dealloc
{
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	[_tableView release];
	[super dealloc];
}

@end


#define PanoModAddMethod(_class, _sel, _imp, _type) \
    if (![[_class class] instancesRespondToSelector:@selector(_sel)]) \
        class_addMethod([_class class], @selector(_sel), (IMP)_imp, _type)
        
id $PSViewController$initForContentSize$(PSRootController *self, SEL _cmd, CGRect contentSize) {
	return [self init];
}
        
static __attribute__((constructor)) void __PanoModInit() {
	PanoModAddMethod(PSViewController, initForContentSize:, $PSViewController$initForContentSize$, "@@:{ff}");
}
