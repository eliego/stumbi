//
//  CKHTTPResponseKDKCookieFix.m
//  Stumbi
//
//  Created by eli ego on 20.09.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "CKHTTPResponseKDKCookieFix.h"


@implementation CKHTTPResponse (CKHTTPResponseKDKCookieFix)

- (NSArray*)cookies {
	// This is really ugly, but the best I can do, as the actual host is set in CKHTTPConnection which I have no reference to..
	NSString* fakeURL = [NSString stringWithFormat:@"http://%@%@", [[[self request] headers] objectForKey:@"Host"], [[self request] uri]];
	return [NSHTTPCookie cookiesWithResponseHeaderFields:[self headers] forURL:[NSURL URLWithString:fakeURL]];
}

/** Instead of only storing one cookie as an Array, we concatenate all cookies to a comma-separated string.
 *  This is mostly to imititate the behaviour of NSHTTPURLResponse */
- (id)initWithRequest:(CKHTTPRequest *)request data:(NSData *)data
{
	if (self = [super init])
	{
		myRequest = [request retain];
		if (!data || [data length] == 0)
		{
			return self;
		}
		NSRange headerRange = [data rangeOfData:[[NSString stringWithString:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		NSString *headerString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0,headerRange.location)] encoding:NSUTF8StringEncoding] autorelease];
		NSArray *headerLines = [headerString componentsSeparatedByString:@"\r\n"];
		
		NSArray *response = [[headerLines objectAtIndex:0] componentsSeparatedByString:@" "]; // HTTP/1.1 CODE NAME
		myResponseCode = [[response objectAtIndex:1] intValue];
		
		if ([response count] >= 3)
		{
			NSString *msg = [[response subarrayWithRange:NSMakeRange(2, [response count] - 2)] componentsJoinedByString:@" "];
			myResponse = [msg copy];
		}
		
		// now enumerate over the headers which will be if the line is empty
		int i, lineCount = [headerLines count];
		for (i = 1; i < lineCount; i++)
		{
			NSString *line = [headerLines objectAtIndex:i];
			if ([line isEqualToString:@""])
			{
				//we hit the end of the headers
				break;
			}
			NSRange colon = [line rangeOfString:@":"];
			if (colon.location != NSNotFound)
			{
				NSString *key = [line substringToIndex:colon.location];
				NSString *val = [line substringFromIndex:colon.location + colon.length + 1];
				NSString* oldVal = [myHeaders objectForKey:key];
				
				if (oldVal != nil) {
					val = [NSString stringWithFormat:@"%@,%@", oldVal, val];
				}
				
				[myHeaders setObject:val forKey:key];
			}
		}
		BOOL isChunkedTransfer = NO;
		if ([myHeaders objectForKey:@"Transfer-Encoding"])
		{
			if ([[[myHeaders objectForKey:@"Transfer-Encoding"] lowercaseString] isEqualToString:@"chunked"])
			{
				isChunkedTransfer = YES;
			}
		}
		// now get the data range for the content
		unsigned start = NSMaxRange(headerRange);
		
		if (!isChunkedTransfer)
		{
			unsigned contentLength = [[myHeaders objectForKey:@"Content-Length"] intValue];
			if (contentLength > 0)
			{
				[self setContent:[data subdataWithRange:NSMakeRange(start, contentLength)]];
			}
			else
			{
				[self setContent:[data subdataWithRange:NSMakeRange(start, [data length] - start)]];
			}
		}
		else
		{
			NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
			NSRange lengthRange = [data rangeOfData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]
											  range:NSMakeRange(start, [data length] - start)];
			NSString *lengthString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(lengthRange.location - 4, 4)] encoding:NSUTF8StringEncoding] autorelease];
			NSScanner *scanner = [NSScanner scannerWithString:lengthString];
			unsigned chunkLength = 0;
			[scanner scanUpToCharactersFromSet:hexSet intoString:nil];
			[scanner scanHexInt:&chunkLength];
			
			while (chunkLength > 0)
			{
				[self appendContent:[data subdataWithRange:NSMakeRange(NSMaxRange(lengthRange), chunkLength)]];
				
				lengthRange = [data rangeOfData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]
										  range:NSMakeRange(NSMaxRange(lengthRange) + chunkLength + 2, [data length] - NSMaxRange(lengthRange) - chunkLength - 2)];
				lengthString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(lengthRange.location - 4, 4)] encoding:NSUTF8StringEncoding] autorelease];
				scanner = [NSScanner scannerWithString:lengthString];
				[scanner scanUpToCharactersFromSet:hexSet intoString:nil];
				[scanner scanHexInt:&chunkLength];
			}
		}	
	}
	return self;
}

