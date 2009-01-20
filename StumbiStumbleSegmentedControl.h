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

@interface StumbiStumbleSegmentedControl : KDKInteractiveSegmentedControl {
}

- (void) stumbleCompleted:(NSNotification*)theNotification;

@end
