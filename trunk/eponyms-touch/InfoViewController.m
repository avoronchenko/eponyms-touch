//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the info screen for eponyms-touch
//  


#import "eponyms_touchAppDelegate.h"
#import "InfoViewController.h"
#import "EponymUpdater.h"


#define CANCEL_IMPORT_TITLE @"Cancel import?"


@interface InfoViewController (Private)

- (void) adjustContentToOrientation:(UIInterfaceOrientation)newOrientation animated:(BOOL)animated;
- (void) switchToTab:(NSUInteger)tab;
- (void) lockGUI:(BOOL)lock;
- (void) newEponymsAreAvailable:(BOOL)available;
- (void) resetStatusElementsWithButtonTitle:(NSString *)buttonTitle;

@end




@implementation InfoViewController

@synthesize delegate, firstTimeLaunch, lastEponymCheck, lastEponymUpdate, tabSegments, infoPlistDict, projectWebsiteURL;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		askingToAbortImport = NO;
		
		// compose the navigation bar
		NSArray *possibleTabs = [NSArray arrayWithObjects:@"About", @"Update", @"Options", nil];
		self.tabSegments = [[UISegmentedControl alloc] initWithItems:possibleTabs];
		tabSegments.selectedSegmentIndex = 0;
		tabSegments.segmentedControlStyle = UISegmentedControlStyleBar;
		tabSegments.frame = CGRectMake(0.0, 0.0, 220.0, 30.0);
		tabSegments.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[tabSegments addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.titleView	= tabSegments;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissMe:)] autorelease];
		
		// NSBundle Info.plist
		self.infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.projectWebsiteURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"projectWebsite"]];
	}
	return self;
}

- (void) dealloc
{
	self.infoPlistDict = nil;
	self.projectWebsiteURL = nil;
	self.tabSegments = nil;
	
	// IBOutlets
	[infoView release];
	[updatesView release];
	[optionsView release];
	[backgroundImage release];
	
	[versionLabel release];
	[usingEponymsLabel release];
	[authorTextView release];
	[propsTextView release];
	
	[projectWebsiteButton release];
	[eponymsDotNetButton release];
	
	[lastCheckLabel release];
	[lastUpdateLabel release];
	
	[progressText release];
	[progressView release];
	
	[updateButton release];
	[autocheckSwitch release];
	
	[allowRotateSwitch release];
	
	[super dealloc];
}
#pragma mark -



#pragma mark View Controller Delegate
- (void) viewDidLoad
{
	self.view = infoView;
	
	tabSegments.tintColor = [delegate naviBarTintColor];
	[self switchToTab:0];
	lastInterfaceOrientation = UIInterfaceOrientationPortrait;
	
	// hide progress stuff
	[self setStatusMessage:nil];
	[self resetStatusElementsWithButtonTitle:nil];
	
	projectWebsiteButton.autoresizingMask = UIViewAutoresizingNone;
	eponymsDotNetButton.autoresizingMask = UIViewAutoresizingNone;
	propsTextView.autoresizingMask = UIViewAutoresizingNone;
	
	// last update date/time
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSince1970:lastEponymCheck];
	NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastEponymUpdate];
	NSDate *usingEponymsDate = [NSDate dateWithTimeIntervalSince1970:[delegate usingEponymsOf]];
	[self updateLabelsWithDateForLastCheck:lastCheckDate lastUpdate:lastUpdateDate usingEponyms:usingEponymsDate];
	
	// version
	NSString *version = [NSString stringWithFormat:@"Version %@  (%@)", [infoPlistDict objectForKey:@"CFBundleVersion"], [infoPlistDict objectForKey:@"SubversionRevision"]];
	[versionLabel setText:version];
}

