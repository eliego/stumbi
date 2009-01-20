//
//  URLExtension.m
//  Stumbi
//
//  Created by eli ego on 31.05.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "URLExtension.h"


@implementation NSURL (URLEscapedStringExtension)

- (NSString*) escapedString {
	NSString* url = [self description];

	if (!url)
		return [NSString string];
	
	NSString* escapedUrl = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url,
																			 NULL, (CFStringRef)@";/?:@&=+$",
																			 kCFStringEncodingUTF8);
	return [escapedUrl autorelease];
}

@end