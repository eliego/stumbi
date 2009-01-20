//
//  KDKInteractiveSegmentedControl.h
//  Stumbi
//
//  Created by eli ego on 14.06.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 * This is basically only usable for "buttonlike" SegmentedControls
 * Changes image on click
 * Changes back on call of resetSegment, though it always waits at least minTime seconds
 */
@interface KDKInteractiveSegmentedControl : NSSegmentedControl {
	NSMutableDictionary* alternateImages;
	NSMutableDictionary* originalImages;
	NSMutableDictionary* pressTimestamps;
	NSTimeInterval minTime;
}

- (void) awakeFromNib;
- (void) resetSegment:(int)theSegment;
- (void) setAlternateImage:(NSImage*)theImage forSegment:(int)theSegment;

- (NSTimeInterval)minTime;
- (void)setMinTime:(NSTimeInterval)theMinTime;

@end
