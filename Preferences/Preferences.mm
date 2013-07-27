#import "../definitions.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#include <objc/runtime.h>
#include <sys/sysctl.h>

@interface PSViewController (PanoMod)
- (void)setView:(id)view;
@end

@interface PSListController (PanoMod)
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidUnload;
@end

#define kFontSize 14.0f
#define CELL_CONTENT_MARGIN 20.0f
#define PanoModBrief \
@"Enable Panorama on every unsupported iOS 6 device.\n\
Then Customize the interface and properties of Panorama with PanoMod."

#define Id [[spec properties] objectForKey:@"id"]

#define addPerson(numCase, lineCount, TextLabel, DetailTextLabel) 	case numCase: \
    																{ \
    																	[cell.detailTextLabel setText:DetailTextLabel]; \
    																	[cell.textLabel setText:TextLabel]; \
    																	cell.detailTextLabel.numberOfLines = lineCount; \
    																	break; \
    																}

#define openLink(url) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];

#define getSpec(mySpec, string)	if ([Id isEqualToString:string]) \
                				self.mySpec = spec;

#define rangeFix(min, max) 	int value2 = [NSNumber numberWithInteger:([value intValue])].intValue; \
							if (value2 > max) { value = [NSNumber numberWithInteger:max]; } \
							else if (value2 < min) { value = [NSNumber numberWithInteger:min]; } \
							else value = [NSNumber numberWithInteger:([value intValue])];

#define rangeFixFloat(min, max) 	float value2 = [NSNumber numberWithFloat:([value floatValue])].floatValue; \
									if (value2 > max) { value = [NSNumber numberWithFloat:max]; } \
									else if (value2 < min) { value = [NSNumber numberWithFloat:min]; } \
									else value = [NSNumber numberWithFloat:([value floatValue])];

#define updateValue(targetSpec, sliderSpec, targetKey, string) 	[self.targetSpec setProperty:[NSString stringWithFormat:string, [[self readPreferenceValue:self.sliderSpec] intValue]] forKey:targetKey]; \
  																		[self reloadSpecifier:self.targetSpec animated:NO];

#define updateFloatValue(targetSpec, sliderSpec, targetKey, string) 	[self.targetSpec setProperty:[NSString stringWithFormat:string, [[self readPreferenceValue:self.sliderSpec] floatValue]] forKey:targetKey]; \
  																		[self reloadSpecifier:self.targetSpec animated:NO];

#define resetValue(intValue, spec, inputSpec) 	[self setPreferenceValue:[NSNumber numberWithInteger:intValue] specifier:self.spec]; \
												[self setPreferenceValue:[[NSNumber numberWithInteger:intValue] stringValue] specifier:self.inputSpec]; \
												[self reloadSpecifier:self.spec]; \
												[self reloadSpecifier:self.inputSpec]; \
												[[NSUserDefaults standardUserDefaults] synchronize];

