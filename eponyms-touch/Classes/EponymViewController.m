//
//  EponymViewController.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the eponym view for eponyms-touch
//  


#import "eponyms_touchAppDelegate.h"
#import "EponymViewController.h"
#import "ListViewController.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "MCTextView.h"
#import "PPHintableLabel.h"
#import "PPHintView.h"
#ifdef SHOW_GOOGLE_ADS
#	import "GoogleAdSenseClient.h"
#endif


#define kSideMargin 15.f
#define kLabelSideMargin 5.f
#define kHeightTitle 32.f
#define kDistanceTextFromTitle 8.f
#define kDistanceCatLabelFromText 8.f
#define kDistanceDateLabelsFromCat 8.f
#define kTotalSizeBottomMargin 10.f
#define kGoogleAdViewTopMargin 0.f			// additionally to kTotalSizeBottomMargin
#define kBottomMargin 5.f					// does not apply to the Google Ads




@interface EponymViewController ()

- (void) adjustInterfaceToEponym;
- (void) alignUIElements;
- (void) showRandomEponym:(id)sender;

#ifdef SHOW_GOOGLE_ADS
@property (nonatomic, readwrite, retain) GADBannerView *adView;

- (BOOL) adViewIsVisible;
- (void) loadGoogleAdsWithEponym:(Eponym *)eponym;
- (void) assureGoogleAdsVisibleInView:(UIView *)inView;
#endif

@end



@implementation EponymViewController

@dynamic eponymToBeShown;
@dynamic rightBarButtonStarredItem;
@dynamic rightBarButtonNotStarredItem;
@dynamic eponymTitleLabel;
@dynamic eponymTextView;
@dynamic eponymCategoriesLabel;
@dynamic dateCreatedLabel;
@dynamic dateUpdatedLabel;
@dynamic randomNoTitleEponymButton;
@dynamic randomNoTextEponymButton;
@dynamic revealButton;
@synthesize displayNextEponymInLearningMode;
#ifdef SHOW_GOOGLE_ADS
@synthesize adView;
#endif


- (void) dealloc
{
	[eponymToBeShown release];
	
	self.rightBarButtonStarredItem = nil;
	self.rightBarButtonNotStarredItem = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	self.randomNoTitleEponymButton = nil;
	self.randomNoTextEponymButton = nil;
	self.revealButton = nil;
	
#ifdef SHOW_GOOGLE_ADS
	adView.delegate = nil;
	self.adView = nil;
#endif
	
	[super dealloc];
}

- (void) viewDidUnload
{
	self.rightBarButtonStarredItem = nil;
	self.rightBarButtonNotStarredItem = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	self.randomNoTitleEponymButton = nil;
	self.randomNoTextEponymButton = nil;
	self.revealButton = nil;
	
#ifdef SHOW_GOOGLE_ADS
	adView.delegate = nil;
	self.adView = nil;
#endif
	
	[super viewDidUnload];
}


- (id) init
{
	return [self initWithNibName:nil bundle:nil];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = @"Eponym";
#ifdef SHOW_GOOGLE_ADS
		adSize = GAD_SIZE_320x50;
#endif
	}
	return self;
}
#pragma mark -



#pragma mark GUI
- (void) loadView
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	// The main view
	self.view = [[[UIScrollView alloc] initWithFrame:screenRect] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.view.backgroundColor = [UIColor colorWithRed:0.936f green:0.953f blue:0.968f alpha:1.f];
	}
	else {
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view.autoresizesSubviews = YES;
	((UIScrollView *)self.view).delegate = self;
	
	[self.view addSubview:self.eponymTitleLabel];
	
	// Compose the container (contains eponym text, the category labels and the date labels)
	CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
	CGRect containerRect = CGRectMake(kSideMargin, kSideMargin + kHeightTitle + kDistanceTextFromTitle, fullWidth, 20.0);
	
	UIView *container = [[[UIView alloc] initWithFrame:containerRect] autorelease];
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
	container.autoresizesSubviews = YES;
	
	// add subviews to the container
	[container addSubview:self.eponymTextView];
	[container addSubview:self.eponymCategoriesLabel];
	[container addSubview:self.dateCreatedLabel];
	[container addSubview:self.dateUpdatedLabel];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[container addSubview:self.randomNoTitleEponymButton];
		[container addSubview:self.randomNoTextEponymButton];
	}
	
	[self.view addSubview:container];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self alignUIElements];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	viewIsVisible = YES;
