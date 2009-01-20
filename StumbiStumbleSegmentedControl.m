//
//  StumbiVoteSegmentedControl.m
//  Stumbi
//
//  Created by eli ego on 15.06.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "StumbiStumbleSegmentedControl.h"


@implementation StumbiStumbleSegmentedControl

- (void) awakeFromNib {
	[super awakeFromNib];
	[self setImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_STUMBLE_IMAGE]] autorelease] forSegment:0];
	[self setAlternateImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_STUMBLE_ALT_IMAGE]] autorelease] forSegment:0];
	[self setMinTime:0.7];
}

/* Add observer */
- (BOOL) sendAction:(SEL)theAction to:(id)theTarget {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stumbleCompleted:)
												 name:StumbiStumbleCompletedNotification object:theTarget];
	
	return [super sendAction:(SEL)theAction to:theTarget];
}

- (void) stumbleCompleted:(NSNotification*)theNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:StumbiStumbleCompletedNotification object:[theNotification object]];
	
	[self resetSegment:0];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


@end
