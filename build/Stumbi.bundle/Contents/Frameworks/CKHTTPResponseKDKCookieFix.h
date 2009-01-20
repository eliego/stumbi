//
//  CKHTTPResponseKDKCookieFix.h
//  Stumbi
//
//  Created by eli ego on 20.09.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Connection/Connection.h"


@interface CKHTTPResponse (CKHTTPResponseKDKCookieFix)

- (NSArray*)cookies;

@end
