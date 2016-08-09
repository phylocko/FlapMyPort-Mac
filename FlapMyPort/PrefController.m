//
//  PrefController.m
//  FlapMyPort
//
//  Created by Vladislav Pavkin on 05/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import "PrefController.h"

@interface PrefController () <URLManagerDelegate>
{
    NSUserDefaults  *config;
    URLManager     *myConnection;
}
@end

@implementation PrefController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    myConnection = [[URLManager alloc] init];
    [myConnection createSession];
    
    [self pullData];
}





- (void) refresh: (NSMutableData *) data
{
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    if(response)
    {
        if([[response objectForKey:@"checkResult"] isEqualToString:@"flapmyport"])
        {
            [config setObject:self.urlField.stringValue forKey:@"ApiUrl"];
            [config setObject:self.loginField.stringValue forKey:@"UserLogin"];
            [config setObject:self.passwordField.stringValue forKey:@"UserPassword"];
            [config setObject:self.urlField.stringValue forKey:@"ApiUrl"];
            
            self.statusLabel.stringValue= @"✅";
            self.statusLabel.hidden = NO;

            self.helperText.stringValue = @"This url is a correct url! Stored to config.";
            [self enableControls];
            return;
        }
    }

   
    self.helperText.stringValue = @"Couldn't find API response. Check the URL or your credentials if needed.";
    self.statusLabel.stringValue= @"❗️";
    self.statusLabel.hidden = NO;

    [self enableControls];
}
- (void) connectionError: (NSError *) error
{
    self.helperText.stringValue = @"Couldn't find API response. Check the URL or your credentials if needed.";

    self.statusLabel.stringValue= @"❗️";
    self.statusLabel.hidden = NO;

    [self enableControls];
}



- (IBAction)ApplyClick:(id)sender {
    
    [self disableControls];
    
    self.statusLabel.stringValue = @"";
    
    if([self urlCorrect])
    {
        NSString *url = [NSString stringWithFormat:@"%@/?check", self.urlField.stringValue];

        myConnection.delegate = self;
        myConnection.UserLogin = self.loginField.stringValue;
        myConnection.UserPassword = self.passwordField.stringValue;

        [myConnection getURL:url];
        
    }
}

- (void) disableControls
{
    self.applyButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.statusLabel.hidden = YES;
    
    self.progressIndicator.hidden = NO;
    [self.progressIndicator startAnimation:0];
}
- (void) enableControls
{
    self.applyButton.enabled = YES;
    self.cancelButton.enabled = YES;
    
    [self.progressIndicator stopAnimation:0];
    self.progressIndicator.hidden = YES;
}

- (IBAction)CancelClick:(id)sender {

    [self.view.window close];

}

- (void) pullData
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
    
    self.loginField.stringValue = [config valueForKey:@"UserLogin"];
    self.passwordField.stringValue = [config valueForKey:@"UserPassword"];
    self.urlField.stringValue = [config valueForKey:@"ApiUrl"];
}

- (BOOL) urlCorrect
{
    return YES;
}

@end