- (void) viewWillAppear:(BOOL)animated
{
	BOOL mustSeeProgress = firstTimeLaunch || [delegate newEponymsAvailable];
	
	if(mustSeeProgress) {
		[self switchToTab:1];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	if(firstTimeLaunch) {
		NSString *title = @"First Launch";
		NSString *message = @"Welcome to Eponyms!\nBefore using Eponyms, the database must be created.";
		
		[self alertViewWithTitle:title message:message cancelTitle:@"OK"];		// maybe allow postponing first import?
	}
	
	// Adjust options
	autocheckSwitch.on = [delegate shouldAutoCheck];
	
	[self adjustContentToOrientation:[self interfaceOrientation] animated:NO];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate) {
		[self adjustContentToOrientation:interfaceOrientation animated:YES];
		return YES;
	}
	
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
}

- (void) adjustContentToOrientation:(UIInterfaceOrientation)newOrientation animated:(BOOL)animated
{
	if(newOrientation != lastInterfaceOrientation) {
		CGPoint websiteCenter;
		CGPoint eponymsNetCenter;
		CGRect propsFrame;
		
		// get dimensions
		CGSize screenSize;// = infoView.frame.size;		// can't use this here since upon calling infoView still has the old dimensions
		CGRect foo = authorTextView.frame;
		CGPoint authorsOrigin = foo.origin;
		CGFloat authorsHeight = foo.size.height;
		
		// to Portrait
		if((UIInterfaceOrientationPortrait == newOrientation) || (UIInterfaceOrientationPortraitUpsideDown == newOrientation)) {
			screenSize = CGSizeMake(320, 416);
			websiteCenter = CGPointMake(roundf((screenSize.width - 48.0) / 4) + 20.0,			// - 48 = - 2*20 (margin) + -8 (space between buttons)
										authorsOrigin.y + authorsHeight + (projectWebsiteButton.bounds.size.height / 2) + 10);
			eponymsNetCenter = CGPointMake(roundf((screenSize.width - 48.0) / 4 * 3) + 28.0,	// + 28 = + 20 (margin) + 8 (space between buttons)
										   authorsOrigin.y + authorsHeight + (projectWebsiteButton.bounds.size.height / 2) + 10);
			CGFloat propsFrameY = authorsOrigin.y + authorsHeight + projectWebsiteButton.bounds.size.height + 20;
			propsFrame = CGRectMake(20,
									propsFrameY,
									screenSize.width - 40,
									screenSize.height - propsFrameY - 20);
		}
		
		// Landscape
		else {
			screenSize = CGSizeMake(480, 268);
			websiteCenter = CGPointMake(screenSize.width - roundf((projectWebsiteButton.bounds.size.width / 2) + 20), 38.5);
			eponymsNetCenter = CGPointMake(screenSize.width - roundf((eponymsDotNetButton.bounds.size.width / 2) + 20), 86.5);
			CGFloat propsFrameY = authorsOrigin.y + authorsHeight;
			propsFrame = CGRectMake(20,
									propsFrameY,
									screenSize.width - 40,
									screenSize.height - propsFrameY - 20);
		}
		
		// Start animation
		if(animated) {
			[UIView beginAnimations:nil context:nil];
			
			projectWebsiteButton.center = websiteCenter;
			eponymsDotNetButton.center = eponymsNetCenter;
			propsTextView.frame = propsFrame;
			
			[UIView commitAnimations];
		}
		else {
			projectWebsiteButton.center = websiteCenter;
			eponymsDotNetButton.center = eponymsNetCenter;
			propsTextView.frame = propsFrame;
		}
	}
	
	lastInterfaceOrientation = newOrientation;
}

- (void) didReceiveMemoryWarning
{
	[self dismissMe:nil];
	[super didReceiveMemoryWarning];		// Releases the view if it doesn't have a superview !!
}

