//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller for the info screen for eponyms-touch
//  


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>


@class EponymUpdater;


@interface InfoViewController : UIViewController <UIAlertViewDelegate> {
	id delegate;
	
	EponymUpdater *myUpdater;
	BOOL needToReloadEponyms;
	BOOL firstTimeLaunch;
	BOOL newEponymsAvailable;
	BOOL iAmUpdating;
	BOOL askingToAbortImport;
	
	NSInteger lastEponymCheck;
	NSInteger lastEponymUpdate;
	NSInteger usingEponymsOf;
	NSUInteger readyToLoadNumEponyms;
	
	IBOutlet UIView *topContainer;
	IBOutlet UIView *bottomContainer;
	
	IBOutlet UILabel *versionLabel;
	IBOutlet UILabel *usingEponymsLabel;
	IBOutlet UILabel *lastCheckLabel;
	IBOutlet UILabel *lastUpdateLabel;
	IBOutlet UITextView *infoTextView;
	
	IBOutlet UIButton *updateButton;
	IBOutlet UIButton *projectWebsiteButton;
	IBOutlet UIButton *eponymsDotNetButton;
	
	IBOutlet UILabel *progressText;
	IBOutlet UIProgressView *progressView;
	
	NSDictionary *infoPlistDict;
	NSURL *projectWebsiteURL;
	NSURL *eponymUpdateCheckURL;
	NSURL *eponymXMLURL;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL needToReloadEponyms;
@property (nonatomic, assign) BOOL firstTimeLaunch;
@property (nonatomic, assign) BOOL newEponymsAvailable;
@property (nonatomic, assign) BOOL iAmUpdating;

@property (nonatomic, retain) EponymUpdater *myUpdater;
@property (nonatomic, assign) NSInteger lastEponymCheck;
@property (nonatomic, assign) NSInteger lastEponymUpdate;
@property (nonatomic, assign) NSInteger usingEponymsOf;
@property (nonatomic, assign) NSUInteger readyToLoadNumEponyms;

@property (nonatomic, readonly) UILabel *progressText;
@property (nonatomic, readonly) UIProgressView *progressView;
@property (nonatomic, readonly) UIButton *updateButton;

@property (nonatomic, retain) NSDictionary *infoPlistDict;
@property (nonatomic, retain) NSURL *projectWebsiteURL;
@property (nonatomic, retain) NSURL *eponymUpdateCheckURL;
@property (nonatomic, retain) NSURL *eponymXMLURL;

- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms;
- (void) dismissMe:(id)sender;
- (void) abortUpdateAction;

- (void) setUpdateButtonTitle:(NSString *)title;
- (void) setUpdateButtonTitleColor:(UIColor *)color;
- (void) setStatusMessage:(NSString *)message;
- (void) setProgress:(CGFloat) progress;

// Online Access
- (IBAction) performUpdateAction:(id)sender;
- (IBAction) openProjectWebsite:(id)sender;
- (IBAction) openEponymsDotNet:(id)sender;

- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle;

@end