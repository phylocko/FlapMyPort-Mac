//
//  FlapTableViewController.m
//  FlapMyPort
//
//  Created by Vladislav Pavkin on 05/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import "FlapTableViewController.h"
#import "CheckBoxTableCell.h"
#import "ChartCell.h"

@interface FlapTableViewController () <URLManagerDelegate, NSTextFieldDelegate>
{
    NSMutableArray	*flapList;
    NSMutableArray  *flapListFiltered;
    URLManager		*myConnection;
    unsigned long   eldestFlapAtLastUpdate;

    NSDate          *startDate;
    NSDate          *endDate;
    NSString        *interval;
    NSArray         *WorkModes;
    NSString        *WorkMode; // Will be @"1MIN", ,@"10MINS", @"1HOUR", @"1HOUR", @"MANUAL"
    BOOL            autoRefresh;
    NSInteger        oldestFlapID;
    NSInteger        lastOldestFlapID;
    NSUserDefaults  *config;
    NSString        *ApiUrl;
    
    NSString        *UserLogin;
    NSString        *UserPassword;
    
}

@end

@implementation FlapTableViewController



- (void)viewDidLoad {
    
    oldestFlapID = 0;
    lastOldestFlapID = 0;
    
    config = [NSUserDefaults standardUserDefaults];
    
    if([self apiIsDefault] == YES)
    {
        [self showAlert:@"You have VirtualAPI link configured as your API URL, so you are seeing fake data.\r\nPlease open Preferences and type your URL." withTitle:@"No URL Configured"];
    }
    
    if ([self apiUrlExists] == NO)
    {
        [self showAlert:@"You have no API URL configured so we're going to use VirtualAPI. Please open Preferences and type your URL." withTitle:@"No URL Configured"];

    }

    self.filterField.delegate = self;

    WorkModes = @[@"1MIN" ,@"10MIN", @"1HOUR", @"INTERVAL", @"FROM"];
    
    [self changeWorkMode:2];
    
    [super viewDidLoad];
    
    
    [self updateContols];

    
    
    [self pullConfig];
    
    
    flapList = [[NSMutableArray alloc] init];
    flapListFiltered = [[NSMutableArray alloc] init];
    
    [self disableControls];

    myConnection = [URLManager sharedInstance];
    [myConnection createSession];
    myConnection.delegate = self;
    myConnection.UserLogin = UserLogin;
    myConnection.UserPassword = UserPassword;

    [self requestData];
    
}



#pragma mark - Button Operations

- (void) disableControls
{
    self.showButton.enabled = NO;
    self.filterField.enabled = NO;
    self.modeSelector.enabled = NO;
    self.startDatePicker.enabled = NO;
    self.endDatePicker.enabled = NO;
    
    self.progressIndicator.hidden = NO;
    [self.progressIndicator startAnimation:0];

}

- (void) enableControls
{
    self.showButton.enabled = YES;
    self.filterField.enabled = YES;
    self.modeSelector.enabled = YES;
    self.startDatePicker.enabled = YES;
    self.endDatePicker.enabled = YES;
    
    self.progressIndicator.hidden = YES;
    [self.progressIndicator stopAnimation:0];
}

- (IBAction)selectMode:(NSSegmentedControl *)sender {

    [self changeWorkMode: sender.selectedSegment];

}

- (void) updateContols
{
    [self showDatePickers];
}

- (void) showDatePickers
{

    if([WorkMode isEqualToString:@"INTERVAL"])
    {
        self.startDatePicker.hidden = NO;
        self.endDatePicker.hidden = NO;
        return;
    }

    if([WorkMode isEqualToString:@"FROM"])
    {
        self.startDatePicker.hidden = NO;
        self.endDatePicker.hidden = YES;
        return;
    }
    
    self.startDatePicker.hidden = YES;
    self.endDatePicker.hidden = YES;
    return;
}

- (void) setDatPickersValues
{
    self.startDatePicker.dateValue = startDate;
    self.endDatePicker.dateValue = endDate;
}
#pragma mark - My Methods

