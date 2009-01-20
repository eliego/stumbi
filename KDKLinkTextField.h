//
//  KDKLinkTextField.h
//  Stumbi
//
//  Created by eli ego on 05.09.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KDKLinkTextField : NSTextField {
	NSURL* href;
}

- (void) awakeFromNib;

- (NSURL*)href;
- (void)setHref: (NSURL*)theHref;
- (void)launchHrefFrom: (id)sender;

@end
