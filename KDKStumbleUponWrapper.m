//
//  StumbleUpon.m
//  Stumbi
//
//  Created by eli ego on 2008-01-31.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "KDKStumbleUponWrapper.h"

NSString* const KDKUnparsableDataException = @"KDKUnparsableDataException";
NSString* const KDKUnknownAddressException = @"KDKUnknownAddressException";
NSString* const KDKErrorData = @"KDKErrorData";
NSString* const KDKErrorCameFromRequestType = @"KDKErrorCameFromRequestType";
NSString* const KDKErrorURL = @"KDKErrorURL";
NSString* const KDKErrorRating = @"KDKErrorRating";
NSString* const KDKErrorSeverityHigh = @"KDKErrorSeverityHigh";
NSString* const KDKErrorSeverityLow = @"KDKErrorSeverityLow";
NSString* const KDKErrorSeverity = @"KDKErrorSeverity";
NSString* const KDKInvalidArgumentException = @"KDKInvalidArgumentException";
NSString* const KDKAuthenticationException = @"KDKAuthenticationException";
NSString* const KDKServerDownException = @"KDKServerDownException";
NSString* const KDKStumbleUponLoginFinishedNotification = @"KDKStumbleUponLoginFinishedNotification";

@interface KDKStumbleUponWrapper (KDKStumbleUponWrapperPrivate)
- (void) fetchNewLinks;
- (void) reportStumbles;
- (void) sendAction:(CKHTTPRequest*) action;
- (void) sendAction:(CKHTTPRequest*) action withAuth:(BOOL)sendAuth;
- (void) parseStumbleResponse:(NSString*)theData;
- (void) parseVoteResponse:(NSString*)theData url:(NSURL*)theUrl vote:(BOOL)theVote;
- (void) parseUserInfoResponse:(NSString*)theData;
- (void)clearCachedURLs;
- (NSString*)visitedStumblesPOSTString;

// Local delegate wrapper methods
- (void) receiveNewStumble:(NSURL*)theStumbleURL;
- (void) receiveNewException:(NSException*)theException;
- (void) receiveNewVoteResponse:(KDKVoteResponse)theResponse url:(NSURL*)theUrl vote:(BOOL)theVote;
@end


@implementation KDKStumbleUponWrapper

- (id) init {
	self = [super init];
	if (self != nil) {
		unvisitedURLs = [[NSMutableSet alloc] init];
		httpConnection = [[CKHTTPConnection alloc] initWithHost:KDK_SU_HTTP_HOST port:KDK_SU_HTTP_PORT username:nil password:nil error:nil];
		[httpConnection setDelegate:self];
		userPassword = [NSString string];
		userName = [NSString string];
		
		// Load visited unsubmitted URLs from UserDefaults
		NSData* data;
		if (data = [[NSUserDefaults standardUserDefaults] dataForKey:KDK_SU_DEFAULTS_VISITED_STUMBLES_KEY]) {
			visitedURLs = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];;
		}
		
		if (!visitedURLs)
			visitedURLs = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id) initWithUserName: (NSString*)theUserName password: (NSString*)theUserPassword {
	if ([self init]) {
		[self login: theUserName withUserPassword: theUserPassword];
	}
	
	return self;
}

- (NSString*) userName {
	return userName;
}

- (NSString*) userPassword {
	return userPassword;
}

- (void) dealloc {
	[userName release];
	[userPassword release];
	[unvisitedURLs release];
	[visitedURLs release];
	[httpConnection closeStreams];
	[httpConnection release];
	[super dealloc];
}

- (void) setDelegate: (id)theDelegate {
	delegate = theDelegate;
}

- (id) delegate {
	return delegate;
}

- (void)setProxyHost:(NSString*)theHost port:(int)thePort {
	; // Do nothing at the moment
}

