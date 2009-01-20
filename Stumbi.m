//
//  Stumbi.m
//  Stumbi
//
//  Created by eli ego on 2008-01-31.
//  Copyright 2008 Soya Software. All rights reserved.
//

// TODO: kolla när vänner tipsat om URL

#import "Stumbi.h"
#import "Connection/Connection.h"
#include <SystemConfiguration/SystemConfiguration.h>

NSString* const StumbiVoteCompletedNotification = @"StumbiVoteCompletedNotification";
NSString* const StumbiStumbleCompletedNotification = @"StumbiStumbleCompletedNotification";

NSString* const KDKInvalidSenderException = @"KDKInvalidSenderException";

@implementation Stumbi

/****** INITIALIZATION *************/

+ (void) load
{	// Hey ho, let's go!
	[Stumbi sharedInstance];
}

+ (Stumbi*) sharedInstance {
	static Stumbi* sharedInstance;
	
	if ( sharedInstance == nil ) {
		sharedInstance = [[Stumbi alloc] init];
	}
	return sharedInstance;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
		if ([userDefaults boolForKey:STUMBI_USER_DEFAULTS_INSTALLED_KEY]) {
			firstRun = NO;
		} else {
			firstRun = YES;
			[userDefaults setBool:YES forKey:STUMBI_USER_DEFAULTS_INSTALLED_KEY];
		}
			
		[NSBundle loadNibNamed:STUMBI_NIB_NAME owner:self];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:)
													 name:NSApplicationDidFinishLaunchingNotification
												   object:[NSApplication sharedApplication]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
													 name:NSApplicationWillTerminateNotification
												   object:[NSApplication sharedApplication]];
	}

	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification*)theNotification {
	stumbleUponWrapper = [[KDKStumbleUponWrapper alloc] init];
	[stumbleUponWrapper setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stumbleUponLoginFinished:)
												 name:KDKStumbleUponLoginFinishedNotification
											   object:stumbleUponWrapper];
	
	newURLWindowController = [[StumbiNewURLWindowController alloc] init];
	
#ifdef STUMBI_IS_SHAREWARE	
	appManager = [[KDKAppManager alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appManagerDataUpdated:)
											   name:KDKAppManagerDataUpdatedNotification
											   object:appManager];
#endif
	
	// Load config from user defaults, update wrapper
	NSString* savedUserName = nil;
	NSString* savedUserPassword = nil;
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ( (savedUserName = [userDefaults stringForKey:STUMBI_USER_DEFAULTS_USER_NAME_KEY]) &&
		 (savedUserPassword = [userDefaults stringForKey:STUMBI_USER_DEFAULTS_USER_PASSWORD_KEY]) ) {
		[stumbleUponWrapper login:savedUserName withUserPassword:savedUserPassword];
	}
	
	if (firstRun && !savedUserName && !savedUserPassword) {
		[self settings:self];
	}
}

- (void) awakeFromNib
{	
	// Insert menu
	[stumbiMenu setTitle:STUMBI_MENU_TITLE];
	NSMenuItem* containerMenuItem = [[NSMenuItem alloc] initWithTitle: STUMBI_MENU_TITLE action: NULL keyEquivalent:@""];
	[containerMenuItem setSubmenu: stumbiMenu];
	
	[[[NSApplication sharedApplication] mainMenu] addItem: containerMenuItem];
	
	// Inject toolbar
	KDKToolbarDelegateWrapper* wrapper = [[[KDKToolbarDelegateWrapper alloc] init] autorelease];
	[wrapper setItems:[self toolbarItems]];
	[wrapper setDefaultIndex:STUMBI_SAFARI_TOOLBAR_INSERT_INDEX];
	toolbarInjector = [[KDKToolbarInjector alloc] initWithWrapper:wrapper
												 targetIdentifier:STUMBI_SAFARI_TOOLBAR_KEY];
	
	if (firstRun) {
		@try {
			[toolbarInjector injectIntoSavedConfiguration];
		} @catch (NSException* e) {
			; // Doesn't matter, since we're in the defaults as well..
		}
	}
}