+ (NSRange)canConstructResponseWithData:(NSData *)data
{
	NSRange packetRange = NSMakeRange(NSNotFound, 0);
	NSRange headerRange = [data rangeOfData:[[NSString stringWithString:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (headerRange.location == NSNotFound)
	{
		return packetRange;
	}
	
	NSString *headerString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0,headerRange.location)] encoding:NSUTF8StringEncoding] autorelease];
	NSArray *headerLines = [headerString componentsSeparatedByString:@"\r\n"];
	NSMutableDictionary *headers = [NSMutableDictionary dictionary];
	
	// we put in a try/catch to handle any unexpected/missing data
	@try {
		NSArray *response = [[headerLines objectAtIndex:0] componentsSeparatedByString:@" "];
		// HTTP/1.1 CODE NAME
		if ([[[response objectAtIndex:0] uppercaseString] isEqualToString:@"HTTP/1.1"])
		{
			//int responseCode = [[response objectAtIndex:1] intValue];
			
			if ([response count] >= 3)
			{
				//NSString *msg = [[response subarrayWithRange:NSMakeRange(2, [response count] - 2)] componentsJoinedByString:@" "];
			}
			
			// now enumerate over the headers which will be if the line is empty
			int i, lineCount = [headerLines count];
			for (i = 1; i < lineCount; i++)
			{
				NSString *line = [headerLines objectAtIndex:i];
				if ([line isEqualToString:@""])
				{
					//we hit the end of the headers
					i++;
					break;
				}
				NSRange colon = [line rangeOfString:@":"];
				if (colon.location != NSNotFound)
				{
					NSString *key = [line substringToIndex:colon.location];
					NSString *val = [line substringFromIndex:colon.location + colon.length + 1];
					BOOL hasMultiValues = [val rangeOfString:@";"].location != NSNotFound;
					
					if (hasMultiValues)
					{
						NSArray *vals = [val componentsSeparatedByString:@";"];
						NSMutableArray *mutableVals = [NSMutableArray array];
						NSEnumerator *e = [vals objectEnumerator];
						NSString *cur;
						
						while (cur = [e nextObject])
						{
							[mutableVals addObject:[cur stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
						}
						[headers setObject:mutableVals forKey:key];
					}
					else
					{
						[headers setObject:val forKey:key];
					}
				}
			}
		}
		BOOL isChunkedTransfer = NO;
		if ([headers objectForKey:@"Transfer-Encoding"])
		{
			if ([[[headers objectForKey:@"Transfer-Encoding"] lowercaseString] isEqualToString:@"chunked"])
			{
				isChunkedTransfer = YES;
			}
		}
		// now get the data range for the content
		unsigned start = NSMaxRange(headerRange);
		if (!isChunkedTransfer)
		{
			unsigned contentLength = [[headers objectForKey:@"Content-Length"] intValue];
			//S3 sends responses which are valid and complete but have Content-Length = 0. Confirmations of upload, delete, etc.
//			BOOL isAmazonS3 = ([headers objectForKey:@"Server"] && [[headers objectForKey:@"Server"] isEqualToString:@"AmazonS3"]);
//			if (contentLength > 0 || isAmazonS3) 
//			{
				unsigned end = start + contentLength;
				
				if (end <= [data length]) //only update the packet range if it is all there
				{
					packetRange.location = 0;
					packetRange.length = end;
				}
//			}
//			else
//			{
//				return packetRange;
//			}
		}
		else
		{
			NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
			NSData *newLineData = [[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
			NSRange lengthRange = [data rangeOfData:newLineData range:NSMakeRange(start, [data length] - start)];
			NSString *lengthString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(lengthRange.location - 4, 4)] encoding:NSUTF8StringEncoding] autorelease];
			NSScanner *scanner = [NSScanner scannerWithString:lengthString];
			unsigned chunkLength = 0;
			[scanner scanUpToCharactersFromSet:hexSet intoString:nil];
			[scanner scanHexInt:&chunkLength];
			
			while (chunkLength > 0)
			{
				//[self appendContent:[data subdataWithRange:NSMakeRange(NSMaxRange(lengthRange), chunkLength)]];
				
				lengthRange = [data rangeOfData:newLineData range:NSMakeRange(NSMaxRange(lengthRange) + chunkLength + 2, [data length] - NSMaxRange(lengthRange) - chunkLength - 2)];
				if (lengthRange.location == NSNotFound)
				{
					return packetRange;
				}
				lengthString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(lengthRange.location - 4, 4)] encoding:NSUTF8StringEncoding] autorelease];
				scanner = [NSScanner scannerWithString:lengthString];
				[scanner scanUpToCharactersFromSet:hexSet intoString:nil];
				[scanner scanHexInt:&chunkLength];
			}
			
			// the end of range will be 0\r\n\r\n
			//NSRange end = [packet rangeOfString:@"0\r\n\r\n"];
			packetRange.location = 0;
			packetRange.length = NSMaxRange(lengthRange);
		}
	} 
	@catch (NSException *e) {
		// do nothing - we cannot parse properly
	}
	@finally {
		
	}
	return packetRange;
}


@end