// Request new stumle url. Calls delegate method when available.
- (void) requestNewStumble {
	KDKStumble* stumble;
	if (stumble = [unvisitedURLs anyObject]) {
		[stumble setTimestamp:[[NSDate date] timeIntervalSince1970]];
		
		[visitedURLs addObject:stumble];
		
		// If someone referred this to us, we must report it right away
		if ([stumble referral] != 0)
			[self reportStumbles];
		
		[self receiveNewStumble: [stumble url]];
		
		[unvisitedURLs removeObject: stumble];
	} else {
		[self fetchNewLinks];
	}
}

- (void)vote:(BOOL)theVote forURL:(NSURL*)theURL {	
	CKHTTPRequest* action = [[CKHTTPRequest alloc] initWithMethod:KDK_SU_HTTP_METHOD uri:@"/rate.php"];
	
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:voteRequest] forKey:KDK_SU_REQUEST_TYPE_KEY];
	[userInfo setObject:theURL forKey:KDK_SU_STUMBLE_URL_KEY];
	[userInfo setObject:[NSNumber numberWithBool:theVote] forKey:KDK_SU_STUMBLE_RATING_KEY];
	[action setUserInfo:userInfo];
	
	// Construct content
	[action setContentString:[NSString stringWithFormat:@"rating=%d&url=%@", theVote, [theURL escapedString]]];
	[self sendAction:action];
	[action release];
}

- (void)login:(NSString*)theUserName withUserPassword:(NSString*)theUserPassword {
	if ([userName length] && [userPassword length]) {
		[self clearCachedURLs];
		@try {
			[self reportStumbles];
		} @catch (NSException* e) {
			;
		}
	}

	[userName autorelease];
	userName = [theUserName copy];
	
	[userPassword autorelease];
	userPassword = [theUserPassword copy];
	
	userID = 0;	

	CKHTTPRequest* action = [[CKHTTPRequest alloc] initWithMethod:KDK_SU_HTTP_METHOD uri:@"/userexists.php"];
	[action setContentString:[NSString stringWithFormat:@"username=%@&password=%@", theUserName, theUserPassword]];
	[action setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:userInfoRequest] forKey:KDK_SU_REQUEST_TYPE_KEY]];
	[self sendAction:action withAuth:NO];
	[action release];
}

// Send URL to friend
- (void)sendUrl:(NSURL*)theUrl toEmail:(NSString*)theEmail {
	CKHTTPRequest* action = [[CKHTTPRequest alloc] initWithMethod:KDK_SU_HTTP_METHOD uri:@"/mailit.php"];
	
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:sendEmailRequest] forKey:KDK_SU_REQUEST_TYPE_KEY];
	[userInfo setObject:theUrl forKey:KDK_SU_STUMBLE_URL_KEY];
	[action setUserInfo:userInfo];
	
	[action setContentString:[NSString stringWithFormat:@"url=%@&recipient=%@", [theUrl escapedString], theEmail]];
	[self sendAction:action];
	[action release];
}

- (NSURL*)loginURL {
	return [NSURL URLWithString:[NSString stringWithFormat:KDK_SU_LOGIN_URL_FORMAT, [self userName], [self userPassword]]];
}

// Save visisted, unsubmitted stumbles to user defaults
- (void)close {
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:visitedURLs];
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:KDK_SU_DEFAULTS_VISITED_STUMBLES_KEY];
}