- (NSString *)getEncodedFilterString {
    return  [self.filterField.stringValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
}

- (void) pullConfig
{

    if( [self apiUrlExists] == NO )
    {
        [self setDefaultApiUrl];
    }
    
    if([config valueForKey:@"UserLogin"] == nil)
    {
        [config setObject:@"" forKey:@"UserLogin"];
    }

    if([config valueForKey:@"UserPassword"] == nil)
    {
        [config setObject:@"" forKey:@"UserPassword"];
    }
    if([config valueForKey:@"ApiUrl"] == nil)
    {
        [config setObject:@"" forKey:@"ApiUrl"];
    }
    UserLogin = [config valueForKey:@"UserLogin"];
    UserPassword = [config valueForKey:@"UserPassword"];

    ApiUrl = [config valueForKey:@"ApiUrl"];
    
}

- (BOOL) apiUrlExists
{
    if([config valueForKey:@"ApiUrl"] == nil)
    {
        return NO;
    }

    if([[config valueForKey:@"ApiUrl"] isEqualToString:@""])
    {
        return NO;
    }
    
    return YES;
}

- (void) setDefaultApiUrl
{
    [config setObject:@"http://virtualapi.flapmyport.com" forKey:@"ApiUrl"];
}

- (BOOL) apiIsDefault
{
    if( [[config valueForKey:@"ApiUrl"] isEqualToString:@"http://virtualapi.flapmyport.com"])
    {
        return YES;
    }

    return NO;
}

- (void) showAlert: (NSString *) message withTitle: (NSString *) title
{
    self.bottomLabel.stringValue = title;
    [self enableControls];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: message];
    [alert runModal];
    
}

- (void) requestData // Asks FlaFlapManager to request the url and call my appropriate method
{
    [self pullConfig];

    [self deactivateTimer];
    
    NSString *url = [[NSString alloc] init];

    if([WorkMode isEqualToString:@"1MIN"] || [WorkMode isEqualToString:@"10MIN"] || [WorkMode isEqualToString:@"1HOUR"])
    {
        url = [self prepareUrlWithInterval];
    }
    else
    {
        url = [self prepareUrlWithDates];
    }
    
    [self disableControls];

    self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — Requesting data from url %@", [self getCurrentTimeString], ApiUrl];
    
    myConnection.delegate = self;
    myConnection.UserLogin = UserLogin;
    myConnection.UserPassword = UserPassword;

    [myConnection getURL:url];

}

