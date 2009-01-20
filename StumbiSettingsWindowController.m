//
//  StumbiSettingsWindowController.m
//  Stumbi
//
//  Created by eli ego on 2008-02-18.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "StumbiSettingsWindowController.h"

NSString* const StumbiSettingsWindowChangedNotification = @"StumbiSettingsWindowChangedNotification";

@implementation StumbiSettingsWindowController

- (id) init {
	self = [super init];
	if (self != nil) {
		[super initWithWindowNibName:STUMBI_SETTINGS_WINDOW_NIB_NAME];
		[self window]; // to load window so that setters and getters work
		
		// Set href in links
		[forgotAccountLink setHref:[NSURL URLWithString:STUMBI_FORGOT_ACCOUNT_LINK]];
		[createAccountLink setHref:[NSURL URLWithString:STUMBI_CREATE_ACCOUNT_LINK]];
	}
	return self;
}

- (IBAction)close:(id)theSender {
	[[self window] close];
	[[NSNotificationCenter defaultCenter] postNotificationName:StumbiSettingsWindowChangedNotification object:self];
}

- (void)setUserName: (NSString*)theUserName {
	if (theUserName != nil)
		[userNameField setStringValue:theUserName];
}

- (NSString*)userName {
	return [userNameField stringValue];
}

- (void)setUserPassword: (NSString*)theUserPassword {
	if (theUserPassword != nil)
		[userPasswordField setStringValue:theUserPassword];
}

- (NSString*)userPassword {
	return [userPasswordField stringValue];
}

@end
