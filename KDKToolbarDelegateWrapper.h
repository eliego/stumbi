//
//  KDKToolbarDelegateWrapper.h
//  Stumbi
//
//  Created by eli ego on 2008-04-02.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>

#define KDK_USER_DEFAULTS_TOOLBAR_CONF_KEY @"NSToolbar Configuration %@"
#define KDK_TOOLBAR_ITEMS_KEY @"TB Item Identifiers"

extern NSString* const KDKDelegateDidChangeNotification;
extern NSString* const KDKDelegateWillChangeNotification;
extern NSString* const KDKNoSavedConfigException;
extern int const KDKNoDefault;

@interface KDKToolbarDelegateWrapper : NSObject <NSCopying> {
	id delegate;
	NSMutableDictionary* itemsDictionary;
	NSArray* itemsArray;
	int defaultIndex;
}

- (id)initWithDelegate:(id)theDelegate items:(NSArray*)theItems;

- (void)setDelegate:(id)theDelegate;
- (id)delegate;

- (void)setItems:(NSArray*)items;
- (NSArray*)items;

- (void)setDefaultIndex:(int)theIndex;
- (int)defaultIndex;

// Delegate methods
- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;

@end


@interface KDKToolbarInjector : NSObject {
	NSString* targetIdentifier;
	KDKToolbarDelegateWrapper* wrapper;
}

- (id)initWithWrapper:(KDKToolbarDelegateWrapper*)theWrapper targetIdentifier:(NSString*)theTargetIdentifier;

- (void) injectIntoSavedConfiguration;
- (void) injectIntoSavedConfigurationAtIndex:(unsigned)theIndex;

// Notification handlers
- (void) delegateWillChange:(NSNotification*)theNotification;
- (void) delegateDidChange:(NSNotification*)theNotification;

@end


@interface NSToolbar (ToolbarNotificationExtension)

- (void) setDelegate:(id)theDelegate sendNotification:(BOOL)theSendFlag;

@end


@interface NSArray (ArrayDeepCopyExtension)

- (id) deepCopyWithZone:(NSZone*)theZone;

@end