//
//  Stumbi.h
//  Stumbi
//
//  Created by eli ego on 2008-01-31.
//  Copyright 2008 Soya Software. All rights reserved.
//

//#define STUMBI_IS_SHAREWARE

#import <Cocoa/Cocoa.h>
#import "KDKStumbleUponWrapper.h"
#import "StumbiSettingsWindowController.h"
#import "KDKToolbarDelegateWrapper.h"
#import "StumbiNewURLWindowController.h"
#import "StumbiVoteSegmentedControl.h"
#ifdef STUMBI_IS_SHAREWARE	
	#import "KDKAppManager.h"
#endif

@class BrowserDocument;
@class BrowserDocumentController;
@class BrowserToolbarItem;

extern NSString* const StumbiVoteCompletedNotification;
extern NSString* const StumbiStumbleCompletedNotification;

extern NSString* const KDKInvalidSenderException;

#define STUMBI_IDENTIFIER @"com.kungdenknege.Stumbi"
#define STUMBI_NIB_NAME @"StumbiMain"
#define STUMBI_MENU_TITLE @"Stumbi"
#define STUMBI_RECOVERY_TEXT @"Please check http://www.soyasoftware.com/?stumbi for updates"
#define STUMBI_ERROR_DOMAIN @"com.kungdenknege.Stumbi.ErrorDomain"
#define STUMBI_HOME_PAGE @"http://www.soyasoftware.com/?stumbi"
#define STUMBI_REPORT_BUG_URL @"http://www.soyasoftware.com/?bugreport"
#define STUMBI_ASK_RECIPIENT_EMAIL_TEXT "Please enter the email address of the recipient:"
#define STUMBI_STUMBLEUPON_REVIEW_BASE_URL @"http://www.stumbleupon.com/url"

#define STUMBI_USER_DEFAULTS_USER_NAME_KEY @"STUMBI_USER_DEFAULTS_USER_NAME_KEY"
#define STUMBI_USER_DEFAULTS_USER_PASSWORD_KEY @"STUMBI_USER_DEFAULTS_USER_PASSWORD_KEY"
#define STUMBI_USER_DEFAULTS_INSTALLED_KEY @"STUMBI_USER_DEFAULTS_INSTALLED_KEY"

#define STUMBI_SAFARI_TOOLBAR_KEY @"BrowserWindowToolbarIdentifier"
#define STUMBI_SAFARI_TOOLBAR_INSERT_INDEX 3

#define STUMBI_TOOLBAR_BUTTON_STUMBLE_ID @"STUMBI_TOOLBAR_BUTTON_STUMBLE_ID"
#define STUMBI_TOOLBAR_BUTTON_STUMBLE_LABEL @"Stumble"
#define STUMBI_TOOLBAR_BUTTON_STUMBLE_IMAGE @"stumbleit"
#define STUMBI_TOOLBAR_BUTTON_STUMBLE_ALT_IMAGE @"stumbleit_alt"

#define STUMBI_TOOLBAR_BUTTON_VOTE_ID @"STUMBI_TOOLBAR_BUTTON_THUMBS_UP_ID"
#define STUMBI_TOOLBAR_BUTTON_VOTE_LABEL @"Vote"


#define STUMBI_SHAREWARE_MENU_ITEM_INFO_RANGE NSMakeRange(10, 10)

@interface Stumbi : NSObject {
	IBOutlet NSMenu* stumbiMenu;
	IBOutlet NSMenuItem* sharewareMenuItem;
	IBOutlet id stumbleButton;
	IBOutlet id voteControl;
	
	NSRange sharewareMenuItemStumblesLeftRange;
	
	id appManager;
	StumbiSettingsWindowController* settingsWindowController;
	StumbiNewURLWindowController* newURLWindowController;
	KDKStumbleUponWrapper* stumbleUponWrapper;
	KDKToolbarInjector* toolbarInjector;
	BOOL firstRun;
}

// initialization
+ (void) load;
+ (Stumbi*) sharedInstance;
- (void)applicationDidFinishLaunching:(NSNotification*)theNotification;
- (void) awakeFromNib;

// Actions
- (IBAction)stumble:(id)sender;
- (IBAction)vote:(id)sender;
- (IBAction)goToHomePage:(id)sender;
- (IBAction)settings:(id)sender;
- (IBAction)sendTo:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)viewReviews:(id)sender;
- (IBAction)reportBug:(id)sender;

// Delegate method implementations
- (void)receiveNewStumble:(NSURL*)theStumbleURL;
- (void)receiveNewException:(NSException*)theException;
- (void)receiveNewVoteResponse:(KDKVoteResponse)theResponse url:(NSURL*)theUrl vote:(BOOL)theVote;

// Helpers
- (NSArray*)toolbarItems;
- (void)applicationWillTerminate:(NSNotification*)theNotification;
- (void)settingsWindowChangedNotification:(NSNotification*)theNotification;
- (void)appManagerDataUpdated:(NSNotification*)theNotification;
- (void)stumbleUponLoginFinished:(NSNotification*)theNotification;
- (void)updateSharewareMenuItem;
- (void)goToURLWrapper:(NSURL*) theURL;
- (void)displayErrorWithDescription:(NSString*)theErrorDescription recoveryText:(NSString*)theRecoveryText;
- (void)newUrl:(NSURL*)theUrl;
- (void)setProxy;
@end
