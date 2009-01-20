//
//  StumbiNewURLWindowController.h
//  Stumbi
//
//  Created by eli ego on 2008-04-04.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebKit/WebKit.h"
#import "URLExtension.h"

#define STUMBI_NEW_URL_WINDOW_NIB_NAME @"NewURLWindow"

#define STUMBI_NEW_URL_HTTP_URL @"http://www.stumbleupon.com/newurl.php"

#define STUMBI_NEW_URL_RESULT_TO_CLOSE_ON @"rating submitted"

@interface StumbiNewURLWindowController : NSWindowController {
	IBOutlet WebView* webView;
}

- (void) showWindowToPostNewUrl:(NSURL*)theUrl withTitle:(NSString*)theTitle;
- (void) goToUrl:(NSURL*)theUrl;

// Frameload delegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

@end