// Delegate method: we got a response!
- (void) connection:(CKHTTPConnection *)connection didReceiveResponse:(CKHTTPResponse *)response {
	
#ifdef KDK_SU_HTTP_DEBUG
	NSLog(@"Stumbi got: %@", [response contentString]);
#endif
	
	CKHTTPRequest* originatingRequest = [response request];

	@try {
		if ([[response contentString] isEqualToString:@"ERROR NO_SUCH_USERNAME"])
			[NSException raise:KDKAuthenticationException format:@"Incorrect username or password!"];
		else if ([[response contentString] isEqualToString:@"ERROR INCORRECT_PASSWORD"])
			[NSException raise:KDKAuthenticationException format:@"Incorrect username or password!"];
		else if ([[response contentString] isEqualToString:@"ERROR INVALID_ARGUMENTS"])
			[NSException raise:KDKAuthenticationException format:@"Incorrect username or password!"];
		else if ([[response contentString] isEqualToString:@"ERROR MAINTENANCE"])
			[NSException raise:KDKServerDownException format:@"StumbleUpon is down for maintenance at the moment. Please try again soon!"];
		else if ([[response contentString] length] == 0)
			[NSException raise:KDKAuthenticationException format:@"Incorrect username or password!"];
		else {
			// Which type of request did result in this response?
			switch ( [(NSNumber*)[(NSDictionary*)[originatingRequest userInfo] objectForKey:KDK_SU_REQUEST_TYPE_KEY] intValue] ) {
				case fetchStumblesRequest:
					/* We've got new stumbles - parse, fill array. We assume the request originated from
					requestNewStumble, so we call it to let it push a new stumble to the delegate */
					[self parseStumbleResponse:[response contentString]];
					[self requestNewStumble];
					break;
				case voteRequest:
					[self parseVoteResponse:[response contentString] url:[[originatingRequest userInfo] objectForKey:KDK_SU_STUMBLE_URL_KEY]
									   vote:[(NSNumber*)[[originatingRequest userInfo] objectForKey:KDK_SU_STUMBLE_RATING_KEY] boolValue]];
					break;
				case userInfoRequest:
					[self parseUserInfoResponse:[response contentString]];
					break;
					
				default: // Hmm?
					break;
			}
		}
	} @catch (NSException* e) {
		// Something went wrong - call delegate method with exception. First get all info from request to error..
		// This could probably be done in a nicer way.
		NSMutableDictionary* exceptionUserInfo;
		if (!(exceptionUserInfo = [[e userInfo] mutableCopy]))
			exceptionUserInfo = [NSMutableDictionary dictionary];
		
		if (![exceptionUserInfo objectForKey:KDKErrorSeverity])
			[exceptionUserInfo setObject:KDKErrorSeverityLow forKey:KDKErrorSeverity];
		
		[exceptionUserInfo setObject:[response contentString] forKey:KDKErrorData];
		
		NSDictionary* requestUserInfo = [originatingRequest userInfo];
		[exceptionUserInfo setObject:[requestUserInfo objectForKey:KDK_SU_REQUEST_TYPE_KEY] forKey:KDKErrorCameFromRequestType];
		
		NSURL* stumbleUrl;
		if (stumbleUrl = [requestUserInfo objectForKey:KDK_SU_STUMBLE_URL_KEY])
			[exceptionUserInfo setObject:stumbleUrl forKey:KDKErrorURL];
		
		if ([requestUserInfo objectForKey:KDK_SU_STUMBLE_RATING_KEY])
			[exceptionUserInfo setObject:[requestUserInfo objectForKey:KDK_SU_STUMBLE_RATING_KEY] forKey:KDKErrorRating];
		
		NSException* newE = [NSException exceptionWithName:[e name] reason:[e reason] userInfo:exceptionUserInfo];
		[self receiveNewException:newE];
	}
}	

@end


@implementation KDKStumbleUponWrapper (KDKStumbleUponWrapperPrivate)
// Actually fetch new links from server
- (void) fetchNewLinks {
	// Construct request
	CKHTTPRequest* action = [[CKHTTPRequest alloc] initWithMethod:KDK_SU_HTTP_METHOD uri:@"/recommend.php"];
	
	[action setContentString:[self visitedStumblesPOSTString]];
	[action setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:fetchStumblesRequest] forKey:KDK_SU_REQUEST_TYPE_KEY]];
	[self sendAction: action];
	[action release];
}

- (void)reportStumbles {
	// Construct request
	CKHTTPRequest* action = [[CKHTTPRequest alloc] initWithMethod:KDK_SU_HTTP_METHOD uri:@"/stumbles.php"];
	
	[action setContentString:[self visitedStumblesPOSTString]];
	[action setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:reportStumblesRequest] forKey:KDK_SU_REQUEST_TYPE_KEY]];
	[self sendAction: action];
	[action release];
}