#ifdef SHOW_GOOGLE_ADS
	if ([self adViewIsVisible]) {
		[self loadGoogleAdsWithEponym:eponymToBeShown];
	}
#endif
}

- (void) viewWillDisappear:(BOOL)animated
{
	viewIsVisible = NO;
	[super viewWillDisappear:animated];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (APP_DELEGATE.allowAutoRotate) {
		return YES;
	}
	
	return IS_PORTRAIT(toInterfaceOrientation);
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self alignUIElements];
}
#pragma mark -



#pragma mark Eponym Display
- (void) adjustInterfaceToEponym
{
	((UIScrollView *)self.view).contentOffset = CGPointZero;
	
	// starred or not starred, that's the question
	[self indicateEponymStarredStatus];
	
	// title and text
	eponymTitleLabel.text = (EPLearningModeNoTitle == displayNextEponymInLearningMode) ? @"…" : eponymToBeShown.title;
	eponymTextView.text = (EPLearningModeNoText == displayNextEponymInLearningMode) ? @"…" : eponymToBeShown.text;
	eponymTextView.contentOffset = CGPointZero;
	[eponymTextView resignFirstResponder];
	
	// enable revealButton
	if (EPLearningModeNoTitle == displayNextEponymInLearningMode) {
		self.revealButton.frame = eponymTitleLabel.bounds;
		[eponymTitleLabel addSubview:revealButton];
	}
	else if (EPLearningModeNoText == displayNextEponymInLearningMode) {
		self.revealButton.frame = eponymTextView.bounds;
		[eponymTextView addSubview:revealButton];
	}
	
	// categories
	if ([eponymToBeShown.categories count] > 0) {
		NSMutableArray *eponymCategories = [NSMutableArray arrayWithCapacity:[eponymToBeShown.categories count]];
		NSMutableArray *eponymCategoriesDesc = [NSMutableArray arrayWithCapacity:[eponymToBeShown.categories count]];
		for (EponymCategory *cat in eponymToBeShown.categories) {
			[eponymCategories addObject:cat.tag];
			[eponymCategoriesDesc addObject:[NSString stringWithFormat:@"%@ • %@", cat.tag, cat.title]];
		}
		eponymCategoriesLabel.text = [eponymCategories componentsJoinedByString:@", "];
		eponymCategoriesLabel.hintText = [eponymCategoriesDesc componentsJoinedByString:@"\n"];
	}
	else {
		eponymCategoriesLabel.text = @"";
	}
	
	// dates
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	if (eponymToBeShown.created) {
		dateCreatedLabel.hidden = NO;
		dateCreatedLabel.text = [NSString stringWithFormat:@"Created: %@", [dateFormatter stringFromDate:eponymToBeShown.created]];
	}
	else {
		dateCreatedLabel.hidden = YES;
	}
	
	if (eponymToBeShown.lastedit) {
		dateUpdatedLabel.hidden = NO;
		dateUpdatedLabel.text = [NSString stringWithFormat:@"Updated: %@", [dateFormatter stringFromDate:eponymToBeShown.lastedit]];
	}
	else {
		dateUpdatedLabel.hidden = YES;
	}
	
	// adjust content
	[self alignUIElements];
	
	// load ads
#ifdef SHOW_GOOGLE_ADS
	if (EPLearningModeNone == displayNextEponymInLearningMode && [self adViewIsVisible]) {
		[self performSelector:@selector(loadGoogleAdsWithEponym:) withObject:eponymToBeShown afterDelay:0.4];
	}
#endif
	
	displayNextEponymInLearningMode = EPLearningModeNone;
}

