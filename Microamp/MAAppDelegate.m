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
#import <IOKit/hidsystem/ev_keymap.h>
@implementation MAAppDelegate

- (void)mediaKeyEvent: (int)key state: (BOOL)state repeat: (BOOL)repeat
{
	switch( key )
	{
		case NX_KEYTYPE_PLAY:
			if( state == 0 ){
                if (self.playBt.state == 1) self.playBt.state = 0; else self.playBt.state = 1;
                [self playPause]; 
            }
            //Play pressed and released
            return;
            break;
            
		case NX_KEYTYPE_NEXT:
			if( state == 0 )
				[self nextBtn:nil]; //Next pressed and released
            return;
            break;
            
		case NX_KEYTYPE_PREVIOUS:
			if( state == 0 )
				[self prevBtn:nil]; //Previous pressed and released
            return;
            break;
	}
}

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
           // NSLog(@"Val %f",([player averagePowerForChannel:0]*100)/4);
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
-(void)playPause {
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
        NSDockTile *dockTile = [NSApp dockTile];
        [dockTile setBadgeLabel:[NSString stringWithFormat:@"%d",curplay+1]];
        
    }
    [self.table reloadData];
}
- (IBAction)playClick:(id)sender {
    [self playPause];
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

- (IBAction)delsel:(id)sender {
    if(self.table.selectedRow == playerItems.count || self.table.selectedRow < 0) return;
    if(curplay > self.table.selectedRow) curplay--;
    [playerItems removeObjectAtIndex:self.table.selectedRow];
    if(playerItems.count==0)
    {
        curplay = -1;
        [self.playBt setState:0];
        [[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"stop" withExtension:@"wav"] error:nil]play];
        [player pause];
        player = [[AVAudioPlayer alloc]initWithContentsOfURL:nil error:nil];
    }
    
    if ([self.table selectedRow] == curplay) {
         [self _playNextSong];
    }
       
    [self.table reloadData];
}
@end
