//
//  AppDelegate.m
//  FlapMyPort
//
//  Created by Владислав Павкин on 08/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    /*
    if ( visibleWindows )
    {
        [self.window orderFront:self];
    }
    else {
        [self.window makeKeyAndOrderFront:self];
    }
    */

    NSLog(@"%hhd", flag);

    for (NSWindow *Window in sender.windows)
    {
        if(!flag)
        {
            [Window makeKeyAndOrderFront:self];
        }
    }
    
    return YES;
}

@end
