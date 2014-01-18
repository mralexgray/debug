
/*  DebugPref.m  *  Debug
    Created by Timothy Perfitt on 11/6/09. Cpyright (c) 2013 twocanoes. All rights reserved. */

#import "DebugPref.h"

#define fm [NSFileManager defaultManager]

@implementation DebugPref

@synthesize hasUnappledChanges, isTracingKerberos, isDoingNetworkTrace, isDSDebugging,
            isTracingLDAP, isEnabled, isLoggingDNS, isTracingDNS, isSyslogDebug;

- (IBAction) compressAndSendToDesktop:(id)sender {  NSTask *task = NSTask.new;

  [task setLaunchPath:@"/usr/bin/zip"];
  [task setArguments:@[@"-r",@"~/Desktop/debug.zip".stringByExpandingTildeInPath, @"/Library/Logs",@"/var/log"]];
  [task launch];
  [task waitUntilExit];
}

- (NSString*) interface{ return [NSUserDefaults.standardUserDefaults valueForKey:@"interface"]; }

- (void) setDefaults { // [self setInterface:@"en0"];

  [self setHasUnappledChanges:NO];
  [self setIsEnabled:           [fm fileExistsAtPath:@"/Library/LaunchDaemons/com.twocanoes.debug.plist"]];
  [self setIsDSDebugging:       [fm fileExistsAtPath:@"/Library/Preferences/DirectoryService/.DSLogDebugAtStart"]];
  [self setIsLoggingDNS:        [fm fileExistsAtPath:@"/tmp/.dnsdebugging"]];
  [self setIsSyslogDebug:       [fm fileExistsAtPath:@"/tmp/.syslogverbose"]];
  [self setIsDoingNetworkTrace: [fm fileExistsAtPath:@"/tmp/.tcpdumprunning"]];
  [self setIsTracingDNS:        [fm fileExistsAtPath:@"/tmp/.tracedns"]];
  [self setIsTracingKerberos:   [fm fileExistsAtPath:@"/tmp/.tracekerberos"]];
  [self setIsTracingLDAP:       [fm fileExistsAtPath:@"/tmp/.traceldap"]];
}

- (void) mainViewDidLoad {

  [_lockView setDelegate:self];
  [_lockView setString:"system.privilege.admin"];
  [_lockView setAutoupdate:YES];
  [_lockView updateStatus:self];
  _authorization = nil;
  [self setDefaults];
}
- (IBAction) apply:(id)sender{ [self save]; }
- (void) save {

  _authorization = _lockView.authorization.authorizationRef;

  NSString    * scriptPath = [[NSBundle bundleForClass:self.class] pathForResource:@"debug" ofType:@"perl"];
  const char  * pathToTool = scriptPath.UTF8String;
  AuthorizationFlags flags = kAuthorizationFlagDefaults     | kAuthorizationFlagInteractionAllowed |
                             kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
  int curArg = 2;
  char **arguments = calloc(10 , sizeof(char*));

  if (self.isEnabled) {

    if (self.isDSDebugging) {
      NSLog(@"adding ds at %i",curArg);
      arguments[curArg++] = "-ds";
    }
    if (self.isDoingNetworkTrace) {
      NSMutableArray *ports = NSMutableArray.new;
      arguments[curArg++] = "-tcpdump";
      arguments[curArg++] = (char *)[[self interface] UTF8String];
      [fm createFileAtPath:@"/tmp/.tracedns" contents:nil attributes:nil];
      [ports addObject:@"port 53"];
      [ports addObject:@"port 5353"];
      [ports addObject:@"port 464"];
      [ports addObject:@"port 88"];
      [ports addObject:@"port 389"];
      [ports addObject:@"port 636"];

      if (ports.count) {
            arguments[curArg++] = "-ports";
        NSString *optionsObject = [ports componentsJoinedByString:@" or "];
        char           *options = calloc([optionsObject length]+1, sizeof (char));
        strncpy(options,(char*)optionsObject.UTF8String,sizeof(char)*(optionsObject.length + 1));
        arguments[curArg++] = options;
      }
    }
    if (self.isLoggingDNS)  arguments[curArg++] = "-dns";
    if (self.isSyslogDebug) arguments[curArg++] = "-syslog";
  }

  if (curArg == 2) arguments[curArg++] = "-disable";

  // either disabled or nothing selected
  AuthorizationItem    right = {kAuthorizationRightExecute, 0, NULL, 0};
  AuthorizationRights rights = {1, &right};

  // Call AuthorizationCopyRights to determine or extend the allowable rights.
  OSStatus status = AuthorizationCopyRights(_authorization, &rights, NULL, flags, NULL);
  if (status != errAuthorizationSuccess) NSLog(@"Copy Rights Unsuccessful: %d", status);

  NSLog(@"path is %s",pathToTool);
  arguments[0] = (char *)pathToTool;
  arguments[1] = "-install";
  for (int i = 0; i < curArg; i++) NSLog(@"arg[%i] is %s",i,arguments[i]);

  status = AuthorizationExecuteWithPrivileges ( _authorization, "/usr/bin/perl",
                                             kAuthorizationFlagDefaults, arguments, nil);
  if (status !=  errAuthorizationSuccess)
    NSLog(@"AuthorizationExecuteWithPrivileges Unsuccessful: %d", status);

  [self setHasUnappledChanges:NO];
  /*   NSRunInformationalAlertPanel(@"Restart Required",
   @"Logging will now take affect on restart.",
   @"OK",  nil,nil);
   */
}
- (IBAction) optionChanged:(id)sender{ [self setHasUnappledChanges:YES]; }
- (IBAction)        revert:(id)sender{ [self setDefaults]; }

@end