- (NSString *) prepareUrlWithInterval
{
    interval = @"3600";

    if([WorkMode isEqualToString:@"1MIN"])
    {
        interval = @"60";
    }

    if([WorkMode isEqualToString:@"10MIN"])
    {
        interval = @"600";
    }

    if([WorkMode isEqualToString:@"1HOUR"])
    {
        interval = @"3600";
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/?review&interval=%@&filter=%@", ApiUrl, interval, [self getEncodedFilterString]];

    return url;
}

- (NSString *) prepareUrlWithDates
{
    NSDateFormatter *txtFormat = [[NSDateFormatter alloc] init];
    [txtFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *url = [NSString stringWithFormat:@"%@/?review&start=%@&end=%@&filter=%@", ApiUrl, [txtFormat stringFromDate:startDate], [txtFormat stringFromDate:endDate], [self getEncodedFilterString]];

    url = [url stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    return url;
}


- (void) changeWorkMode: (NSUInteger) mode
{
    WorkMode = [WorkModes objectAtIndex:mode];

    [self setInterval];
    
    [self deactivateTimer];
    
    [self updateDates];
    
    [self showDatePickers];
    
    autoRefresh = YES;
    
    if([WorkMode isEqualToString:@"INTERVAL"])
    {
        autoRefresh = NO;
    }
    else
    {
        [self requestData];
    }

    return;
   
}
- (void) setInterval
{
    if ([WorkMode isEqualToString:@"1MIN"])
    {
        interval = @"60";
    }
    if ([WorkMode isEqualToString:@"10MIN"])
    {
        interval = @"600";
    }
    if ([WorkMode isEqualToString:@"1HOUR"])
    {
        interval = @"3600";
    }
}

- (void) updateDates
{
    if([WorkMode isEqualToString:@"INTERVAL"])
    {
        [self setStartDate:self.startDatePicker.dateValue];
        [self setEndDate:self.endDatePicker.dateValue];
    }
    else if([WorkMode isEqualToString:@"FROM"])
    {
        [self setStartDate:self.startDatePicker.dateValue];
        [self setEndDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
    else
    {
        [self setStartDate:[NSDate dateWithTimeIntervalSinceNow:-[interval intValue]]];
        [self setEndDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
}

- (void) setStartDate: (NSDate *) date
{
    startDate = date;
    self.startDatePicker.dateValue = date;
}
- (void) setEndDate: (NSDate *) date
{
    endDate = date;
    self.endDatePicker.dateValue = date;
}

- (NSString *) getCurrentTimeString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];

    [formatter setDateStyle:NSDateFormatterMediumStyle];

    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];;
}
- (NSString *) getCredentials
{
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", UserLogin, UserPassword];
    NSData *authData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encodedHeader = [authData base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:encodedHeader encoding:NSUTF8StringEncoding];
    NSString *readyString = [NSString stringWithFormat:@"Basic %@", encodedString];
    
    return readyString;
}

- (NSString *) getHostnameFromFlap: (NSDictionary *) flap
{
    NSString *ipaddress = [flap objectForKey:@"ipaddress"];
    NSString *hostname = [flap objectForKey:@"hostname"];
    
    if([hostname isKindOfClass:[NSNull class]])
    {
        return ipaddress;
    }
    else
    {
        return hostname;
    }
}

- (NSString *) getIfNameFromFlap: (NSDictionary *) flap
{
    NSString *ifName = [flap objectForKey:@"ifName"];
    NSString *ifAlias = [flap objectForKey:@"ifAlias"];

    
    if(![ifAlias isKindOfClass:[NSNull class]])
    {
        if (![ifAlias isEqualToString:@""])
        {
            return [NSString stringWithFormat:@"%@ — %@", ifName, ifAlias];
        }
    }
    
    return [NSString stringWithFormat:@"%@", ifName];
}

- (void) copySelectedRows
{
    NSIndexSet *selectedRows = self.tableView.selectedRowIndexes;
    
    __block NSString *copyString = [[NSString alloc] init];
    
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSDictionary *flap = [self->flapListFiltered objectAtIndex:idx];
        
        NSString *appendingString = [[NSString alloc] initWithFormat:@"%@\t%@\t%@ — %@\t%@\r\n",
                                     [self getHostnameFromFlap:flap],
                                     [self getIfNameFromFlap:flap],
                                     [flap objectForKey:@"firstFlapTime"],
                                     [flap objectForKey:@"lastFlapTime"],
                                     [flap objectForKey:@"ifOperStatus"]];
        
        copyString = [copyString stringByAppendingString:appendingString];
        
    }];
    
    [[NSPasteboard generalPasteboard] clearContents];
    
    [[NSPasteboard generalPasteboard] setString:copyString forType:NSStringPboardType];
}



#pragma mark - TableView Methods
-(void)tableView:(NSTableView *)mtableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [flapListFiltered sortUsingDescriptors: [mtableView sortDescriptors]];
    [self.tableView reloadData];
}


- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return flapListFiltered.count;
    return 0;
}


- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{

    NSDictionary *flap = [flapListFiltered objectAtIndex:row];

    NSString *colID = tableColumn.identifier;

    
    
    

    // === CHART ================================================================================================
    
    if ([colID isEqualToString:@"chart"])
    {
        ChartCell *cell = [tableView makeViewWithIdentifier:[colID stringByAppendingString:@"Cell"] owner:self];

        NSString *urlString = [[NSString alloc] init];
        
        if([WorkMode isEqualToString:@"INTERVAL"] || [WorkMode isEqualToString:@"FROM"])
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *startDateTxt = [formatter stringFromDate:startDate];
            NSString *endDateTxt = [formatter stringFromDate:endDate];
            
            urlString = [NSString stringWithFormat:@"%@/?ifindex=%@&flapchart&host=%@&start=%@&end=%@", ApiUrl, [flap valueForKey:@"ifIndex"], [flap valueForKey:@"ipaddress"], startDateTxt, endDateTxt];
            urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        }
        else
        {
            urlString = [NSString stringWithFormat:@"%@/?ifindex=%@&flapchart&host=%@&interval=%@", ApiUrl, [flap valueForKey:@"ifIndex"], [flap valueForKey:@"ipaddress"], interval];
        }

        if([[flap valueForKey:@"image"] isKindOfClass:[NSImage class]])
        {
            cell.chartImage.image = [flap valueForKey:@"image"];
        }
        else
        {

        
            NSURL *url = [NSURL URLWithString:urlString];
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
            [req setValue:[self getCredentials] forHTTPHeaderField:@"Authorization"];
            NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                if (data) {
                    NSImage *image = [[NSImage alloc] initWithData:data];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [flap setValue:image forKey:@"image"];
                            cell.chartImage.image = image;
                        });
                    }
                }
            }];

            [task resume];
      }

        
        
        return cell;
    }


    
    
    
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:[colID stringByAppendingString:@"Cell"] owner:self];

    // === HOST ================================================================================================

    if ([colID isEqualToString:@"hostname"])
    {
        
        cell.textField.stringValue = [self getHostnameFromFlap: flap];
        return cell;
    }

    // === INTERFACE ================================================================================================

    if ([colID isEqualToString:@"interface"])
    {
        /*
        NSString *ifName = [flap objectForKey:@"ifName"];
        NSString *ifAlias = [flap objectForKey:@"ifAlias"];

        cell.textField.stringValue = ifName;
        
        if(![ifAlias isKindOfClass:[NSNull class]])
        {
            if (![ifAlias isEqualToString:@""])
            {
                cell.textField.stringValue = [NSString stringWithFormat:@"%@ — %@", ifName, ifAlias];
            }
        }
        */
        
        cell.textField.stringValue = [self getIfNameFromFlap:flap];
        
        // Text color
        if([[flap valueForKey:@"ifOperStatus"] isEqualToString:@"up"])
        {
            cell.textField.textColor = [NSColor colorWithSRGBRed:0.5f green:0.8f blue:0.4f alpha:1.0f];
        }
        else
        {
            cell.textField.textColor = [NSColor colorWithSRGBRed:0.9f green:0.5f blue:0.5f alpha:1.0f];
        }
    }


    // === START DATE ================================================================================================

    
    if ([colID isEqualToString:@"startDate"])
    {
        cell.textField.stringValue = [flap valueForKey:@"firstFlapTime"];
        return cell;
    }

    
    // === END DATE ================================================================================================

    
    if ([colID isEqualToString:@"endDate"])
    {
        cell.textField.stringValue = [flap valueForKey:@"lastFlapTime"];
        return cell;
    }

    
    // === FLAP NUMBER ================================================================================================

    
    if ([colID isEqualToString:@"flapNumber"])
    {
        cell.textField.stringValue = [flap valueForKey:@"flapCount"];
        return cell;
    }
    
    
    // === STATUS ================================================================================================

    if ([colID isEqualToString:@"status"])
    {
        cell.textField.stringValue = [flap valueForKey:@"ifOperStatus"];

        if([[flap valueForKey:@"ifOperStatus"] isEqualToString:@"up"])
        {
            cell.textField.textColor = [NSColor colorWithSRGBRed:0.5f green:0.8f blue:0.4f alpha:1.0f];
        }
        else
        {
            cell.textField.textColor = [NSColor colorWithSRGBRed:0.9f green:0.5f blue:0.5f alpha:1.0f];
        }

        return cell;
    }
    
    
    return cell;


}