- (void) alignUIElements
{
	CGRect viewFrame = self.view.frame;
	CGFloat scaleFactor = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1.5f : 1.f;
	
	// Size needed to fit all text
	CGRect currRect = eponymTextView.frame;
	CGSize szMax = CGSizeMake(currRect.size.width, 10000.0);
	CGSize optimalSize = [eponymTextView sizeThatFits:szMax];
	
	if (optimalSize.height < 10000.0) {
		currRect.size.height = optimalSize.height;
	}
	eponymTextView.frame = currRect;
	
	// Align the labels below
	CGRect catRect = eponymCategoriesLabel.frame;
	catRect.origin.x = currRect.origin.x + kLabelSideMargin;
	catRect.origin.y = currRect.size.height + roundf(kDistanceCatLabelFromText * scaleFactor);
	catRect.size.width = [eponymCategoriesLabel.text sizeWithFont:eponymCategoriesLabel.font].width;
	eponymCategoriesLabel.frame = catRect;
	
	CGFloat subviewHeight = catRect.origin.y + catRect.size.height;
	
	if (!dateCreatedLabel.hidden) {
		CGRect creaRect = dateCreatedLabel.frame;
		creaRect.origin.y = subviewHeight + roundf(kDistanceDateLabelsFromCat * scaleFactor);
		dateCreatedLabel.frame = creaRect;
		subviewHeight = creaRect.origin.y + creaRect.size.height;
	}
	
	if (!dateUpdatedLabel.hidden) {
		CGRect updRect = dateUpdatedLabel.frame;
		updRect.origin.y = subviewHeight + 1.f;
		dateUpdatedLabel.frame = updRect;
		subviewHeight = updRect.origin.y + updRect.size.height;
	}
	
	// "random eponym" buttons on iPad
	if (randomNoTitleEponymButton && randomNoTextEponymButton) {
		CGFloat orig = subviewHeight + roundf(kDistanceDateLabelsFromCat * scaleFactor);
		
		CGRect buttRect = randomNoTitleEponymButton.frame;
		buttRect.origin.y = orig;
		randomNoTitleEponymButton.frame = buttRect;
		
		buttRect = randomNoTextEponymButton.frame;
		buttRect.origin.y = orig;
		randomNoTextEponymButton.frame = buttRect;
		
		subviewHeight = orig + buttRect.size.height;
	}
	
	// tell the container view its new height
	subviewHeight += kTotalSizeBottomMargin;
	CGRect superRect = [eponymTextView superview].frame;
	superRect.size.height = subviewHeight;
	[eponymTextView superview].frame = superRect;
	
	CGFloat totalHeight = superRect.origin.y + superRect.size.height + kBottomMargin;
	
	// adjust Google ads
#ifdef SHOW_GOOGLE_ADS
	if (self.adView) {
		CGFloat googleMin = viewFrame.size.height - adSize.height;
		CGFloat googleY = superRect.origin.y + superRect.size.height + kGoogleAdViewTopMargin;
		CGFloat googleTop = fmaxf(googleY, googleMin);
		CGRect adRect = CGRectMake(0.f, googleTop, adSize.width, adSize.height);
		
		adView.frame = adRect;
		totalHeight = adRect.origin.y + adRect.size.height;
	}
#endif
	
	// tell our view the size so that scrolling is possible
	CGFloat minHeight = viewFrame.size.height;
	CGSize contSize = CGSizeMake(((UIScrollView *)self.view).contentSize.width, totalHeight);
	((UIScrollView *)self.view).contentSize = contSize;
	
	// scroll to top when needed
	if (totalHeight < minHeight) {
		[((UIScrollView *)self.view) scrollRectToVisible:CGRectMake(0.f, 0.f, 10.f, 10.f) animated:NO];
	}
}


- (void) showRandomEponym:(id)sender
{
	if (randomNoTitleEponymButton == sender) {
		[APP_DELEGATE loadRandomEponymWithMode:EPLearningModeNoTitle];
	}
	else {
		[APP_DELEGATE loadRandomEponymWithMode:EPLearningModeNoText];
	}
}

- (IBAction) reveal:(id)sender
{
	[revealButton removeFromSuperview];
	[APP_DELEGATE resetEponymRefractoryTimeout];
	[[APP_DELEGATE listController] assureEponymSelectedInListAnimated:NO];
	
	eponymTitleLabel.text = eponymToBeShown.title;
	eponymTextView.text = eponymToBeShown.text;
	//eponymTextView.text = [NSString stringWithFormat:@"%@ %@ %@ %@", eponymToBeShown.text, eponymToBeShown.text, eponymToBeShown.text, eponymToBeShown.text];		// to test long eponyms
	
	[UIView beginAnimations:nil context:nil];
	[self alignUIElements];
	[UIView commitAnimations];
	
	// load ads
#ifdef SHOW_GOOGLE_ADS
	if ([self adViewIsVisible]) {
		[self performSelector:@selector(loadGoogleAdsWithEponym:) withObject:eponymToBeShown afterDelay:0.4];
	}
#endif
}
#pragma mark -



#pragma mark Toggle Starred
- (void) toggleEponymStarred:(id)sender
{
	[eponymToBeShown toggleStarred];
	[self indicateEponymStarredStatus];
	[[APP_DELEGATE listController] assureSelectedEponymStarredInList];
}

- (void) indicateEponymStarredStatus
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.leftBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	}
	else {
		self.navigationItem.rightBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	}
}
#pragma mark -



