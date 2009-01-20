//
//  StumbiNewURLWindowController.m
//  Stumbi
//
//  Created by eli ego on 2008-04-04.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import "StumbiNewURLWindowController.h"

@implementation StumbiNewURLWindowController

- (id) init {
	id ret = [super initWithWindowNibName:STUMBI_NEW_URL_WINDOW_NIB_NAME];
	
	// Load window
	[self window];
	
	return ret;
}


- (void) showWindowToPostNewUrl:(NSURL*)theUrl withTitle:(NSString*)theTitle {

	NSString* content = [NSString stringWithFormat:@"url=%@&title=%@", [theUrl escapedString], theTitle];
		
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:STUMBI_NEW_URL_HTTP_URL]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];

	[webView setHidden:YES];
	[[webView mainFrame] loadRequest:request];
	[self showWindow:self];
}

- (void) goToUrl:(NSURL*)theUrl {
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:theUrl];
	[request setHTTPMethod:@"GET"];
	[[webView mainFrame] loadRequest:request];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSString* result = [[[[[frame DOMDocument] getElementsByTagName:@"body"] item:0] firstChild] nodeValue];
	if ([result hasSuffix:STUMBI_NEW_URL_RESULT_TO_CLOSE_ON]) {
		[self close];
		[webView setHidden:YES];
	}
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
	[webView setHidden:NO];
}

@end
