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

@interface FlapTableViewController () <URLManagerDelegate>
{
    NSMutableArray	*flapList;
    URLManager		*myConnection;
    unsigned long   eldestFlapAtLastUpdate;

    NSDate          *startDate;
    NSDate          *endDate;
    NSString        *interval;
    NSString        *filter;
    NSArray         *WorkModes;
    NSString        *WorkMode; // Will be @"1MIN", ,@"10MINS", @"1HOUR", @"1HOUR", @"MANUAL"
    BOOL            autoRefresh;
    NSNumber        *oldestFlapID;
    NSNumber        *lastOldestFlapID;
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
    
    WorkModes = @[@"1MIN" ,@"10MIN", @"1HOUR", @"INTERVAL", @"FROM"];
    
    [self changeWorkMode:2];
    
    [super viewDidLoad];
    
    
    [self updateContols];

    
    
    [self pullConfig];
    
    
    flapList = [[NSMutableArray alloc] init];
    
    //myConnection = [FlapManager sharedInstance];

    //myConnection.delegate = self;
    
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
    self.showOnlyDown.enabled = NO;
    self.filterField.enabled = NO;
    self.modeSelector.enabled = NO;
    self.startDatePicker.enabled = NO;
    self.endDatePicker.enabled = NO;

}

- (void) enableControls
{
    self.showButton.enabled = YES;
    self.showOnlyDown.enabled = YES;
    self.filterField.enabled = YES;
    self.modeSelector.enabled = YES;
    self.startDatePicker.enabled = YES;
    self.endDatePicker.enabled = YES;
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

- (void) pullConfig
{
    config = [NSUserDefaults standardUserDefaults];
    
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

- (BOOL) noUrl
{
    return [[config valueForKey:@"ApiUrl"] isEqualToString:@""];
}
- (void) noUrlError
{
    self.bottomLabel.stringValue = @"You have no URL configured. Please open Preferences and type the URL.";
    [self enableControls];
    
}

- (void) requestData // Asks FlaFlapManager to request the url and call my appropriate method
{
    [self pullConfig];

    [self deactivateTimer];
    
    if ([self noUrl])
    {
        [self noUrlError];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"You have no URL configured. Please open Preferences and type the URL."]];
        [alert runModal];
        return;
    }
    
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
    //myConnection.UserLogin = UserLogin;
    //myConnection.UserPassword = UserPassword;

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
    
    NSString *url = [NSString stringWithFormat:@"%@/?review&interval=%@&filter=%@", ApiUrl, interval, self.filterField.stringValue];

    return url;
}

- (NSString *) prepareUrlWithDates
{
    NSDateFormatter *txtFormat = [[NSDateFormatter alloc] init];
    [txtFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *url = [NSString stringWithFormat:@"%@/?review&start=%@&end=%@&filter=%@", ApiUrl, [txtFormat stringFromDate:startDate], [txtFormat stringFromDate:endDate], self.filterField.stringValue];

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



#pragma mark - TableView Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return flapList.count;
    return 0;
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{

    NSDictionary *flap = [flapList objectAtIndex:row];

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

 
        
        NSURL *url = [NSURL URLWithString:urlString];
        

        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [req setValue:[self getCredentials] forHTTPHeaderField:@"Authorization"];

        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (data) {
                NSImage *image = [[NSImage alloc] initWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.chartImage.image = image;
                    });
                }
            }
        }];
        [task resume];

        return cell;
    }


    
    
    
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:[colID stringByAppendingString:@"Cell"] owner:self];

    // === HOST ================================================================================================

    if ([colID isEqualToString:@"hostname"])
    {
        NSString *ipaddress = [flap objectForKey:@"ipaddress"];
        NSString *hostname = [flap objectForKey:@"hostname"];

        cell.textField.stringValue = hostname;
        if([hostname isKindOfClass:[NSNull class]]) cell.textField.stringValue = ipaddress;
        return cell;
    }

    // === INTERFACE ================================================================================================

    if ([colID isEqualToString:@"interface"])
    {
        NSString *ifName = [flap objectForKey:@"ifName"];
        NSString *ifAlias = [flap objectForKey:@"ifAlias"];

        cell.textField.stringValue = ifName;
        
        if(![ifAlias isKindOfClass:[NSNull class]])
        {
            if (![ifAlias isEqualToString:@""])
            {
                cell.textField.stringValue = [NSString stringWithFormat:@"%@ — \t%@", ifName, ifAlias];
            }
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

        if( [[flap valueForKey:@"ifOperStatus"] isEqualToString:@""] )
        {

            if([[flap valueForKey:@"ifOperStatus"] isEqualToString:@"up"])
            {
                cell.textField.textColor = [NSColor colorWithSRGBRed:0.5f green:0.8f blue:0.4f alpha:1.0f];
            }
            else
            {
                cell.textField.textColor = [NSColor colorWithSRGBRed:0.9f green:0.5f blue:0.5f alpha:1.0f];
            }
        }
        
        return cell;
    }
    
    
    return cell;


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
    
    [[NSApp dockTile] setBadgeLabel:@""];
    
    if(data != nil)
    {
        [flapList removeAllObjects];
        
        NSError *dataError = [NSError alloc];
        
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];

        if(!response)
        {
            self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — Wrong data received from server: %@", [self getCurrentTimeString], dataError];
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
            oldestFlapID = [params objectForKey:@"oldestFlapID"];
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
                    
                    if(!ipaddress)
                    {
                        ipaddress = @"";
                    }
                    
                    if(!hostname)
                    {
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
                            
                            // ifAlias
                            [item setObject:@"" forKey:@"ifAlias"];
                            NSString *ifAlias = [port objectForKey:@"ifAlias"];
                            if(ifAlias) [item setObject:ifAlias forKey:@"ifAlias"];

                            
                            // ifName
                            [item setObject:@"" forKey:@"ifName"];
                            NSString *ifName = [port objectForKey:@"ifName"];
                            if(ifName) [item setObject:ifName forKey:@"ifName"];

                            
                            // ifOperStatus
                            [item setObject:@"" forKey:@"ifOperStatus"];
                            NSString *ifOperStatus = [port objectForKey:@"ifOperStatus"];
                            if(ifOperStatus) [item setObject:ifOperStatus forKey:@"ifOperStatus"];

                            
                            // ifIndex
                            [item setObject:@"" forKey:@"ifIndex"];
                            NSString *ifIndex = [port objectForKey:@"ifIndex"];
                            if(ifIndex) [item setObject:ifIndex forKey:@"ifIndex"];

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
    
    [self.tableView reloadData];
    
    [self enableControls];
    
    if([oldestFlapID integerValue] > [lastOldestFlapID integerValue])
    {
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", (unsigned long)[flapList count]]];
        [NSApp requestUserAttention:NSCriticalRequest];
        
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"linkdown" ofType:@"aif"];
        
        if(resourcePath)
        {
            NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
            [sound play];
        }
    }
    
    lastOldestFlapID = oldestFlapID;

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
    
    NSString *myError = [error domain];

    self.bottomLabel.stringValue = [NSString stringWithFormat:@"%@ — Connection error: %@", [self getCurrentTimeString], myError];
    
    [[NSApp dockTile] setBadgeLabel:@"❕"];
    [NSApp requestUserAttention: NSCriticalRequest];
    [[NSSound soundNamed:@"Basso"] play];
    
    [self enableControls];
    
    if(autoRefresh == YES)
    {
        [self activateTimer];
    }
  
}

@end
