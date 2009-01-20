//
//  KDKInteractiveSegmentedControl.m
//  Stumbi
//
//  Created by eli ego on 14.06.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "KDKInteractiveSegmentedControl.h"


@implementation KDKInteractiveSegmentedControl

- (void) awakeFromNib {
	alternateImages = [[NSMutableDictionary alloc] init];
	originalImages = [[NSMutableDictionary alloc] init];
	pressTimestamps = [[NSMutableDictionary alloc] init];
	minTime = 0.0;
}

- (void) dealloc {
	[alternateImages release];
	[originalImages release];
	[pressTimestamps release];
	
	[super dealloc];
}


/*
 * Change image to alternate
 */
- (BOOL) sendAction:(SEL)theAction to:(id)theTarget {
	NSImage* alternateImage;
	NSNumber* selectedSegment = [NSNumber numberWithInt:[self selectedSegment]];

	if (alternateImage = [alternateImages objectForKey:selectedSegment]) {
		// Store original image
		if ([originalImages objectForKey:selectedSegment] == nil) {
			NSImage* oldImage = [self imageForSegment:[self selectedSegment]];
			[originalImages setObject:oldImage forKey:selectedSegment];
		}

		[self setImage:alternateImage forSegment:[self selectedSegment]];
	}
	
	[pressTimestamps setObject:[NSDate date] forKey:selectedSegment];

	return [super sendAction:theAction to:theTarget];
}

- (void) resetSegmentWrapper:(NSNumber*)theSegment {
	[self resetSegment:[theSegment intValue]];
}

- (void) resetSegment:(int)theSegment {
	NSImage* originalImage;
	NSNumber* segmentNumber = [NSNumber numberWithInt:theSegment];
	
	if (originalImage = [originalImages objectForKey:segmentNumber]) {
		NSTimeInterval timeSincePress = -[(NSDate*)[pressTimestamps objectForKey:segmentNumber] timeIntervalSinceNow];
		
		if (timeSincePress < minTime) {
			[self performSelector:@selector(resetSegmentWrapper:) withObject:segmentNumber afterDelay:(minTime - timeSincePress)];
		} else {
			[self setImage:originalImage forSegment:theSegment];
		}
	}
}

- (void) setAlternateImage:(NSImage*)theImage forSegment:(int)theSegment {
	NSNumber* segmentNumber = [NSNumber numberWithInt:theSegment];
	[alternateImages setObject:theImage forKey:segmentNumber];
}
	
- (void) encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:alternateImages forKey:@"StumbiAlternateImages"];
		[coder encodeObject:originalImages forKey:@"StumbiOriginalImages"];
		[coder encodeObject:pressTimestamps forKey:@"StumbiTimestamps"];
		[coder encodeDouble:minTime forKey:@"StumbiMinTime"];
    } else {
        [coder encodeObject:alternateImages];
		[coder encodeObject:originalImages];
		[coder encodeObject:pressTimestamps];
		[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&minTime];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        alternateImages = [[coder decodeObjectForKey:@"StumbiAlternateImages"] retain];
		originalImages = [[coder decodeObjectForKey:@"StumbiOriginalImages"] retain];
		pressTimestamps = [[coder decodeObjectForKey:@"StumbiTimestamps"] retain];
		minTime = [coder decodeDoubleForKey:@"StumbiMinTime"];
    } else {
        alternateImages = [[coder decodeObject] retain];
		originalImages = [[coder decodeObject] retain];
		pressTimestamps = [[coder decodeObject] retain];
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&minTime];
    }
    return self;
}

- (NSTimeInterval)minTime {
	return minTime;
}

- (void)setMinTime:(NSTimeInterval)theMinTime {
	minTime = theMinTime;
}

@end