#define orig	[self setPreferenceValue:value specifier:spec]; \
				[[NSUserDefaults standardUserDefaults] synchronize];


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
		 _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelectionDuringEditing:NO];
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:_tableView];
	}
	return self;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
	return 1;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section
{
	switch (section) {
		case 0: return @"PanoMod";
		case 1: return @"Will this fully working in A4 iDevices ?";
		case 2: return @"(A4 iDevices) Panorama doesn't work in Lockscreen Camera";
		case 3: return @"(iPad) Sometimes camera view flashes frequently when taking Panorama";
		case 4: return @"(iPad) Landscape Panorama UI is bad";
		case 5: return @"Panorama sometimes still dark even with \"Pano Dark Fix\" enabled";
		case 6: return @"Supported iOS Versions";
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
        [cell.textLabel setLineBreakMode:UILineBreakModeWordWrap];
    }
    
	switch (indexPath.section)
	{
		case 0:	[cell.textLabel setText:PanoModBrief]; break;
    	case 1: [cell.textLabel setText:@"Here are the issues that still can’t be fixed.\n\
1. The resolution of panoramic image in A4 iDevices is much lower than expect, due to some iOS compatibility reasons, I must use the thumbnail of panoramic image for saving in camera roll instead of using the actual but camera doesn't provide it.\n\
2. iPhone 3GS, the slowest iOS 6 device, may not able to handle Panorama capture so it causes green images as usual."]; break;
		case 2: [cell.textLabel setText:@"Method we use to enable Panorama is about code injection that only work when launching (Camera) app. So it doesn't work with Lockscreen Camera."]; break;
		case 3: [cell.textLabel setText:@"This issue related with AE or Auto Exposure of Panorama, if you lock AE (Long tap the camera preview) will temporary fix the issue."]; break;
		case 4: [cell.textLabel setText:@"Apple didn’t make Panorama as a stock feature on any iPads so there will be bugs like this that are simply unfixable."]; break;
		case 5: [cell.textLabel setText:@"This issue related with memory and performance."]; break;
		case 6: [cell.textLabel setText:@"iOS 6.0.0 - 6.1.3"]; break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), 20000.0f);
  	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] textLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
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
		 _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelectionDuringEditing:NO];
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:_tableView];
	}
	return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section
{
	switch (section) {
		case 1: return @"Enable Panorama";
		case 2: return @"Panoramic Images Maximum Width";
		case 3: return @"Preview Width & Preview Height";
		case 4: return @"Min & Max Framerate";
		case 5: return @"ACTPanorama(BufferRingSize, PowerBlurBias, PowerBlurSlope)";
		case 6: return @"Instructional Text";
		case 7: return @"Enable Zoom";
		case 8: return @"Enable Grid";
		case 9: return @"Blue Button";
		case 10: return @"Panorama Low Light Boost";
		case 11: return @"Fix Dark issue";
		case 12: return @"Ability to Toggle Torch";
		case 13: return @"White Arrow";
		case 14: return @"Blue line in the middle";
		case 15: return @"White Border";
		case 16: return @"Reset Sliders Values";
		case 17: return @"About Sliders and Inputs";
		case 18: return @"About \"Hide KB\" button at Top-right";
	}
	return nil;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 19;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
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
        [cell.textLabel setLineBreakMode:UILineBreakModeWordWrap];
    }
    switch (indexPath.section) {
        	case 0:
  				[cell.textLabel setText:@"We will explain each function how they work."]; break;
  			case 1:
  				[cell.textLabel setText:@"Only available if iDevice doesn't support Panorama by default, by injecting some code that tell Camera this device supported Panorama.\nBut it slows down time for opening Camera app, much in A4 iDevices."]; break;
  			case 2:
  				[cell.textLabel setText:@"For example, the default maximum panoramic image width of iPhone 4S, iPhone 5 and iPod touch 5G (5MP Camera) is 10800 pixel, you can adjust it, lowest is 3000 pixel, highest is 21600 pixel.\nNOTE: You cannot set the maximum width LOWER than the Camera sensor width."]; break;
  			case 3:
  				[cell.textLabel setText:@"Adjust the little Panorama Preview sizes in the middle, default value, 306 pixel Width and 86 pixel Height.\nKeep in mind that this function doesn’t work well with iPads when Preview Width is more than the original value."]; break;
  			case 4:
  				[cell.textLabel setText:@"Adjust the FPS of Panorama, but keep in mind in that don’t set it too high or too low or you may face the pink preview issue."]; break;
  			case 5:
  				[cell.textLabel setText:@"Some Panorama properties, just included them if you want to play around."]; break;
  			case 6:
  				[cell.textLabel setText:@"This is what Panorama talk to you, when you capture Panorama, this function provided some customization including Hide Text, Hide BG (Hide Black translucent background) and Custom Text. (Set it to whatever you want)"]; break;
  			case 7:
  				[cell.textLabel setText:@"This might be useless function, all it does is enabling ability to zoom in Panorama mode but doesn't affect in resulted image."]; break;
  			case 8:
  				[cell.textLabel setText:@"If you want grid to show in Panorama mode."]; break;
  			case 9:
  				[cell.textLabel setText:@"Like \"Better Pano Button\" that changes your Panorama button for 4-inches Tall-iDevices to blue."]; break;
  			case 10:
  				[cell.textLabel setText:@"Like \"LLBPano\", works only in Low Light Boost-capable iDevices or only iPhone 5 and iPod touch 5G, fix dark issue using Low Light Boost method.\nFor iPod touch 5G users, you must have tweak \"LLBiPT5\" version 1.0-4 or above installed first."]; break;
  			case 11:
  				[cell.textLabel setText:@"For those iDevices without support Low Light Boost feature, this function will fix the dark issue in the another way and it works for all iDevices (iPod touch 5G users, if you don’t want to install LLBiPT5, you can just enable this function) and you will see the big different in camera brightness/lighting performance.\nBut reason why Apple limits the brightness is simple, to fix Panorama overbright issue that you can face it in daytime."]; break;
  			case 12:
  				[cell.textLabel setText:@"Like \"Flashorama\" that allows you to toggle torch using Flash button in Panorama mode.\nSupported for iPhone 4, iPhone 4S, iPhone 5 and iPod touch 5G."]; break;
  			case 13:
  				[cell.textLabel setText:@"The white arrow follows you when you move around to capture Panorama, hide if you annoy it."]; break;
  			case 14:
  				[cell.textLabel setText:@"Hiding the blue horizontal line at the middle of screen, if you don't want it."]; break;
  			case 15:
  				[cell.textLabel setText:@"Hiding the border crops the small Panorama preview, sometimes this function is recommended to enable when you set Panoramic images maximum width into different values."]; break;
  			case 16:
  				[cell.textLabel setText:@"Reset all sliders values to their default."]; break;
  			case 17:
  				[cell.textLabel setText:@"Just adjust them, easy ?"]; break;
  			case 18:
  				[cell.textLabel setText:@"Simple button for hiding keyboard, useful in iPhone/iPod when you want to set many properties using input box."]; break;
  		}    

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   	CGSize constraint = CGSizeMake([tableView frame].size.width - (CELL_CONTENT_MARGIN * 2), MAXFLOAT);
  	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] textLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
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
		 _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480 - 64) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelectionDuringEditing:NO];
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:_tableView];
	}
	return self;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
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
			openLink(@"https://twitter.com/PoomSmart")
		case 2:
			openLink(@"https://twitter.com/Pix3lDemon")
		case 3:
			openLink(@"https://twitter.com/BassamKassem1")
		case 4:
			openLink(@"https://twitter.com/iPMisterX")
		case 5:
			openLink(@"https://twitter.com/nenocrack")
		case 6:
			openLink(@"https://twitter.com/Raem0n")
		case 7:
			openLink(@"https://twitter.com/NTD123")
		case 8:
			openLink(@"https://www.facebook.com/itenb?fref=ts")
		case 9:
			openLink(@"https://twitter.com/xtoyou")
		case 10:
			openLink(@"https://twitter.com/n4te2iver")
		case 11:
			openLink(@"https://twitter.com/NavehIDL")
		case 12:
			openLink(@"https://www.facebook.com/omkung?fref=ts")
		case 13:
			openLink(@"https://twitter.com/iPFaHaD")
		case 14:
			openLink(@"https://twitter.com/H4lfSc0p3R")
		
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSString *ident = nil;
	switch (indexPath.row)
	{
		case 1:	ident = @"u1"; break;
    	case 2: ident = @"u2"; break;
    	case 3: ident = @"u3"; break;
    	case 4: ident = @"u4"; break;
    	case 5: ident = @"u5"; break;
    	case 6: ident = @"u6"; break;
    	case 7: ident = @"u7"; break;
    	case 8: ident = @"u8"; break;
    	case 9: ident = @"u9"; break;
    	case 10: ident = @"u10"; break;
    	case 11: ident = @"u11"; break;
    	case 12: ident = @"u12"; break;
    	case 13: ident = @"u13"; break;
    	case 14: ident = @"u14"; break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    
    if (cell == nil) {
    	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
    	[cell.textLabel setNumberOfLines:0];
    	[cell.textLabel setBackgroundColor:[UIColor clearColor]];
    	[cell.textLabel setFont:[UIFont boldSystemFontOfSize:(kFontSize + 2)]];
        [cell.textLabel setLineBreakMode:UILineBreakModeWordWrap];
    }
    
    if (indexPath.row != 0) {
    	switch (indexPath.row)
    	{
    		addPerson(1, 3, 	@"@PoomSmart (Dev)", 	@"Tested tweak on iPod touch 4th generation, iPod touch 5G, iPhone 4S and iPad 2nd Generation (GSM).")
    		addPerson(2, 3, 	@"@Pix3lDemon (Dev)", 	@"Tested tweak on iPhone 3GS, iPhone 4, iPod touch 4th generation, iPad 2nd Generation and iPad 3rd generation.")
    		addPerson(3, 1, 	@"@BassamKassem1", 		@"Tested tweak on iPhone 4 GSM.")
    		addPerson(4, 1, 	@"@iPMisterX", 			@"Tested tweak on iPhone 3GS.")
			addPerson(5, 1, 	@"@nenocrack", 			@"Tested tweak on iPhone 4 GSM.")
    		addPerson(6, 2, 	@"@Raemon", 			@"Tested tweak on iPhone 4 GSM and iPad mini 1G (Global).")
    		addPerson(7, 1, 	@"@Ntd123",				@"Tested tweak on iPhone 4 GSM.")
    		addPerson(8, 2, 	@"Liewlom Bunnag",		@"Tested tweak on iPad 2nd Generation (Wi-Fi).")
    		addPerson(9, 2, 	@"@Xtoyou",				@"Tested tweak on iPad 3rd Generation (Global).")
    		addPerson(10, 2, 	@"@n4te2iver",			@"Tested tweak on iPad 4th Generation (Wi-Fi).")
    		addPerson(11, 1, 	@"@NavehIDL",			@"Tested tweak on iPad mini 1G (Wi-Fi).")
    		addPerson(12, 1, 	@"Srsw Omegax Akrw",	@"Tested tweak on iPad mini 1G (GSM).")
    		addPerson(13, 1,	@"@iPFaHaD",			@"Tested tweak on iPhone 4 GSM.")
    		addPerson(14, 1,	@"@H4lfSc0p3R",			@"Tested tweak on iPhone 4 GSM.")
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
  	CGSize size = [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] detailTextLabel] text] sizeWithFont:[UIFont systemFontOfSize:kFontSize] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
  	return 30.0f + [[[[self tableView:tableView cellForRowAtIndexPath:indexPath] detailTextLabel] text] sizeWithFont:[UIFont systemFontOfSize:(kFontSize + 0.5)] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap].height;
    
}

