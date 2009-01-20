//
//  KDKToolbarDelegateWrapper.m
//  Stumbi
//
//  Created by eli ego on 2008-04-02.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "KDKToolbarDelegateWrapper.h"

NSString* const KDKDelegateDidChangeNotification = @"KDKDelegateDidChangeNotification";
NSString* const KDKDelegateWillChangeNotification = @"KDKDelegateWillChangeNotification";
NSString* const KDKNoSavedConfigException = @"KDKNoSavedConfigException";
const int KDKNoDefault = -1;

BOOL KDKDidSwap = NO;

@implementation KDKToolbarDelegateWrapper

- (id) init {
	self = [super init];
	if (self != nil) {
		itemsDictionary = [[NSMutableDictionary alloc] init];
		defaultIndex = KDKNoDefault;
	}
	return self;
}


- (id) initWithDelegate:(id)theDelegate items:(NSArray*)theItems{
	if ([self init]) {
		[self setDelegate:theDelegate];
		[self setItems:theItems];
	}
	
	return self;
}

- (void) dealloc {
	[itemsDictionary release];
	[itemsArray autorelease];
	[super dealloc];
}

- (id)copyWithZone:(NSZone*)theZone {
	KDKToolbarDelegateWrapper* copy = [[[self class] allocWithZone:theZone] init];
	[copy setDelegate:delegate];
	[copy setItems:[[itemsArray deepCopyWithZone:NSDefaultMallocZone()] autorelease]];
	[copy setDefaultIndex:defaultIndex];
	
	return copy;
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}

- (void)setItems:(NSArray*)theItems {
	itemsArray = [theItems retain];
		
	[itemsDictionary removeAllObjects];
	NSEnumerator* enumerator = [theItems objectEnumerator];
	
	NSToolbarItem* currentItem;
	while (currentItem = [enumerator nextObject])
		[itemsDictionary setObject:currentItem forKey:[currentItem itemIdentifier]];
}

- (NSArray*)items {
	return itemsArray;
}

- (int)defaultIndex {
	return defaultIndex;
}

- (void)setDefaultIndex:(int)theIndex {
	defaultIndex = theIndex;
}

// Delegate method implementations
- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray* allItems = [NSMutableArray arrayWithArray:[delegate toolbarAllowedItemIdentifiers:toolbar]];
	[allItems addObjectsFromArray:[itemsDictionary allKeys]];

	return allItems;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	NSToolbarItem* item;
	if (item = [itemsDictionary objectForKey:itemIdentifier]) {
		return item;
	} else
		return [delegate toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray* defaults = [NSMutableArray arrayWithArray:[delegate toolbarDefaultItemIdentifiers:toolbar]];
	
	if (defaultIndex != KDKNoDefault) {
		// Append to end if index is insane
		int currentIndex = (defaultIndex <= [defaults count] ? defaultIndex : [defaults count]);
		
		NSEnumerator* enumerator = [itemsArray objectEnumerator];
		NSString* currentIdentifier;
		while (currentIdentifier = [(NSToolbarItem*)[enumerator nextObject] itemIdentifier])
			[defaults insertObject:currentIdentifier atIndex:currentIndex++];
	}
	
	return [[defaults retain] autorelease];
}

// The rest is just to pass on messages we don't answer to..
- (void)forwardInvocation:(NSInvocation*)theInvocation
{
    if ([delegate respondsToSelector:[theInvocation selector]])
        [theInvocation invokeWithTarget:delegate];
    else
        [super forwardInvocation:theInvocation];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)theSelector {
	NSMethodSignature* signature;
	if (signature = [super methodSignatureForSelector:theSelector])
		return signature;
	else
		return [delegate methodSignatureForSelector:theSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    else if (delegate) {
		return [delegate respondsToSelector:aSelector];
    }
    return NO;
}

@end


@implementation KDKToolbarInjector

- (id)initWithWrapper:(KDKToolbarDelegateWrapper*)theWrapper targetIdentifier:(NSString*)theTargetIdentifier {
	if ([self init]) {
		wrapper = [theWrapper retain];
		targetIdentifier = [theTargetIdentifier copy];
		
		// Swizzle methods!
		if (!KDKDidSwap) {
			Method oldMethod = class_getInstanceMethod([NSToolbar class], @selector(setDelegate:));
			Method newMethod = class_getInstanceMethod([NSToolbar class], @selector(mySetDelegate:));
			
			IMP temp = oldMethod->method_imp;
			oldMethod->method_imp = newMethod->method_imp;
			newMethod->method_imp = temp;
			
			KDKDidSwap = YES;
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delegateWillChange:)
													 name:KDKDelegateWillChangeNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delegateDidChange:)
													 name:KDKDelegateDidChangeNotification
												   object:nil];
	}
	return self;
}