#pragma mark - TextField Delegate Methods

- (void)controlTextDidChange:(NSNotification *) obj
{

    if (obj.object == self.filterField)
    {
        [self applyFilterWithString:self.filterField.stringValue];
    }
}

-(void)applyFilterWithString:(NSString*) filterString {
    
    flapListFiltered = [[NSMutableArray alloc] initWithArray:flapList];
    
    if (filterString.length == 0) {
        [self.tableView reloadData];
        return;
    }
    
    NSArray *keyWords = [filterString componentsSeparatedByString:@" "];
    
    NSMutableArray *removingFlaps = [[NSMutableArray alloc] init];
    
    for (NSDictionary *flap in flapListFiltered) {

        // Iterating over the keywords
        for (NSString *keyWord in keyWords) {

            if(!keyWord || keyWord.length == 0) {
                continue;
            }
            
            if([keyWord hasPrefix:@"!"]) {

                // if flap mathes remove it
                NSString *negativeKeyword = [keyWord substringFromIndex:1];
                
                if([[flap objectForKey:@"hostname"] containsString:negativeKeyword]) {
                    [removingFlaps addObject:flap];
                    continue;
                }

                if([[flap objectForKey:@"ifName"] containsString:negativeKeyword]) {
                    [removingFlaps addObject:flap];
                    continue;
                }
                if([[flap objectForKey:@"ifAlias"] containsString:negativeKeyword]) {
                    [removingFlaps addObject:flap];
                    continue;
                }

            } else {

                // if flap doesn't match — remove id
                if([[flap objectForKey:@"hostname"] containsString:keyWord] ||
                   [[flap objectForKey:@"ifName"] containsString:keyWord] ||
                   [[flap objectForKey:@"ifAlias"] containsString:keyWord]) {
                    continue;
                } else {
                    [removingFlaps addObject:flap];
                }
            }
            
        }

    }
    
    for (NSDictionary *removingFlap in removingFlaps) {
        [flapListFiltered removeObject:removingFlap];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Buttons
- (IBAction)showButtonPressed:(NSButton *)sender {
    
    [self disableControls];
    [self updateDates];
    [self requestData];

    
}


- (IBAction)resetButtonPressed:(NSButton *)sender {
    
    [self viewDidLoad];
    
}

- (void) activateTimer
{
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(showButtonPressed:) userInfo:nil repeats:YES];
}

- (void) deactivateTimer
{
    [self.refreshTimer invalidate];
}


#pragma mark - Delegate methods
- (void) refresh: (NSData *) data {
    
    [flapList removeAllObjects];
    [flapListFiltered removeAllObjects];
    
    [[NSApp dockTile] setBadgeLabel:@""];
    
    if(data != nil)
    {
        [flapList removeAllObjects];
        
        NSError *dataError = [NSError alloc];
        
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];

        if(!response)
        {
            
            self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — Wrong data received from server: %@", [self getCurrentTimeString], [dataError localizedDescription] ];
            [self.tableView reloadData];
            [[NSApp dockTile] setBadgeLabel:@"❕"];
            [NSApp requestUserAttention: NSCriticalRequest];
            [[NSSound soundNamed:@"Basso"] play];
            [self enableControls];
            return;
        }
        
        NSArray *hosts = [response objectForKey:@"hosts"];
        NSDictionary *params = [response objectForKey:@"params"];
        
        if(!([params objectForKey:@"oldestFlapID"] == nil))
        {
            oldestFlapID = [[params objectForKey:@"oldestFlapID"] integerValue];
            if (oldestFlapID > lastOldestFlapID)
            {
                [NSApp requestUserAttention:NSCriticalRequest];
                
                NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"linkdown" ofType:@"aif"];
                
                if(resourcePath)
                {
                    NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
                    [sound play];
                }
                
                lastOldestFlapID = oldestFlapID;
            }
        }
        
        for (NSDictionary *host in hosts)
        {
            
            if (host)
            {
                NSString *ipaddress = [host objectForKey:@"ipaddress"];
                
                if(ipaddress)
                {
                    NSArray *ports = [host objectForKey:@"ports"];
                    NSString *ipaddress = [host objectForKey:@"ipaddress"];
                    NSString *hostname = [host objectForKey:@"name"];
                    
                    if([hostname length] == 0) {
                        hostname = ipaddress;
                    }
                    
                    if(ports)
                    {
                        for (NSDictionary *port in ports)
                        {
                            // Object for adding to flapList
                            NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                            
                            [item setObject:ipaddress forKey:@"ipaddress"];
                            
                            [item setObject:hostname forKey:@"hostname"];
                            
                            // ifIndex
                            [item setObject:@"" forKey:@"ifIndex"];
                            NSString *ifIndex = [port objectForKey:@"ifIndex"];
                            if(ifIndex) [item setObject:ifIndex forKey:@"ifIndex"];

                            // ifName
                            [item setObject:@"" forKey:@"ifName"];
                            NSString *ifName = [port objectForKey:@"ifName"];
                            if(ifName) {
                                [item setObject:ifName forKey:@"ifName"];
                                
                                // Replace empty ifName with "ifIndex 1111" value
                                if([ifName length] == 0) {
                                    [item setObject:[@"ifIndex " stringByAppendingString:ifIndex] forKey:@"ifName"];
                                }
                            }

                            // ifAlias
                            [item setObject:@"" forKey:@"ifAlias"];
                            NSString *ifAlias = [port objectForKey:@"ifAlias"];
                            if(ifAlias) [item setObject:ifAlias forKey:@"ifAlias"];

                            // ifOperStatus
                            [item setObject:@"" forKey:@"ifOperStatus"];
                            NSString *ifOperStatus = [port objectForKey:@"ifOperStatus"];
                            if(ifOperStatus) [item setObject:ifOperStatus forKey:@"ifOperStatus"];

                            
                            // flapCount
                            [item setObject:@"" forKey:@"flapCount"];
                            NSString *flapCount = [port objectForKey:@"flapCount"];
                            if(flapCount) [item setObject:flapCount forKey:@"flapCount"];
                            
                            // firstFlapTime
                            [item setObject:@"" forKey:@"firstFlapTime"];
                            NSString *firstFlapTime = [port objectForKey:@"firstFlapTime"];
                            if(firstFlapTime) [item setObject:firstFlapTime forKey:@"firstFlapTime"];
                            
                            // lastFlapTime
                            [item setObject:@"" forKey:@"lastFlapTime"];
                            NSString *lastFlapTime = [port objectForKey:@"lastFlapTime"];
                            if(lastFlapTime) [item setObject:lastFlapTime forKey:@"lastFlapTime"];
                            
                            [flapList addObject:item];
                        }
                        
                    }
                }
            }
        }
    }

    // Copy FlapList to FlapListFiltered
    flapListFiltered = [NSMutableArray arrayWithArray:flapList];
    
    [self.tableView reloadData];
    
    [self enableControls];
    
    if (flapList.count > 0)
    {
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", (long)flapList.count] ];
    }

    
    if(autoRefresh == YES)
    {
        [self activateTimer];
    }
    
    if([flapList count] == 1)
    {
        self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — 1 row", [self getCurrentTimeString]];
    }
    else
    {
        self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — %lu rows", [self getCurrentTimeString], (unsigned long)[flapList count]];
    }
}


- (void) connectionError: (NSError *) error {
    
    self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — Connection error: %@", [self getCurrentTimeString], [error localizedDescription] ];

    [[NSApp dockTile] setBadgeLabel:@"❕"];
    [NSApp requestUserAttention: NSCriticalRequest];
    [[NSSound soundNamed:@"Basso"] play];

    [self enableControls];

    if(autoRefresh == YES)
    {
        [self activateTimer];
    }

}


- (void)copy:(id)sender
{

    NSResponder *firstResponder;
    
    if (firstResponder == nil)
    {
        [self copySelectedRows];
    }

}
@end