- (void)dealloc
{
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	[_tableView release];
	[super dealloc];
}

@end

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
@synthesize hideTextSpec;
@synthesize customTextSpec;
@synthesize inputTextSpec;
@synthesize blueButtonDescSpec, blueButtonSwitchSpec;
@synthesize LLBPanoDescSpec, LLBPanoSwitchSpec;
@synthesize PanoDarkFixDescSpec, PanoDarkFixSwitchSpec;
@synthesize FMDescSpec, FMSwitchSpec;

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
			if ([[[spec properties] objectForKey:@"id"] length] > 0)
				spec = nil;
		}
    [super viewDidUnload];
}

- (void)setWidth:(id)value specifier:(PSSpecifier *)spec
{
	rangeFix(3000, 21600)
	orig
	updateValue(maxWidthSpec, maxWidthSliderSpec, @"footerText", @"Current Width: %i pixels")
}

- (void)setPreviewWidth:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(100, 576)
	orig
	updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"footerText", @"Current Width: %f pixels")
}

- (void)setPreviewHeight:(id)value specifier:(PSSpecifier *)spec
{
	rangeFixFloat(40, 576)
	orig
	updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"footerText", @"Current Height: %f pixels")
}


- (void)setMinFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.maxFPSSliderSpec] intValue] < [NSNumber numberWithInt:([value intValue])].intValue)
		resetValue([value intValue], maxFPSSliderSpec, maxFPSInputSpec)

	rangeFix(1, 30)
	orig
	updateValue(maxFPSSpec, maxFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
	updateValue(minFPSSpec, minFPSSliderSpec, @"footerText", @"Current Framerate: %i FPS")
}