- (void) sendAction:(CKHTTPRequest*) action {
	[self sendAction:action withAuth:YES];
}

- (void) sendAction: (CKHTTPRequest*) action withAuth:(BOOL)sendAuth {
	// Add auth to action
	if (sendAuth) {
		NSString* possibleDelimiter = ([[action contentString] length] > 0) ? @"&" : @"";
		[action setContentString:[NSString stringWithFormat:@"%@%@username=%d&password=%@", [action contentString], possibleDelimiter, userID, [self userPassword]]];
	}
	
	// Setup request
	NSString* cookieContent = [NSString stringWithFormat:@"stumble_user=%d;stumble_pass=%@;version=%@", userID, [self userPassword], KDK_SU_HTTP_USER_AGENT];
	[action addHeader:cookieContent forKey:@"Cookie"];
	[action addHeader:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
	[action setHeader:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_4_11; sv-se) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.2 Safari/525.22" forKey:@"User-Agent"];
	
	[action setHeader:KDK_SU_HTTP_USER_AGENT forKey:@"X-SU-Version"];
	[action setHeader:[NSString stringWithFormat:@"%d", userID] forKey:@"X-SU-Username"];
	[action setHeader:[self userPassword] forKey:@"X-SU-Password"];
	
	// Connect and send
	if (![httpConnection isConnected])
		[httpConnection connect];

	[httpConnection sendRequest: action];
}

// Push link to delegate
- (void) receiveNewStumble:(NSURL*)theStumbleURL {
	if ([delegate respondsToSelector: _cmd])
		[delegate receiveNewStumble: theStumbleURL];
}

- (void) receiveNewException:(NSException*)theException {
	if ([delegate respondsToSelector:_cmd])
		[delegate receiveNewException:theException];
}

- (void) receiveNewVoteResponse:(KDKVoteResponse)theResponse url:(NSURL*)theUrl vote:(BOOL)theVote {
	if ([delegate respondsToSelector:_cmd])
		[delegate receiveNewVoteResponse:theResponse url:theUrl vote:theVote];
}

- (void) parseStumbleResponse:(NSString*)theData {
	NSMutableSet* theTargetSet = unvisitedURLs;
	
	int originalItemCount = [theTargetSet count];
	NSArray* responseLines = [theData componentsSeparatedByString:@"\n"];
	NSEnumerator* responseLinesEnumerator = [responseLines objectEnumerator];
	
	NSString* aLine;
	while (aLine = [responseLinesEnumerator nextObject]) {
		NSArray* wordsInTheLine = [aLine componentsSeparatedByString:@" "];
		if ( [(NSString*)[wordsInTheLine objectAtIndex:0] isEqualToString:@"URL"] ) {
			KDKStumble* aStumble = [[KDKStumble alloc] init];
			[aStumble setUrl:[NSURL URLWithString:[wordsInTheLine objectAtIndex:1]]];
			if ([wordsInTheLine count] > 12) {
				[aStumble setUrlId:[(NSString*)[wordsInTheLine objectAtIndex:9] intValue]];
				[aStumble setType:[(NSString*)[wordsInTheLine objectAtIndex:12] intValue]];
				if ([wordsInTheLine count] > 14) {
					[aStumble setReferral:[(NSString*)[wordsInTheLine objectAtIndex:14] intValue]];
				} else
					[aStumble setReferral:0];
			} else {
				[aStumble setUrlId:0];
				[aStumble setType:0];
			}
			
			[theTargetSet addObject:[aStumble autorelease]];
		}
	}
	
	// If we didn't parse any data, scream
	if ([theTargetSet count] == originalItemCount) {
		NSException* e = [NSException exceptionWithName:KDKUnparsableDataException
												 reason:@"The data received from StumbleUpon couldn't be parsed."
											   userInfo:[NSDictionary dictionaryWithObject:KDKErrorSeverityHigh
																					forKey:KDKErrorSeverity]];
		[e raise];
	}
}

- (void) parseVoteResponse:(NSString*)theData url:(NSURL*)theUrl vote:(BOOL)theVote {
	NSArray* responseLines = [theData componentsSeparatedByString:@"\n"];
	// STRINGARRAY
	if ([responseLines searchForString:@"NEWURL"]) {
		[self receiveNewVoteResponse:unknownURL url:theUrl vote:theVote];
	} else // Since SU suddenly decided to stop answering but silently register the vote
		[self receiveNewVoteResponse:success url:theUrl vote:theVote];
}

- (void) parseUserInfoResponse:(NSString*)theData {
	NSArray* responseLines = [theData componentsSeparatedByString:@"\n"];
	NSArray* wordsInFirstLine = [[responseLines objectAtIndex:0] componentsSeparatedByString:@" "];
	int newUserID;
	
	if ( ([[wordsInFirstLine objectAtIndex:0] isEqualToString:@"USER"]) && 
		 ([wordsInFirstLine count] == 2) &&
		 ((newUserID = [[wordsInFirstLine objectAtIndex:1] intValue]) != 0) ) {
		userID = newUserID;

		[[NSNotificationCenter defaultCenter] postNotificationName:KDKStumbleUponLoginFinishedNotification object:self];
	} else {
		NSMutableDictionary* userInfoDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
		[userInfoDictionary setObject:KDKErrorSeverityHigh forKey:KDKErrorSeverity];
		
		NSException* e = [NSException exceptionWithName:KDKUnparsableDataException
												 reason:@"The data received from StumbleUpon couldn't be parsed."
											   userInfo:userInfoDictionary];
		[e raise];
	}
}
	
- (void)clearCachedURLs {
	[unvisitedURLs removeAllObjects];
}

// Report visited URL:s
- (NSString*)visitedStumblesPOSTString {
	if ([visitedURLs count] > 0) {	
		KDKStumble* aStumble;
		NSMutableString* urlIds = [NSMutableString string];
		NSMutableString* timestamps = [NSMutableString string];
		NSMutableString* types = [NSMutableString string];
		NSMutableString* referralIds = [NSMutableString string];
		NSMutableString* recentlySeen = [NSMutableString string];

		while (aStumble = [visitedURLs lastObject]) {
			if (![aStumble urlId])
				continue;
			
			[urlIds insertString:[NSString stringWithFormat:@"%d.", [aStumble urlId]] atIndex:0];
			[timestamps insertString:[NSString stringWithFormat:@"%d.", [aStumble timestamp]] atIndex:0];
			[types insertString:[NSString stringWithFormat:@"%d.", [aStumble type]] atIndex:0];
			[referralIds insertString:[NSString stringWithFormat:@"%@.", (([aStumble referral] != 0) ? [NSString stringWithFormat:@"%d", [aStumble referral]] : @"")] atIndex:0];
			[recentlySeen appendFormat:@"%d.", [aStumble urlId]];
			
			[visitedURLs removeLastObject];
		}
		
		// Remove trailing dot
		[urlIds deleteCharactersInRange:NSMakeRange([urlIds length] - 1, 1)];
		[timestamps deleteCharactersInRange:NSMakeRange([timestamps length] - 1, 1)];
		[types deleteCharactersInRange:NSMakeRange([types length] - 1, 1)];
		[referralIds deleteCharactersInRange:NSMakeRange([referralIds length] - 1, 1)];
		
		return [NSString stringWithFormat:@"urlids=%@&timestamps=%@&types=%@&referralids=%@&recentlySeen=%@",
			urlIds,
			timestamps,
			types,
			referralIds,
			recentlySeen];
	} else {
		return [NSString string];
	}
}

@end


@implementation NSArray (ArrayStringSearchExtension)

- (NSString*) searchForString:(NSString*)theString {
	NSEnumerator* enumerator = [self objectEnumerator];
	id anObject;
	while (anObject = [enumerator nextObject])
		if ([anObject isKindOfClass:[NSString class]])
			if ([(NSString*)anObject isEqualToString:theString])
				return anObject;
	
	return nil;
}

@end