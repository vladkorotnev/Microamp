//
//  MAAppDelegate.h
//  Microamp
//
//  Created by Vladislav Korotnev on 1/20/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>


@interface MAAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDataSource,NSTableViewDelegate,AVAudioPlayerDelegate> {
    NSMutableArray*playerItems;
    AVAudioPlayer * player;
    int curplay;
}
@property (assign) IBOutlet NSTableView *table;


- (IBAction)add:(id)sender;
@property (assign) IBOutlet NSButton *playBt;
- (IBAction)playClick:(id)sender;
- (IBAction)selBelowCur:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *lowerBar;
@property (assign) IBOutlet NSProgressIndicator *wheel;
- (IBAction)volumeSlider:(NSSlider*)sender;
- (IBAction)prevBtn:(id)sender;
- (IBAction)nextBtn:(id)sender;

@property (assign) IBOutlet NSProgressIndicator *higherBar;
@property (assign) IBOutlet NSSlider *vol;

- (IBAction)delsel:(id)sender;

@end
