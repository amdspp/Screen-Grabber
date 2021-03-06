//
//  FOPreviewDocument.m
//  ScreenGrabber
//
//  Copyright 2006-2011 Fredrik Olsson. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FOPreviewDocument.h"


@interface FOPreviewDocument (Private)

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSString *)windowNibName;
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController;

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)error;

- (void)screenGrabberWillCaptureImages:(FOScreenGrabber *)screenGrabber;
- (void)screenGrabber:(FOScreenGrabber *)screenGrabber processingPercentDone:(float)percentDone;
- (void)screenGrabberDidCaptureImages:(FOScreenGrabber *)screenGrabber;
- (void)screenGrabber:(FOScreenGrabber *)screenGrabber error:(NSError *)error;

@end



@implementation FOPreviewDocument

- (FOScreenGrabber *)screenGrabber
{
    return _screenGrabber;
}

- (IBAction)captureImages:(id)sender;
{
    [_screenGrabber captureImages:sender];
}


- (IBAction)captureImagesAs:(id)sender;
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpeg", @"png", nil]];
    [panel setCanCreateDirectories:YES];
    [panel setCanSelectHiddenExtension:YES];
    NSString *dir = [[[_screenGrabber imageURL] path] stringByDeletingLastPathComponent];
    NSString *name = [[[_screenGrabber imageURL] path] lastPathComponent];
    [panel beginSheetForDirectory:dir file:name modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


@end



@implementation FOPreviewDocument (Private)

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    if (returnCode == NSOKButton) {
        [_screenGrabber setImageURL:[sheet URL]];
        [_screenGrabber captureImages:self];
    }
}


- (NSString *)windowNibName
{
    return @"PreviewDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    [progressIndicator setUsesThreadedAnimation:YES];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)error
{
    [self willChangeValueForKey:@"screenGrabber"];
    _screenGrabber = [[FOScreenGrabber alloc] initWithURL:url error:error];
    if (_screenGrabber) {
        [_screenGrabber setDelegate:self];
    }
    [self didChangeValueForKey:@"screenGrabber"];
    return _screenGrabber != nil;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)error
{
    [_screenGrabber setImageURL:url];
    // Stupid QTKit is not threadsafe...
    [_screenGrabber captureImagesInThread:nil];
    return YES;
}

- (void)screenGrabberWillCaptureImages:(FOScreenGrabber *)screenGrabber
{
    [NSApp beginSheet:progressSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)screenGrabber:(FOScreenGrabber *)screenGrabber processingPercentDone:(float)percentDone
{
    [progressIndicator setDoubleValue:percentDone];
}

- (void)screenGrabberDidCaptureImages:(FOScreenGrabber *)screenGrabber 
{
    [screenGrabber saveImage:self];
    [NSApp endSheet:progressSheet];
    [progressSheet orderOut:self];
}

- (void)screenGrabber:(FOScreenGrabber *)screenGrabber error:(NSError *)error
{ 
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

@end
