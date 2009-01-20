//
//  StumbleUpon.h
//  Stumbi
//
//  Created by eli ego on 2008-01-31.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Connection/Connection.h"
#import "CKHTTPResponseKDKCookieFix.h"
#import "KDKStumble.h"
#import "URLExtension.h"

#define KDK_SU_HTTP_METHOD @"POST"
#define KDK_SU_HTTP_USER_AGENT @"mozbar 3.16 xpi"
#define KDK_SU_HTTP_PORT @"80"
#define KDK_SU_HTTP_HOST @"www.stumbleupon.com"
#define KDK_SU_LOGIN_URL_FORMAT @"http://www.stumbleupon.com/login.php?session_url=home&username=%@&password=%@"

#define KDK_SU_DEFAULTS_VISITED_STUMBLES_KEY @"KDK_SU_DEFAULTS_VISITED_STUMBLES_KEY"

#define KDK_SU_REQUEST_TYPE_KEY @"KDK_SU_REQUEST_TYPE_KEY"
#define KDK_SU_STUMBLE_URL_KEY @"KDK_SU_STUMBLE_URL_KEY"
#define KDK_SU_STUMBLE_RATING_KEY @"KDK_SU_STUMBLE_RATING_KEY"

//#define KDK_SU_HTTP_DEBUG

extern NSString* const KDKUnparsableDataException;
extern NSString* const KDKUnknownAddressException;
extern NSString* const KDKErrorData;
extern NSString* const KDKErrorSeverity;
extern NSString* const KDKErrorCameFromRequestType;
extern NSString* const KDKErrorURL;
extern NSString* const KDKErrorRating;
extern NSString* const KDKErrorSeverityHigh;
extern NSString* const KDKErrorSeverityLow;
extern NSString* const KDKInvalidArgumentException;
extern NSString* const KDKAuthenticationException;
extern NSString* const KDKServerDownException;
extern NSString* const KDKStumbleUponLoginFinishedNotification;

enum requestType { fetchStumblesRequest = 1, voteRequest, userInfoRequest, sendEmailRequest, reportStumblesRequest };

typedef enum { success = 1, unknownURL } KDKVoteResponse;

@interface KDKStumbleUponWrapper : NSObject {
	int userID;
	NSString* userName;
	NSString* userPassword;
	id delegate;
	NSMutableSet* unvisitedURLs;
	NSMutableArray* visitedURLs;
	CKHTTPConnection* httpConnection;
}

- (id) initWithUserName: (NSString*)theUserName password: (NSString*)theUserPassword;

- (NSString*) userPassword;
- (NSString*) userName;

- (id)delegate;
- (void)setDelegate: (id)theDelegate;

- (void)setProxyHost:(NSString*)theHost port:(int)thePort;

- (void)login:(NSString*)theUserName withUserPassword:(NSString*)theUserPassword;
- (void)requestNewStumble;
- (NSURL*)loginURL;
- (void)vote:(BOOL)theVote forURL:(NSURL*)theURL;
- (void)sendUrl:(NSURL*)theUrl toEmail:(NSString*)theEmail;
- (void)close;

// Implemented delegate methods
- (void) connection:(CKHTTPConnection *)connection didReceiveResponse:(CKHTTPResponse *)response;

@end


@interface NSObject (KDKStumbleUponWrapperDelegate)

- (void) receiveNewStumble:(NSURL*)theStumbleURL;
- (void) receiveNewException:(NSException*)theException;
- (void) receiveNewVoteResponse:(KDKVoteResponse)theResponse url:(NSURL*)theUrl vote:(BOOL)theVote;

@end


@interface NSArray (ArrayStringSearchExtension)

- (NSString*) searchForString:(NSString*)theString;

@end