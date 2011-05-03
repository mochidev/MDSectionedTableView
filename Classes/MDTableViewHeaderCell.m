//
//  MDTableViewHeaderCell.m
//  MDSectionedTableView
//
//  Created by Dimitri Bouniol on 5/1/11.
//  Copyright 2011 Mochi Development, Inc. All rights reserved.
//  
//  Copyright (c) 2011 Dimitri Bouniol, Mochi Development, Inc.
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//  
//  Mochi Dev, and the Mochi Development logo are copyright Mochi Development, Inc.
//  
//  Also, it'd be super awesome if you credited this page in your about screen :)
//  

#import "MDTableViewHeaderCell.h"


@implementation MDTableViewHeaderCell

- (id)initWithReuseIdentifier:(NSString *)anIdentifier
{
    if ((self = [super initWithReuseIdentifier:anIdentifier])) {
        backgroundView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, [self bounds].size.width, 19)];
        [backgroundView setImageScaling:NSImageScaleAxesIndependently];
        [backgroundView setAutoresizingMask:NSViewWidthSizable];
        [backgroundView setImage:[NSImage imageNamed:@"TableHeader.png"]];
        [self addSubview:backgroundView positioned:NSWindowBelow relativeTo:nil];
        [backgroundView release];
        
        NSRect textFieldFrame = NSMakeRect(10, 2, [self bounds].size.width-20, 16);
        [textField setFrame:textFieldFrame];
        [textField setTextColor:[NSColor colorWithCalibratedWhite:0.3 alpha:1]];
        [textField setFont:[NSFont boldSystemFontOfSize:12]];
        
        textFieldFrame.origin.y -= 1;
        
        shadowTextField = [[NSTextField alloc] initWithFrame:textFieldFrame];
        [shadowTextField setAutoresizingMask:NSViewWidthSizable];
        [shadowTextField setEditable:NO];
        [shadowTextField setSelectable:NO];
        [shadowTextField setDrawsBackground:NO];
        [shadowTextField setBezeled:NO];
        [shadowTextField setTextColor:[NSColor colorWithCalibratedWhite:1 alpha:0.5]];
        [shadowTextField setFont:[NSFont boldSystemFontOfSize:12]];
        [self addSubview:shadowTextField positioned:NSWindowBelow relativeTo:textField];
        [shadowTextField release];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [shadowTextField setStringValue:text];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // override and draw nothing, for transparent background
}

- (NSRect)frameAdjustments
{
    return NSMakeRect(0, 0, 0, 1);
}

- (void)dealloc
{
    [super dealloc];
}

@end
