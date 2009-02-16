//
//  KOAuthorAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-2-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOAuthorAreaHotspotHandler.h"
#import "KOMouseBehaviorManager.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "KOEffectView.h"

NSString *const KOButtonNameAuthorMode = @"Author: %@";
NSString *const KOCommandSequenceAuthorMode = @"\07""5\n""%@\n";

@implementation KOAuthorAreaHotspotHandler

#pragma mark -
#pragma mark Event Handle
- (void) mouseUp: (NSEvent *)theEvent {
	NSString *author = [_manager.activeTrackingAreaUserInfo objectForKey:KOMouseAuthorUserInfoName];
	if (author == nil) {
		return;
	}
	NSString *commandSequence = [NSString stringWithFormat:KOCommandSequenceAuthorMode, author];
	[_view sendText:commandSequence];
}

- (void) mouseEntered: (NSEvent *)theEvent {
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	NSString *buttonTitle = [NSString stringWithFormat:NSLocalizedString(KOButtonNameAuthorMode, @"Mouse Button"), [userInfo objectForKey:KOMouseAuthorUserInfoName]];
	[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage: buttonTitle];
	_manager.activeTrackingAreaUserInfo = userInfo;
}

- (void) mouseExited: (NSEvent *)theEvent {
	[[_view effectView] clearButton];
	_manager.activeTrackingAreaUserInfo = nil;
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[[NSCursor arrowCursor] set];
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Update State
BOOL isLetter(unsigned char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c<= 'Z'); }
BOOL isNumber(unsigned char c) { return (c >= '0' && c <= '9'); }

- (void) addAuthorArea: (NSString *)author 
				   row: (int)row 
				column: (int)column 
				length: (int)length {
	NSRect rect = [_view rectAtRow:row column:column height:1 width:length];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseAuthorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, author, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	// Add into manager
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: [NSCursor pointingHandCursor]];	
}

- (void) updateAuthorAreaForRow: (int)r {
	YLTerminal *ds = [_view frontMostTerminal];
    cell *currRow = [ds cellsOfRow:r];
	
	if ([ds bbsState].state == BBSBrowseBoard || [ds bbsState].state == BBSMailList) {
        // browsing a board
		// header/footer
		if (r < 3 || r == _maxRow - 1)
			return;
		
		int start = -1, end = -1;
		unichar textBuf[_maxColumn + 1];
		int bufLength = 0;
		
        // don't check the first two columns ("●" may be used as cursor)
        for (int i = 2; i < _maxColumn - 1; ++i) {
			int db = currRow[i].attr.f.doubleByte;
			if (db == 0) {
                if (start == -1) {
                    if (isLetter(currRow[i].byte))
                        start = i;
                }
				if (isLetter(currRow[i].byte) || isNumber(currRow[i].byte))
					end = i;
				else if (start != -1)
					break;
                if (start != -1)
                    textBuf[bufLength++] = 0x0000 + (currRow[i].byte ?: ' ');
            } else if (db == 2) {
				if (start != -1)
					break;
			}
		}
		
		if (start == -1)
			return;
		
		[self addAuthorArea: [NSString stringWithCharacters:textBuf length:bufLength]
						row: r
					 column: start
					 length: end - start + 1];
		
	}
}

- (void) update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	for (int r = 0; r < _maxRow; ++r) {
		[self updateAuthorAreaForRow:r];
	}
}

@end
