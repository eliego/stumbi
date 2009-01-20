//
//  StumbiVoteSegmentedControl.m
//  Stumbi
//
//  Created by eli ego on 15.06.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "StumbiVoteSegmentedControl.h"


@implementation StumbiVoteSegmentedControl

- (void) awakeFromNib {
	[super awakeFromNib];
	
	[self setLabel:nil forSegment:0];
	[self setLabel:nil forSegment:1];

	[self setImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_THUMBS_UP_IMAGE]] autorelease] forSegment:0];
	[self setAlternateImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_THUMBS_UP_ALT_IMAGE]] autorelease] forSegment:0];

	[self setImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_THUMBS_DOWN_IMAGE]] autorelease] forSegment:1];
	[self setAlternateImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:STUMBI_TOOLBAR_BUTTON_THUMBS_DOWN_ALT_IMAGE]] autorelease] forSegment:1];

	[self setMinTime:0.7];
}

- (BOOL) selectedVote {
	return !(BOOL)[self selectedSegment];
}

/* Add observer */
- (BOOL) sendAction:(SEL)theAction to:(id)theTarget {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voteCompleted:)
												 name:StumbiVoteCompletedNotification object:theTarget];
	
	return [super sendAction:(SEL)theAction to:theTarget];
}

- (void) voteCompleted:(NSNotification*)theNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:StumbiVoteCompletedNotification object:[theNotification object]];
	
	[self resetSegment:0];
	[self resetSegment:1];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


@end