/*************** ACTIONS *******************/

- (IBAction)stumble:(id)sender {
#ifdef STUMBI_IS_SHAREWARE
	if ([appManager tryMainActionExecution]) {
#endif
		[stumbleUponWrapper requestNewStumble];
		[self updateSharewareMenuItem];
#ifdef STUMBI_IS_SHAREWARE
	}
#endif		
}

- (IBAction)vote:(id)sender {
	BrowserDocument* activeBrowserDocument = [[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument];
	NSURL* url = [activeBrowserDocument currentURL];
	if (url) {
		BOOL vote;
		if ([sender isKindOfClass:[StumbiVoteSegmentedControl class]])
			vote = [sender selectedVote];
		else if ([sender isKindOfClass:[NSMenuItem class]])
			vote = (BOOL)[sender tag];
		else
			[NSException raise:KDKInvalidSenderException format:@"Stumbi::Vote was targeted by an invalid sender"];
		
		[stumbleUponWrapper vote:vote forURL:url];
	}
}

- (IBAction)goToHomePage:(id)sender {
	[self goToURLWrapper:[NSURL URLWithString:STUMBI_HOME_PAGE]];
}

- (IBAction)settings:(id)sender {
	if (settingsWindowController == nil) {
		settingsWindowController = [[StumbiSettingsWindowController alloc] init];
		[settingsWindowController setUserName:[stumbleUponWrapper userName]];
		[settingsWindowController setUserPassword:[stumbleUponWrapper userPassword]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsWindowChangedNotification:) name:StumbiSettingsWindowChangedNotification object:settingsWindowController];
	}
	
	[settingsWindowController showWindow:self];
}

