//
//  KDKStumbleUponLog.m
//  Stumbi
//
//  Created by eli ego on 2008-04-03.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "KDKStumble.h"


@implementation KDKStumble

- (long)urlId {
	return urlId;
}

- (void)setUrlId:(long)theUrlId {
	urlId = theUrlId;
}

- (long)timestamp {
	return timestamp;
}

- (void)setTimestamp:(long)theTimestamp {
	timestamp = theTimestamp;
}

- (int)type {
	return type;
}

- (void)setType:(int)theType {
	type = theType;
}

- (long)referral {
	return referral;
}

- (void)setReferral:(long)theReferral {
	referral = theReferral;
}

- (NSURL*)url {
	return [[url copy] autorelease];
}

- (void)setUrl:(NSURL*)theUrl {
	url = [theUrl copy];
}

- (void) dealloc {
	[url release];
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
		[coder encodeInt64:referral forKey:@"KDKStumbleReferralId"];
        [coder encodeInt64:urlId forKey:@"KDKStumbleUrlId"];
        [coder encodeInt64:timestamp forKey:@"KDKStumbleTimestamp"];
        [coder encodeInt:type forKey:@"KDKStumbleType"];
        [coder encodeObject:url forKey:@"KDKStumbleUrl"];
    } else {
		[coder encodeValueOfObjCType:@encode(long) at:&referral];
        [coder encodeValueOfObjCType:@encode(long) at:&urlId];
        [coder encodeValueOfObjCType:@encode(long) at:&timestamp];
        [coder encodeValueOfObjCType:@encode(int) at:&type];
        [coder encodeObject:url];
		
    }
}

- (NSString*)description {
	return [url description];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if ( [coder allowsKeyedCoding] ) {
		referral = [coder decodeInt64ForKey:@"KDKStumbleReferralId"];
        urlId = [coder decodeInt64ForKey:@"KDKStumbleUrlId"];
		timestamp = [coder decodeInt64ForKey:@"KDKStumbleTimestamp"];
		type = [coder decodeIntForKey:@"KDKStumbleType"];
		url = [[coder decodeObjectForKey:@"KDKStumbleUrl"] retain];
    } else {
		[coder decodeValueOfObjCType:@encode(long) at:&referral];
        [coder decodeValueOfObjCType:@encode(long) at:&urlId];
		[coder decodeValueOfObjCType:@encode(long) at:&timestamp];
		[coder decodeValueOfObjCType:@encode(int) at:&type];
		url = [[coder decodeObject] retain];
    }
    return self;
}

@end
