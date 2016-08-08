//
//  CheckBoxTableCell.h
//  FlapMyPort
//
//  Created by Vladislav Pavkin on 05/08/16.
//  Copyright © 2016 Vladislav Pavkin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CheckBoxTableCell : NSTableCellView

@property (weak) IBOutlet NSButton *PausedCheckBox;

- (IBAction)CheckBoxClick:(NSButton *)sender;


@end