#pragma mark KVC
- (Eponym *) eponymToBeShown
{
	return eponymToBeShown;
}
- (void) setEponymToBeShown:(Eponym *)newEponym
{
	if (newEponym != eponymToBeShown) {
		[eponymToBeShown release];
		eponymToBeShown = [newEponym retain];
		
		if (nil != eponymToBeShown) {
#ifdef SHOW_GOOGLE_ADS
			adDidLoadForThisEponym = NO;
#endif
			[self adjustInterfaceToEponym];
		}
	}
}

- (UIBarButtonItem *) rightBarButtonStarredItem
{
	if (nil == rightBarButtonStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[APP_DELEGATE starImageEponymActive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonStarredItem = [[[UIBarButtonItem alloc] initWithCustomView:myButton] autorelease];
	}
	return rightBarButtonStarredItem;
}

- (void) setRightBarButtonStarredItem:(UIBarButtonItem *)newBarButtonItem
{
	if (newBarButtonItem != rightBarButtonStarredItem) {
		[rightBarButtonStarredItem release];
		rightBarButtonStarredItem = [newBarButtonItem retain];
	}
}

- (UIBarButtonItem *) rightBarButtonNotStarredItem
{
	if (nil == rightBarButtonNotStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[APP_DELEGATE starImageEponymInactive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonNotStarredItem = [[[UIBarButtonItem alloc] initWithCustomView:myButton] autorelease];
	}
	return rightBarButtonNotStarredItem;
}
- (void) setRightBarButtonNotStarredItem:(UIBarButtonItem *)newBarButtonItem
{
	if (newBarButtonItem != rightBarButtonNotStarredItem) {
		[rightBarButtonNotStarredItem release];
		rightBarButtonNotStarredItem = [newBarButtonItem retain];
	}
}

- (UILabel *) eponymTitleLabel
{
	if (nil == eponymTitleLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect titleRect = CGRectMake(kSideMargin, kSideMargin, fullWidth, kHeightTitle);
		
		self.eponymTitleLabel = [[[UILabel alloc] initWithFrame:titleRect] autorelease];
		eponymTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymTitleLabel.userInteractionEnabled = YES;
		eponymTitleLabel.font = [UIFont boldSystemFontOfSize:24.f];
		eponymTitleLabel.numberOfLines = 1;
		eponymTitleLabel.adjustsFontSizeToFitWidth = YES;
		eponymTitleLabel.minimumFontSize = 12.f;
		eponymTitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		eponymTitleLabel.backgroundColor = [UIColor clearColor];
		eponymTitleLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
		eponymTitleLabel.shadowOffset = CGSizeMake(0.f, 1.f);
	}
	return eponymTitleLabel;
}
- (void) setEponymTitleLabel:(UILabel *)newTitle
{
	if (newTitle != eponymTitleLabel) {
		[eponymTitleLabel release];
		eponymTitleLabel = [newTitle retain];
	}
}

- (MCTextView *) eponymTextView
{
	if (nil == eponymTextView) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect textRect = CGRectMake(0.f, 0.f, fullWidth, 40.f);
		
		self.eponymTextView = [[[MCTextView alloc] initWithFrame:textRect] autorelease];
		eponymTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymTextView.userInteractionEnabled = YES;
		eponymTextView.scrollEnabled = NO;
		eponymTextView.editable = NO;
		eponymTextView.font = [UIFont systemFontOfSize:17.f];
		eponymTextView.borderColor = [UIColor colorWithWhite:0.6f alpha:1.f];
	}
	return eponymTextView;
}
- (void) setEponymTextView:(MCTextView *)newTextView
{
	if (newTextView != eponymTextView) {
		[eponymTextView release];
		eponymTextView = [newTextView retain];
	}
}

- (PPHintableLabel *) eponymCategoriesLabel
{
	if (nil == eponymCategoriesLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect catRect = CGRectMake(kLabelSideMargin, kDistanceCatLabelFromText, labelWidth, 19.f);
		
		self.eponymCategoriesLabel = [[[PPHintableLabel alloc] initWithFrame:catRect] autorelease];
		eponymCategoriesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymCategoriesLabel.adjustsFontSizeToFitWidth = YES;
		eponymCategoriesLabel.minimumFontSize = 12.f;
		eponymCategoriesLabel.font = [UIFont systemFontOfSize:17.f];
		eponymCategoriesLabel.backgroundColor = [UIColor clearColor];
		eponymCategoriesLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
		eponymCategoriesLabel.shadowOffset = CGSizeMake(0.f, 1.f);
	}
	return eponymCategoriesLabel;
}
- (void) setEponymCategoriesLabel:(PPHintableLabel *)newLabel
{
	if (newLabel != eponymCategoriesLabel) {
		[eponymCategoriesLabel release];
		eponymCategoriesLabel = [newLabel retain];
	}
}

- (UILabel *) dateCreatedLabel
{
	if (nil == dateCreatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateCreatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateCreatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateCreatedLabel.textColor = [UIColor darkGrayColor]; 
		dateCreatedLabel.font = [UIFont systemFontOfSize:14.0];
		dateCreatedLabel.backgroundColor = [UIColor clearColor];
		dateCreatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		dateCreatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return dateCreatedLabel;
}
- (void) setDateCreatedLabel:(UILabel *)newLabel
{
	if (newLabel != dateCreatedLabel) {
		[dateCreatedLabel release];
		dateCreatedLabel = [newLabel retain];
	}
}

- (UILabel *) dateUpdatedLabel
{
	if (nil == dateUpdatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateUpdatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateUpdatedLabel.textColor = [UIColor darkGrayColor]; 
		dateUpdatedLabel.font = [UIFont systemFontOfSize:14.0];
		dateUpdatedLabel.backgroundColor = [UIColor clearColor];
		dateUpdatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		dateUpdatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return dateUpdatedLabel;
}
- (void) setDateUpdatedLabel:(UILabel *)newLabel
{
	if (newLabel != dateUpdatedLabel) {
		[dateUpdatedLabel release];
		dateUpdatedLabel = [newLabel retain];
	}
}

- (UIButton *) randomNoTitleEponymButton
{
	if (nil == randomNoTitleEponymButton) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat buttonWidth = roundf((fullWidth - kSideMargin) / 2);
		CGRect buttonRect = CGRectMake(0.f, kDistanceDateLabelsFromCat, buttonWidth, 37.f);
		
		self.randomNoTitleEponymButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[randomNoTitleEponymButton setTitle:@"Random Eponym"
								   forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[randomNoTitleEponymButton setTitleColor:[UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f] forState:UIControlStateNormal];
		[randomNoTitleEponymButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		
		// background image
		UIImage *buttonImage = [[UIImage imageNamed:@"RoundedButton.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[randomNoTitleEponymButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		UIImage *buttonHighImage = [[UIImage imageNamed:@"RoundedButtonBlue.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[randomNoTitleEponymButton setBackgroundImage:buttonHighImage forState:UIControlStateHighlighted];
		
		// action
		[randomNoTitleEponymButton addTarget:self action:@selector(showRandomEponym:) forControlEvents:UIControlEventTouchUpInside];
		
		// properties
		randomNoTitleEponymButton.frame = buttonRect;
		randomNoTitleEponymButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	}
	return randomNoTitleEponymButton;
}
- (void) setRandomNoTitleEponymButton:(UIButton *)newButton
{
	if (newButton != randomNoTitleEponymButton) {
		[randomNoTitleEponymButton release];
		randomNoTitleEponymButton = [newButton retain];
	}
}

- (UIButton *) randomNoTextEponymButton
{
	if (nil == randomNoTextEponymButton) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat buttonWidth = roundf(fullWidth / 2 - kSideMargin);
		CGRect buttonRect = CGRectMake(fullWidth - buttonWidth, kDistanceDateLabelsFromCat, buttonWidth, 37.f);
		
		self.randomNoTextEponymButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[randomNoTextEponymButton setTitle:@"Random Title"
								   forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[randomNoTextEponymButton setTitleColor:[UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f] forState:UIControlStateNormal];
		[randomNoTextEponymButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		
		// background image
		UIImage *buttonImage = [[UIImage imageNamed:@"RoundedButton.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[randomNoTextEponymButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		UIImage *buttonHighImage = [[UIImage imageNamed:@"RoundedButtonBlue.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[randomNoTextEponymButton setBackgroundImage:buttonHighImage forState:UIControlStateHighlighted];
		
		// action
		[randomNoTextEponymButton addTarget:self action:@selector(showRandomEponym:) forControlEvents:UIControlEventTouchUpInside];
		
		// properties
		randomNoTextEponymButton.frame = buttonRect;
		randomNoTextEponymButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	}
	return randomNoTextEponymButton;
}
- (void) setRandomNoTextEponymButton:(UIButton *)newButton
{
	if (newButton != randomNoTextEponymButton) {
		[randomNoTextEponymButton release];
		randomNoTextEponymButton = [newButton retain];
	}
}

- (UIButton *) revealButton
{
	if (nil == revealButton) {
		self.revealButton = [UIButton buttonWithType:UIButtonTypeCustom];
		
		// action and resizing
		[revealButton addTarget:self action:@selector(reveal:) forControlEvents:UIControlEventTouchUpInside];
		revealButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return revealButton;
}
- (void) setRevealButton:(UIButton *)newButton
{
	if (newButton != revealButton) {
		[revealButton release];
		revealButton = [newButton retain];
	}
}
#pragma mark -



#pragma mark Scroll View Delegate
#ifdef SHOW_GOOGLE_ADS
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (!adIsLoading && !adDidLoadForThisEponym && [self adViewIsVisible]) {
		[self loadGoogleAdsWithEponym:eponymToBeShown];
	}
}
#endif
#pragma mark -



#ifdef SHOW_GOOGLE_ADS
#pragma mark Google Ads
- (void) setAdRootController
{
	if (!adView.rootViewController) {
		UIViewController *root = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			? (UIViewController *)APP_DELEGATE.splitController
			: self.navigationController;
		
		adView.rootViewController = root;
	}
}

- (GADBannerView *) adView
{
	if (nil == adView) {
		adIsLoading = NO;
		
		CGRect adFrame = CGRectZero;
		adFrame.size = adSize;
		self.adView = [[[GADBannerView alloc] initWithFrame:adFrame] autorelease];
		adView.adUnitID = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kAdMobIPadID : kAdMobIPhoneID;
		adView.delegate = self;
		[self setAdRootController];
		
		//adView.autoresizingMask = UIViewAutoresizingFlexibleWidth;		// not stretchable at the moment
	}
	return adView;
}


- (BOOL) adViewIsVisible
{
	BOOL adIsVisible = NO;
	if (viewIsVisible && self.adView) {
		UIScrollView *scrollView = (UIScrollView *)self.view;
		CGRect adRect = [adView frame];
		CGFloat adMiddle = adRect.origin.y + (adRect.size.height / 2);
		CGFloat lowestVisible = scrollView.frame.size.height + scrollView.contentOffset.y;
		adIsVisible = (adMiddle <= lowestVisible);
	}
	return adIsVisible;
}

- (void) assureGoogleAdsVisibleInView:(UIView *)inView
{
	if (self.adView) {
		UIView *oldSuperview = [adView superview];
		if (nil != oldSuperview && oldSuperview != inView) {
			[adView removeFromSuperview];
			oldSuperview = nil;
		}
		
		if (nil == oldSuperview) {
			[inView addSubview:adView];
		}
	}
}

- (void) loadGoogleAdsWithEponym:(Eponym *)eponym
{
	if (!adIsLoading && !adDidLoadForThisEponym && self.adView) {
		NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
		if (now < adsAreRefractoryUntil) {
			return;
		}
		adsAreRefractoryUntil = now + 30.0;					// at max load a new ad every 30 seconds
		adIsLoading = YES;
		
		// create the request
		GADRequest *request = [GADRequest request];
		[request addKeyword:@"medical eponyms"];
		for (EponymCategory *cat in eponym.categories) {
			[request addKeyword:cat.title];
		}
		[request addKeyword:eponym.title];
#ifdef DEBUG
		request.testDevices = [NSArray arrayWithObject:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
		request.additionalParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										@"00346C", @"color_bg",
										@"094784", @"color_bg_top",
										@"001328", @"color_border",
										@"FFFFFF", @"color_link",
										@"EEEEEE", @"color_text",
										@"FFD400", @"color_url",
										nil];
		
		// fire!
		[self setAdRootController];
		[adView loadRequest:request];
	}
}
#pragma mark -



#pragma mark Ad Delegate
- (void) adViewDidDismissScreen:(GADBannerView *)bannerView
{
	[UIAccelerometer sharedAccelerometer].delegate = APP_DELEGATE;			// still needed? TEST!
}

- (void) adViewDidReceiveAd:(GADBannerView *)bannerView
{
	//DLog(@"Ad load Succeeded");
	[self assureGoogleAdsVisibleInView:self.view];
	adIsLoading = NO;
	adDidLoadForThisEponym = YES;
}

- (void) adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
	//DLog(@"Ad load Failed: %@", [error userInfo]);
	[bannerView removeFromSuperview];
	adIsLoading = NO;
}
#endif


@end