// MUST NOT BE DESTRUCTED BEFORE ALL TOOLBARS ARE...
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[wrapper release];
	[targetIdentifier release];
	
	[super dealloc];
}

- (void) injectIntoSavedConfiguration {
	int index = [wrapper defaultIndex];

	if (index != KDKNoDefault)
		[self injectIntoSavedConfigurationAtIndex:index];
}

- (void) injectIntoSavedConfigurationAtIndex:(unsigned)theIndex {
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* oldConf = [userDefaults objectForKey:[NSString stringWithFormat:KDK_USER_DEFAULTS_TOOLBAR_CONF_KEY, targetIdentifier]];
	NSArray* oldItems = [oldConf objectForKey:KDK_TOOLBAR_ITEMS_KEY];
		
	if (oldItems) {	
		NSMutableArray* newItems = [NSMutableArray arrayWithArray:oldItems];
		NSMutableDictionary* newConf = [NSMutableDictionary dictionaryWithDictionary:oldConf];
		
		// Add to end if index is insane
		unsigned currentIndex = (theIndex <= [oldItems count] ? theIndex : [oldItems count]);
		
		NSEnumerator* enumerator = [[wrapper items] objectEnumerator];
		NSString* currentIdentifier;
		while (currentIdentifier = [(NSToolbarItem*)[enumerator nextObject] itemIdentifier])
			if (![oldItems containsObject:currentIdentifier])
				[newItems insertObject:currentIdentifier atIndex:currentIndex++];
		
		[newConf setObject:newItems forKey:KDK_TOOLBAR_ITEMS_KEY];
		[userDefaults setObject:newConf forKey:[NSString stringWithFormat:KDK_USER_DEFAULTS_TOOLBAR_CONF_KEY, targetIdentifier]];
	} else
		[NSException raise:KDKNoSavedConfigException format:@""];
}

// NSToolbar::dealloc calls setDelegate:nil, catch this notification and free our wrapper
- (void) delegateWillChange:(NSNotification*)theNotification {
	id delegate = [[theNotification object] delegate];
	
	if ([delegate class] == [KDKToolbarDelegateWrapper class])
		[delegate autorelease];
}

- (void) delegateDidChange:(NSNotification*)theNotification {
	NSToolbar* toolbar = [theNotification object];

	if ([[toolbar identifier] isEqual:targetIdentifier]) {
		id delegate = [toolbar delegate];
	
		if (delegate) {
			KDKToolbarDelegateWrapper* wrapperCopy = [wrapper copy];
			[wrapperCopy setDelegate:delegate];
			[toolbar setDelegate:wrapperCopy sendNotification:NO];
		}
	}
}

@end


@implementation NSToolbar (ToolbarNotificationExtension)

- (void) mySetDelegate:(id)theDelegate {
	[self setDelegate:theDelegate sendNotification:YES];
}

- (void) setDelegate:(id)theDelegate sendNotification:(BOOL)theSendFlag {
	if (theSendFlag)
		[[NSNotificationCenter defaultCenter] postNotificationName:KDKDelegateWillChangeNotification object:self];
	
	[self mySetDelegate:theDelegate];
	
	if (theSendFlag)
		[[NSNotificationCenter defaultCenter] postNotificationName:KDKDelegateDidChangeNotification object:self];
}

@end


@implementation NSArray (ArrayDeepCopyExtension)

- (id) deepCopyWithZone:(NSZone*)theZone {
	NSMutableArray* copy = [[NSMutableArray allocWithZone:theZone] initWithCapacity:[self count]];
	NSEnumerator* enumerator = [self objectEnumerator];
	
	id currentObject;
	while (currentObject = [enumerator nextObject])
		[copy addObject:[[currentObject copyWithZone:theZone] autorelease]];
	
	return copy;
}

@end