//
//  MAAppDelegate.m
//  Microamp
//
//  Created by Vladislav Korotnev on 1/20/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "MAAppDelegate.h"
@implementation NSMutableArray(Plist)

-(BOOL)writeToTapeFile:(NSURL*)filename{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    BOOL didWriteSuccessfull = [data writeToURL:filename atomically:YES];
    return didWriteSuccessfull;
}

+(NSMutableArray*)readFromTapeFile:(NSURL*)filename{
    NSData * data = [NSData dataWithContentsOfURL:filename];
    return  [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
}

@end //needs to be set for implementation
@implementation MAAppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    curplay = -1;
  
    [self.table setDelegate:self];
    [self.table setDataSource:self];
    playerItems = [NSMutableArray new];
    [self.table setDoubleAction:@selector(_dbClickRow)];
    [self _meters];
}

- (IBAction)add:(id)sender {
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"mp3",@"wav",@"m4a",nil]];
    if ([openPanel runModal] == NSOKButton)
    {
        for (NSURL *u in [openPanel URLs]) {
            [playerItems addObject:u];
            [playerItems retain];
        }
        
       
        [self.table reloadData];
    }
 

}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [playerItems count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSCell *hdr = tableColumn.headerCell;
    if ([hdr.title isEqualToString:@""]) {
        return (row == curplay)? @"√" : @"";
    } else {
        NSURL *u = [playerItems objectAtIndex:row];
        return [u lastPathComponent];
    }
}
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return NO;
}
-(void)_meters {
    if (player) {
        if([player isPlaying]){
          //  NSLog(@"%f",[player averagePowerForChannel:1]);
            [player updateMeters];
            [self.lowerBar setDoubleValue:([player averagePowerForChannel:0]*100)/4];
            [self.higherBar setDoubleValue:([player averagePowerForChannel:1]*100)/4];
       
            [self.wheel setMaxValue:[player duration]];
            [self.wheel setDoubleValue:[player currentTime]];
        }
    }
    [self performSelector:@selector(_meters) withObject:nil afterDelay:0.02];
}
-(void)_dbClickRow {
    curplay = [self.table clickedRow];
    [self _playNextSong];
    
}
-(void)_playNextSong {
    [self.playBt setState:1];
    NSDockTile *dockTile = [NSApp dockTile];
    [dockTile setBadgeLabel:[NSString stringWithFormat:@"%d",curplay+1]];
    [player release];
    player = nil;
    player = [[AVAudioPlayer alloc]initWithContentsOfURL:[playerItems objectAtIndex:curplay] error:nil];
    [player setDelegate:self];
    [player setMeteringEnabled:true];
    [ player setVolume:self.vol.floatValue];
    [player play];
    [self.table reloadData];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)playr successfully:(BOOL)flag{
    if (curplay != [playerItems count]-1) {
        curplay++;
        [self _playNextSong];
        
    } else {
        curplay = -1;
        [self.playBt setState:0];
    }
     [self.table reloadData];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)playr error:(NSError *)error{
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText:@"Some error"];
    [msgBox setInformativeText:[error localizedDescription]];
    [msgBox addButtonWithTitle: @"OK"];
    [msgBox runModal];
}

- (IBAction)playClick:(id)sender {
    if((curplay < 0) || (curplay >= [playerItems count])) curplay=0;
       
    if (player == nil) 
        player = [[AVAudioPlayer alloc]initWithContentsOfURL:[playerItems objectAtIndex:curplay] error:nil];
    [player setDelegate:self];
[player setMeteringEnabled:true];
    if (self.playBt.state == 0) {
        [[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"stop" withExtension:@"wav"] error:nil]play];
        [player pause];
    }
    else {
        [[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"play" withExtension:@"wav"] error:nil]play];
        [player play];
    [ player setVolume:self.vol.floatValue];
    }
    [self.table reloadData];
}

- (IBAction)selBelowCur:(id)sender {
    
    [playerItems insertObject:[playerItems objectAtIndex:self.table.selectedRow] atIndex:(curplay+1)];
    [playerItems removeObjectAtIndex:self.table.selectedRow+1 ];
    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:(curplay+1)] byExtendingSelection:NO];
    [self.table reloadData];
    
}
- (IBAction)volumeSlider:(NSSlider*)sender {
    if(player)
      [ player setVolume:self.vol.floatValue];
}

- (IBAction)prevBtn:(id)sender {
    if (curplay != 0) {
        curplay--;
        [self _playNextSong];
    }
    [self.table reloadData];
}

- (IBAction)nextBtn:(id)sender {
    if (curplay != [playerItems count]-1) {
        curplay++;
        [self _playNextSong];
    }
    [self.table reloadData];
}

@end