- (void)setMaxFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.minFPSSliderSpec] intValue] > [NSNumber numberWithInt:([value intValue])].intValue)
		resetValue([value intValue], minFPSSliderSpec, minFPSInputSpec)
	
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
	if ([value boolValue]) {
		[self.customTextSpec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
		[self.inputTextSpec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
	} else {
		[self.customTextSpec setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
		[self.inputTextSpec setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
	}
	[self reloadSpecifier:self.customTextSpec];
	[self reloadSpecifier:self.inputTextSpec];
}

- (void)resetValues:(id)param
{
	NSString *model = [self model];
	if (isiPhone4S || isiPhone5 || isiPod5 || isiPadMini1G || isiPad3or4) {
		resetValue(10800, maxWidthSliderSpec, maxWidthInputSpec)
	}
	else if (isiPhone3GS) {
		resetValue(2000, maxWidthSliderSpec, maxWidthInputSpec)
	} else {
		resetValue(4000, maxWidthSliderSpec, maxWidthInputSpec)
	}

	if (isiPhone5 || isiPad3or4) {
		resetValue(20, maxFPSSliderSpec, maxFPSInputSpec)
	} else {
		resetValue(15, maxFPSSliderSpec, maxFPSInputSpec)
	}

	if (isiPhone3GS) {
		resetValue(7, minFPSSliderSpec, minFPSInputSpec)
	} else {
		resetValue(15, minFPSSliderSpec, minFPSInputSpec)
	}

	if (isiPhone5 || isiPad3or4) {
		resetValue(5, PanoramaBufferRingSizeSliderSpec, PanoramaBufferRingSizeInputSpec)
	} else {
		resetValue(7, PanoramaBufferRingSizeSliderSpec, PanoramaBufferRingSizeInputSpec)
	}

	if (isiPhone5 || isiPad3or4) {
		resetValue(15, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	else if (isiPod5 || isiPadMini1G || isiPad2 || isiPod4 || isiPhone3GS) {
		resetValue(13, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	else if (isiPhone4S || isiPhone4) {
		resetValue(20, PanoramaPowerBlurSlopeSliderSpec, PanoramaPowerBlurSlopeInputSpec)
	}
	
	resetValue(306, previewWidthSliderSpec, previewWidthInputSpec)
	resetValue(86, previewHeightSliderSpec, previewHeightInputSpec)
	resetValue(30, PanoramaPowerBlurBiasSliderSpec, PanoramaPowerBlurBiasInputSpec)
	
	// Too lazy to reload everything I set above
	[self reloadSpecifiers];

}

- (void)setBoolAndKillCam:(id)value specifier:(PSSpecifier *)spec
{
	orig
	system("killall Camera");
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
			getSpec(minFPSInputSpec, @"MinFrameRateInput")
			getSpec(maxFPSSpec, @"MaxFrameRate")
			getSpec(maxFPSSliderSpec, @"MaxFrameRateSlider")
			getSpec(maxFPSInputSpec, @"MaxFrameRateInput")
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
        }
        
        NSString *model = [self model];
        if (!(isiPhone5 || isiPod5)) {
        	[specs removeObject:self.blueButtonDescSpec];
        	[specs removeObject:self.blueButtonSwitchSpec];
        	[specs removeObject:self.LLBPanoDescSpec];
        	[specs removeObject:self.LLBPanoSwitchSpec];
        }
        if (!(isiPhone4 || isiPhone4S || isiPhone5 || isiPod5)) {
        	[specs removeObject:self.FMDescSpec];
        	[specs removeObject:self.FMSwitchSpec];
        }
        if (isiPhone4S || isiPhone5 || isiPod5) {
        	[specs removeObject:self.PanoEnabledSpec];
        }

		if (![[self readPreferenceValue:self.hideTextSpec] boolValue]) {
			[self.customTextSpec setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
			[self.inputTextSpec setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
		} else {
			[self.customTextSpec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
			[self.inputTextSpec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
		}

        updateValue(maxWidthSpec, maxWidthSliderSpec, @"footerText", @"Current Width: %i pixels")
        updateFloatValue(previewWidthSpec, previewWidthSliderSpec, @"footerText", @"Current Width: %f pixels")
        updateFloatValue(previewHeightSpec, previewHeightSliderSpec, @"footerText", @"Current Height: %f pixels")
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

#define PanoModAddMethod(_class, _sel, _imp, _type) \
    if (![[_class class] instancesRespondToSelector:@selector(_sel)]) \
        class_addMethod([_class class], @selector(_sel), (IMP)_imp, _type)
        
id $PSViewController$initForContentSize$(PSRootController *self, SEL _cmd, CGRect contentSize) {
    return [self init];
}
        
static __attribute__((constructor)) void __PanoModInit() {
    PanoModAddMethod(PSViewController, initForContentSize:, $PSViewController$initForContentSize$, "@@:{ff}");
}
