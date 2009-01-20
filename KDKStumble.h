//
//  KDKStumbleUponLog.h
//  Stumbi
//
//  Created by eli ego on 2008-04-03.
//  Copyright 2008 Soya Software. All rights reserved.
// 

#import <Cocoa/Cocoa.h>


@interface KDKStumble : NSObject <NSCoding> {
	NSURL* url;
	long urlId;
	long timestamp;
	long referral;
	int type;
}

- (long)urlId;
- (void)setUrlId:(long)theUrlId;

- (long)timestamp;
- (void)setTimestamp:(long)theTimestamp;

- (int)type;
- (void)setType:(int)theType;

- (long)referral;
- (void)setReferral:(long)theReferral;

- (NSURL*)url;
- (void)setUrl:(NSURL*)theUrl;

@end