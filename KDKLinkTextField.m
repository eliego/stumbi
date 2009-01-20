//
//  KDKLinkTextField.m
//  Stumbi
//
//  Created by eli ego on 05.09.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "KDKLinkTextField.h"


@implementation KDKLinkTextField

- (id) init {
	self = [super init];
	if (self != nil) {
		href = [[NSString string] retain];
	}
	return self;
}

- (void) dealloc {
	[href release];
	[super dealloc];
}

- (NSURL*)href {
	return href;
}

- (void)setHref: (NSURL*)theHref {
	[href autorelease];
	href = [theHref retain];
}

- (void)awakeFromNib {
	NSAttributedString* oldValue = [self attributedStringValue];
	
	NSMutableAttributedString* newValue = [oldValue mutableCopy];
	NSRange entireRange = NSMakeRange(0,[newValue length]);
	[newValue addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:entireRange];
	[newValue addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:entireRange];
	
	[self setAttributedStringValue:newValue];
	[self setTarget:self];
	[self setAction:@selector(launchHrefFrom:)];
	
	NSURL* valueURL;
	if (valueURL =[NSURL URLWithString:[newValue string]])
		[self setHref:valueURL];
}

- (void)launchHrefFrom: (id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[self href]];
}

- (void)mouseDown: (NSEvent*)theEvent {
	[self sendAction:[self action] to:[self target]];
}

- (void)resetCursorRects {	
    [self addCursorRect:[self visibleRect] cursor:[NSCursor pointingHandCursor]];
}

@end