- (void) dismissMe:(id)sender
{
	// warning when closing during import
	if([delegate iAmUpdating]) {
		askingToAbortImport = YES;
		NSString *warning = @"Are you sure you want to abort the eponym import? This will discard any imported eponyms.";
		[self alertViewWithTitle:CANCEL_IMPORT_TITLE message:warning cancelTitle:@"Continue" otherTitle:@"Abort Import"];
	}
	
	// not importing
	else {
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
}
#pragma mark -



#pragma mark GUI
- (void) tabChanged:(id)sender
{
	UISegmentedControl *segment = sender;
	[self switchToTab:segment.selectedSegmentIndex];
}

- (void) switchToTab:(NSUInteger)tab
{
	tabSegments.selectedSegmentIndex = tab;
	if([backgroundImage superview]) {
		[backgroundImage removeFromSuperview];
	}
	
	// Show the About page
	if(0 == tab) {
		self.view = infoView;
	}
	
	// Show the update tab
	else if(1 == tab) {
		self.view = updatesView;
		
		// adjust the elements
		if([delegate didCheckForNewEponyms]) {
			[self newEponymsAreAvailable:[delegate newEponymsAvailable]];
		}
	}
	
	// Show the options
	else {
		self.view = optionsView;
		
		// adjust the elements
		allowRotateSwitch.on = ((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate;
	}
	
	[self.view insertSubview:backgroundImage atIndex:0];
}

- (void) newEponymsAreAvailable:(BOOL)available
{
	NSString *statusMessage = nil;
	if(available) {
		statusMessage = @"New eponyms are available!";
		[self setUpdateButtonTitle:@"Download New Eponyms"];
		[self setUpdateButtonTitleColor:[UIColor redColor]];
		[self setProgress:-1.0];
	}
	else {
		statusMessage = @"You are up to date";
		[self resetStatusElementsWithButtonTitle:nil];
	}
	
	[self setStatusMessage:statusMessage];
}

- (void) resetStatusElementsWithButtonTitle:(NSString *)buttonTitle
{
	[self setUpdateButtonTitle:(buttonTitle ? buttonTitle : @"Check for Eponym Updates")];
	[self setUpdateButtonTitleColor:nil];
	[self setProgress:-1.0];
}

- (void) lockGUI:(BOOL)lock
{
	if(lock) {
		updateButton.enabled = NO;
		projectWebsiteButton.enabled = NO;
		eponymsDotNetButton.enabled = NO;
		autocheckSwitch.enabled = NO;
		self.navigationItem.rightBarButtonItem.title = @"Abort";
	}
	else {
		updateButton.enabled = YES;
		projectWebsiteButton.enabled = YES;
		eponymsDotNetButton.enabled = YES;
		autocheckSwitch.enabled = YES;
		self.navigationItem.rightBarButtonItem.title = @"Done";
	}
}

- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// last check
	if(lastCheck) {
		[lastCheckLabel setText:([lastCheck timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastCheck] : @"Never"];
	}
	
	// last update
	if(lastUpdate) {
		[lastUpdateLabel setText:([lastUpdate timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastUpdate] : @"Never"];
	}
	
	// using eponyms
	if(usingEponyms) {
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSString *usingEponymsString = ([usingEponyms timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:usingEponyms] : @"Unknown";
		[usingEponymsLabel setText:[NSString stringWithFormat:@"Eponyms Date: %@", usingEponymsString]];
	}
	
	[dateFormatter release];
}


- (void) setUpdateButtonTitle:(NSString *)title
{
	[updateButton setTitle:title forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
}

- (void) setUpdateButtonTitleColor:(UIColor *)color
{
	if(nil == color) {
		color = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];		// default button text color
	}
	[updateButton setTitleColor:color forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void) setStatusMessage:(NSString *)message
{
	if(message) {
		// check message length
		CGFloat maxPossibleWidth = progressText.bounds.size.width * 1.1;		// text will be squeezed, so we allow a little overhead
		CGFloat isWidth = [message sizeWithFont:progressText.font].width;
		if(isWidth > maxPossibleWidth) {
			CGFloat fraction = maxPossibleWidth / isWidth;
			NSUInteger useNumChars = roundf([message length] * fraction);
			
			message = [NSString stringWithFormat:@"%@...", [message stringByPaddingToLength:useNumChars withString:@"X" startingAtIndex:0]];
		}
		
		progressText.textColor = [UIColor blackColor];
		progressText.text = message;
	}
	else {
		progressText.textColor = [UIColor grayColor];
		progressText.text = @"Ready";
	}
}

- (void) setProgress:(CGFloat)progress
{
	if(progress >= 0.0) {
		progressView.hidden = NO;
		progressView.progress = progress;
	}
	else {
		progressView.hidden = YES;
	}
}

- (IBAction) autoCheckSwitchToggled:(id)sender
{
	UISwitch *mySwitch = sender;
	[delegate setShouldAutoCheck:mySwitch.on];
}

- (IBAction) allowRotateSwitchToggled:(id)sender
{
	UISwitch *mySwitch = sender;
	((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate = mySwitch.on;
}
#pragma mark -



#pragma mark Updater Delegate
- (void) updaterDidStartAction:(EponymUpdater *)updater
{
	[updater retain];
	[self lockGUI:YES];
	[self setStatusMessage:updater.statusMessage];
	[updater release];
}

- (void) updater:(EponymUpdater *)updater didEndActionSuccessful:(BOOL)success
{
	[updater retain];
	[self lockGUI:NO];
	
	if(success) {
		// did check for updates
		if(1 == updater.updateAction) {
			[self newEponymsAreAvailable:updater.newEponymsAvailable];
			[self updateLabelsWithDateForLastCheck:[NSDate date] lastUpdate:nil usingEponyms:nil];
		}
		
		// did update eponyms
		else {
			NSString *statusMessage;
			
			if(updater.numEponymsParsed > 0) {
				statusMessage = [NSString stringWithFormat:@"Created %u eponyms", updater.numEponymsParsed];
				[self updateLabelsWithDateForLastCheck:nil lastUpdate:[NSDate date] usingEponyms:updater.eponymCreationDate];
			}
			else {
				statusMessage = @"No eponyms were created";
			}
			
			[self setStatusMessage:statusMessage];
			[self resetStatusElementsWithButtonTitle:nil];
		}
	}
	
	// an error occurred
	else {
		[self resetStatusElementsWithButtonTitle:@"Try Again"];		
		
		if(updater.downloadFailed && updater.statusMessage) {
			[self alertViewWithTitle:@"Download Failed" message:updater.statusMessage cancelTitle:@"OK"];
		}
		
		[self setStatusMessage:updater.statusMessage];
	}
	
	[updater release];
}

- (void) updater:(EponymUpdater *)updater progress:(CGFloat)progress
{
	[self setProgress:progress];
}
#pragma mark -



#pragma mark Alert View + Delegate
// alert with one button
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
	[alert show];
	[alert release];
}

// alert with 2 buttons
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
	[alert show];
	[alert release];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
	// abort import alert
	if(askingToAbortImport) {
		if(buttonIndex == alertView.firstOtherButtonIndex) {
			[delegate abortUpdateAction];
			[self dismissMe:nil];
		}
		askingToAbortImport = NO;
	}
	
	// first import alert (can only be accepted at the moment)
	else if(firstTimeLaunch) {
		[(eponyms_touchAppDelegate *)delegate loadEponymXMLFromDisk];
	}
}
#pragma mark -



#pragma mark Online Access
- (IBAction) performUpdateAction:(id)sender
{
	[delegate checkForUpdates:sender];
}

- (void) openWebsite:(NSURL *)url fromButton:(id) button
{
	if(![[UIApplication sharedApplication] openURL:url]) {
		[button setText:@"Failed"];
	}
}

- (IBAction) openProjectWebsite:(id) sender
{
	[self openWebsite:projectWebsiteURL fromButton:sender];
}

- (IBAction) openEponymsDotNet:(id) sender
{
	[self openWebsite:[NSURL URLWithString:@"http://www.eponyms.net/"] fromButton:sender];
}




@end
