//
//  PrefController.h
//  FlapMyPort
//
//  Created by Vladislav Pavkin on 05/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "URLManager.h"

@interface PrefController : NSViewController
@property (strong) IBOutlet NSTextField *urlField;
@property (strong) IBOutlet NSTextField *loginField;
@property (strong) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSButton *applyButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTextField *helperText;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)ApplyClick:(id)sender;
- (IBAction)CancelClick:(id)sender;

- (void) refresh: (NSMutableData *) data;
- (void) connectionError: (NSError *) error;

@end
