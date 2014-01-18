
/*  DebugPref.h  *  Debug
    Created by Timothy Perfitt on 11/6/09. Cpyright (c) 2013 twocanoes. All rights reserved. */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#include <string.h>

@interface DebugPref : NSPreferencePane

@property IBOutlet SFAuthorizationView * lockView;
@property             AuthorizationRef   authorization;

@property BOOL hasUnappledChanges, isTracingKerberos, isDoingNetworkTrace, isDSDebugging,
               isTracingLDAP, isEnabled, isLoggingDNS, isTracingDNS, isSyslogDebug;

- (IBAction)                    apply:(id)x;
- (IBAction)            optionChanged:(id)x;
- (IBAction)                   revert:(id)x;
- (IBAction) compressAndSendToDesktop:(id)x;
-     (void) mainViewDidLoad;
-     (void) save;
-     (void) setDefaults;
@end
