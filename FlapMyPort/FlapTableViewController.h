//
//  FlapTableViewController.h
//  FlapMyPort
//
//  Created by Vladislav Pavkin on 05/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "FlapManager.h"
#import "URLManager.h"

@interface FlapTableViewController : NSViewController  <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *showButton;
@property (weak) IBOutlet NSTextFieldCell *bottomLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (weak) IBOutlet NSTextField *filterField;
@property (strong, nonatomic) NSTimer   *refreshTimer;


@property (weak) IBOutlet NSDatePicker *startDatePicker;
@property (weak) IBOutlet NSDatePicker *endDatePicker;

@property (weak) IBOutlet NSSegmentedControl *modeSelector;

- (void) disableControls;
- (void) enableControls;
- (void) updateContols;
- (void) showDatePickers;
- (void) setDatPickersValues;
- (void) pullConfig;
- (BOOL) noUrl;
- (void) noUrlError;
- (void) requestData;
- (NSString *) prepareUrlWithInterval;
- (NSString *) prepareUrlWithDates;
- (void) changeWorkMode: (NSUInteger) mode;
- (void) setInterval;
- (void) updateDates;
- (void) setStartDate: (NSDate *) date;
- (void) setEndDate: (NSDate *) date;
- (NSString *) getCurrentTimeString;
- (void) activateTimer;
- (void) deactivateTimer;
- (void) refresh: (NSData *) data;
- (void) connectionError: (NSError *) error;
- (NSString *) getCredentials;

- (void)copy:(id)sender;

- (IBAction)selectMode:(NSSegmentedControl *)sender;
- (IBAction)showButtonPressed:(NSButton *)sender;
- (IBAction)copySelectedRows;



@end
