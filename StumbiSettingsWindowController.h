//
//  StumbiSettingsWindowController.h
//  Stumbi
//
//  Created by eli ego on 2008-02-18.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KDKLinkTextField.h"

// Sent to observers when window resigns key
extern NSString* const StumbiSettingsWindowChangedNotification;
					   
#define STUMBI_SETTINGS_WINDOW_NIB_NAME @"SettingsWindow"

#define STUMBI_CREATE_ACCOUNT_LINK @"http://www.stumbleupon.com/sign_up.php"
#define STUMBI_FORGOT_ACCOUNT_LINK @"http://www.stumbleupon.com/recover_password.php"

@interface StumbiSettingsWindowController : NSWindowController {
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* userPasswordField;
	IBOutlet KDKLinkTextField* forgotAccountLink;
	IBOutlet KDKLinkTextField* createAccountLink;
}


- (void)setUserName: (NSString*)theUserName;
- (NSString*)userName;

- (void)setUserPassword: (NSString*)theUserPassword;
- (NSString*)userPassword;

- (IBAction)close:(id)theSender;

@end
