//
//  StumbiVoteSegmentedControl.h
//  Stumbi
//
//  Created by eli ego on 15.06.08.
//  Copyright 2008 Soya Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KDKInteractiveSegmentedControl.h"
#import "Stumbi.h"

#define STUMBI_TOOLBAR_BUTTON_THUMBS_UP_IMAGE @"thumbup"
#define STUMBI_TOOLBAR_BUTTON_THUMBS_UP_ALT_IMAGE @"thumbup_alt"

#define STUMBI_TOOLBAR_BUTTON_THUMBS_DOWN_IMAGE @"thumbdown"
#define STUMBI_TOOLBAR_BUTTON_THUMBS_DOWN_ALT_IMAGE @"thumbdown_alt"

@interface StumbiVoteSegmentedControl : KDKInteractiveSegmentedControl {
}

- (BOOL) selectedVote;
- (void) voteCompleted:(NSNotification*)theNotification;

@end