- (IBAction)sendTo:(id)sender { // So, yeah, why not get even uglier!? Let WebKit run a JavaScript for us!
	BrowserDocument* browserDocument = [[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument];
	NSString* js = [NSString stringWithFormat:@"prompt('%s', '')", STUMBI_ASK_RECIPIENT_EMAIL_TEXT];
	NSString* receiversEmail = [[[browserDocument currentWebView] windowScriptObject] evaluateWebScript:js];
	
	if (receiversEmail == nil)
		return;
	
	// Validate e-mail!! this is an ocean of ugliness
	NSPredicate *regEx = [NSPredicate
                         predicateWithFormat:@"SELF MATCHES %@", @"^(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4})$"];
	
	if (![regEx evaluateWithObject:receiversEmail]) {
		[self displayErrorWithDescription:@"Incorrectly formatted e-mail address" recoveryText:@"Please try again"];
		return;
	}
	
	[stumbleUponWrapper sendUrl:[browserDocument currentURL] toEmail:receiversEmail];
}

- (IBAction)purchase:(id)sender {
	[appManager purchase];
}

- (IBAction)viewReviews:(id)sender {
	NSURL* currentURL = [[[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument] currentURL];
	NSString* urlString = [[currentURL description] substringFromIndex:[[currentURL scheme] length] + 3];
	NSURL* reviewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", STUMBI_STUMBLEUPON_REVIEW_BASE_URL, urlString]];
	
	[self goToURLWrapper:reviewURL];
}

- (IBAction)reportBug:(id)sender {
	[self goToURLWrapper:[NSURL URLWithString:STUMBI_REPORT_BUG_URL]];
}


/******************** DELEGATE IMPLEMENTATIONS *********************/

- (void)receiveNewStumble:(NSURL*)theStumbleURL {
	[[NSNotificationCenter defaultCenter] postNotificationName:StumbiStumbleCompletedNotification object:self];
	[self goToURLWrapper:theStumbleURL];
}

- (void) receiveNewException:(NSException*)theException {
	BOOL severe = [(NSString*)[[theException userInfo] objectForKey:KDKErrorSeverity] isEqualToString:KDKErrorSeverityHigh];
	
	if (!([[theException name] isEqualToString:KDKAuthenticationException] && [[(NSDictionary*)[theException userInfo] objectForKey:KDKErrorCameFromRequestType] intValue] == userInfoRequest))
		[self displayErrorWithDescription:[theException reason] recoveryText:(severe ? STUMBI_RECOVERY_TEXT : @"")];
}

- (void) receiveNewVoteResponse:(KDKVoteResponse)theResponse url:(NSURL*)theUrl vote:(BOOL)theVote {
	if (theResponse == unknownURL) {
		if (theVote == YES) {
			[self newUrl:theUrl];
		} else {
			[self displayErrorWithDescription:@"StumbleUpon doesn't know about that URL yet!"
								 recoveryText:@"You can add it by voting thumbs up"];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:StumbiVoteCompletedNotification object:self];
}


/********************** HELPERS ********************************/

- (NSArray*)toolbarItems {
	NSSize buttonSize = NSMakeSize(28, 25); // Hardcoded, ugly, but inevitable.
	NSSize twoButtonSize = NSMakeSize(52, 25);
	
	NSToolbarItem* stumbleItem = [[[BrowserToolbarItem alloc] initWithItemIdentifier:STUMBI_TOOLBAR_BUTTON_STUMBLE_ID] autorelease];
	[stumbleButton setLabel:nil forSegment:0];
	[stumbleItem setLabel:STUMBI_TOOLBAR_BUTTON_STUMBLE_LABEL];
	[stumbleItem setPaletteLabel:STUMBI_TOOLBAR_BUTTON_STUMBLE_LABEL];
	[stumbleItem setToolTip:STUMBI_TOOLBAR_BUTTON_STUMBLE_LABEL];
	[stumbleItem setView:stumbleButton];
	[stumbleItem setMinSize:buttonSize];
	[stumbleItem setMaxSize:buttonSize];
	
	NSToolbarItem* voteItem = [[[BrowserToolbarItem alloc] initWithItemIdentifier: STUMBI_TOOLBAR_BUTTON_VOTE_ID] autorelease];
	[voteItem setLabel:STUMBI_TOOLBAR_BUTTON_VOTE_LABEL];
	[voteItem setPaletteLabel:STUMBI_TOOLBAR_BUTTON_VOTE_LABEL];
	[voteItem setToolTip:STUMBI_TOOLBAR_BUTTON_VOTE_LABEL];
	[voteItem setView:voteControl];
	[voteItem setMinSize:twoButtonSize];
	[voteItem setMaxSize:twoButtonSize];
	
	NSMutableArray* items = [[NSMutableArray alloc] initWithCapacity:3];
	[items addObject:stumbleItem];
	[items addObject:voteItem];
	
	return [items autorelease];
}

- (void)applicationWillTerminate:(NSNotification*)theNotification {
	[stumbleUponWrapper close];
}

- (void)appManagerDataUpdated:(NSNotification*)theNotification {
#ifdef STUMBI_IS_SHAREWARE
	// Are we in shareware mode?
	if ([appManager license] == noLicense) {
		// Init menuitem title
		NSMutableAttributedString* title = [[[NSMutableAttributedString alloc] initWithString:[sharewareMenuItem title]] autorelease];
		NSRange entireTitle = NSMakeRange(0, [title length]);
		
		[title addAttribute:NSFontAttributeName
					  value:[NSFont menuFontOfSize:15]
					  range:entireTitle];
		
		[title addAttribute:NSForegroundColorAttributeName
					  value:[NSColor grayColor]
					  range:STUMBI_SHAREWARE_MENU_ITEM_INFO_RANGE];

		[title addAttribute:NSFontAttributeName
					  value:[NSFont menuFontOfSize:13]
					  range:STUMBI_SHAREWARE_MENU_ITEM_INFO_RANGE];
		
			
		[sharewareMenuItem setAttributedTitle:title];
		
		// Init stumbles left range
		sharewareMenuItemStumblesLeftRange = NSMakeRange(11,3);
		
		// Update menu item
		[self updateSharewareMenuItem];
		
		// Remove from bogus menu
		[sharewareMenuItem retain];
		[[sharewareMenuItem menu] removeItem:sharewareMenuItem];
		
		// Add to menu
		[stumbiMenu addItem:sharewareMenuItem];
	}
 #endif
}

- (void)stumbleUponLoginFinished:(NSNotification*)theNotification {
	[newURLWindowController goToUrl:[stumbleUponWrapper loginURL]];
}

- (void)updateSharewareMenuItem {
#ifdef STUMBI_IS_SHAREWARE
	NSMutableAttributedString* title = [[[sharewareMenuItem attributedTitle] mutableCopy] autorelease];
	NSString* stumblesLeft = [NSString stringWithFormat:@"%d", [appManager mainExecutionsLeft]];
	
	[title replaceCharactersInRange:sharewareMenuItemStumblesLeftRange withString:stumblesLeft];
	
	[sharewareMenuItem setAttributedTitle:title];
	
	sharewareMenuItemStumblesLeftRange.length = [stumblesLeft length];
#endif
}

- (void) dealloc {
	[stumbleUponWrapper release];
	[newURLWindowController release];
	[settingsWindowController release];
	[appManager release];
	[toolbarInjector release];
	[sharewareMenuItem release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)settingsWindowChangedNotification:(NSNotification*)theNotification {
	[stumbleUponWrapper login:[settingsWindowController userName]
			 withUserPassword:[settingsWindowController userPassword]];
	
	// Save to user defaults
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[settingsWindowController userName] forKey:STUMBI_USER_DEFAULTS_USER_NAME_KEY];
	[userDefaults setObject:[settingsWindowController userPassword] forKey:STUMBI_USER_DEFAULTS_USER_PASSWORD_KEY];
}

- (void)goToURLWrapper:(NSURL*) theURL {
	[[[NSApplication sharedApplication] mainWindow] makeKeyAndOrderFront:self];
	BrowserDocument* activeBrowserDocument = [[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument];
	[activeBrowserDocument goToURL:theURL];
}

- (void) displayErrorWithDescription:(NSString*)theErrorDescription recoveryText:(NSString*)theRecoveryText {
	NSMutableDictionary* userInfoDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
	[userInfoDictionary setObject:theErrorDescription forKey:NSLocalizedDescriptionKey];
	[userInfoDictionary setObject:theRecoveryText forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	NSError* error = [NSError errorWithDomain:STUMBI_ERROR_DOMAIN code:0 userInfo:userInfoDictionary];
	BrowserDocument* activeBrowserDocument = [[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument];
	[activeBrowserDocument presentError:error];
}

- (void)newUrl:(NSURL*)theUrl {
	NSString* title;
	BrowserDocument* activeBrowserDocument = [[BrowserDocumentController sharedDocumentController] frontmostBrowserDocument];
	
	if ([activeBrowserDocument currentURL] == theUrl)
		title = [activeBrowserDocument pageName];
	else
		title = @"";
		
	[newURLWindowController showWindowToPostNewUrl:theUrl withTitle:title];
}

- (void) setProxy {
	// Connect with System Preferences
	SCDynamicStoreRef sSCDSRef = SCDynamicStoreCreate(NULL,(CFStringRef)STUMBI_IDENTIFIER,NULL, NULL);
	
	// Get system proxies
	NSDictionary* proxies = (NSDictionary*)SCDynamicStoreCopyProxies(sSCDSRef);
	
	// HTTP proxy activated?
	if ([[proxies objectForKey:(NSString*)kSCPropNetProxiesHTTPEnable] boolValue]) {
		[stumbleUponWrapper setProxyHost:[proxies objectForKey:(NSString*)kSCPropNetProxiesHTTPProxy]
									port:[(NSNumber*)[proxies objectForKey:(NSString*)kSCPropNetProxiesHTTPPort] intValue]];
	}
}

@end