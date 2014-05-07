//
//  GBCommandLineParser.m
//  GBCli
//
//  Created by Tomaž Kragelj on 3/12/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

#import <getopt.h>
#import "GBCommandLineParser.h"

const struct GBCommandLineKeys {
	__unsafe_unretained NSString *longOption;
	__unsafe_unretained NSString *shortOption;
	__unsafe_unretained NSString *requirement;
	__unsafe_unretained id notAnOption;
} GBCommandLineKeys = {
	.longOption = @"long",
	.shortOption = @"short",
	.requirement = @"requirement",
	.notAnOption = @"not-an-option",
};

#pragma mark -

@interface GBCommandLineParser ()
- (NSDictionary *)optionDataForOption:(NSString *)shortOrLongName value:(NSString **)value;
- (BOOL)isShortOrLongOptionName:(NSString *)value;
@property (nonatomic, strong) NSMutableDictionary *parsedOptions;
@property (nonatomic, strong) NSMutableArray *parsedArguments;
@property (nonatomic, strong) NSMutableDictionary *registeredOptionsByLongNames;
@property (nonatomic, strong) NSMutableDictionary *registeredOptionsByShortNames;
@end

#pragma mark -

@implementation GBCommandLineParser

@synthesize parsedOptions;
@synthesize parsedArguments;
@synthesize registeredOptionsByLongNames;
@synthesize registeredOptionsByShortNames;

#pragma mark - Initialization & disposal

- (id)init {
	self = [super init];
	if (self) {
		self.registeredOptionsByLongNames = [NSMutableDictionary dictionary];
		self.registeredOptionsByShortNames = [NSMutableDictionary dictionary];
		self.parsedOptions = [NSMutableDictionary dictionary];
		self.parsedArguments = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Options registration

- (void)registerOption:(NSString *)longOption shortcut:(char)shortOption requirement:(GBValueRequirements)requirement {
	// Register option data.
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:longOption forKey:GBCommandLineKeys.longOption];
	[data setObject:[NSNumber numberWithUnsignedInteger:requirement] forKey:GBCommandLineKeys.requirement];
	if (shortOption > 0) {
		[data setObject:[NSNumber numberWithInt:shortOption] forKey:GBCommandLineKeys.shortOption];
		[self.registeredOptionsByShortNames setObject:data forKey:[NSString stringWithFormat:@"%c", shortOption]];
	}
	[self.registeredOptionsByLongNames setObject:data forKey:longOption];

	// If this is a swich, register negative form (i.e. if the option is named --option, negative form is --no-option). Note that negative form doesn't use short code!
	if (requirement == GBValueNone) {		
		NSMutableDictionary *negData = [NSMutableDictionary dictionary];
		NSString *negLongOption = [NSString stringWithFormat:@"no-%@", longOption];
		[negData setObject:negLongOption forKey:GBCommandLineKeys.longOption];
		[negData setObject:[NSNumber numberWithUnsignedInteger:requirement] forKey:GBCommandLineKeys.requirement];
		[self.registeredOptionsByLongNames setObject:data forKey:negLongOption];
	}
}

- (void)registerOption:(NSString *)longOption requirement:(GBValueRequirements)requirement {
	[self registerOption:longOption shortcut:0 requirement:requirement];
}

- (void)registerSwitch:(NSString *)longOption shortcut:(char)shortOption {
	[self registerOption:longOption shortcut:shortOption requirement:GBValueNone];
}

- (void)registerSwitch:(NSString *)longOption {
	[self registerSwitch:longOption shortcut:0];
}

#pragma mark - Options parsing

- (BOOL)parseOptionsUsingDefaultArgumentsWithBlock:(GBCommandLineParseBlock)handler {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *command = [processInfo processName];
    NSMutableArray *arguments = [[processInfo arguments] mutableCopy];
	[arguments removeObjectAtIndex:0];
	return [self parseOptionsWithArguments:arguments commandLine:command block:handler];
}

- (BOOL)parseOptionsWithArguments:(char **)argv count:(int)argc block:(GBCommandLineParseBlock)handler {
	if (argc == 0) return YES;
	NSString *command = [NSString stringWithUTF8String:argv[0]];
	NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argc - 1];
	for (int i=1; i<argc; i++) {
		NSString *argument = [NSString stringWithUTF8String:argv[i]];
		[arguments addObject:argument];
	}
	return [self parseOptionsWithArguments:arguments commandLine:command block:handler];
}

- (BOOL)parseOptionsWithArguments:(NSArray *)arguments commandLine:(NSString *)cmd block:(GBCommandLineParseBlock)handler {
	// Cleanup in case parsing is invoked multiple times.
	[self.parsedOptions removeAllObjects];
	[self.parsedArguments removeAllObjects];

	BOOL result = YES;
	BOOL stop = NO;
	
	// Parse options (options start with -- or -).
	NSUInteger index = 0;
	while (index < arguments.count) {
		id value = nil;
		NSString *input = [arguments objectAtIndex:index];
		NSDictionary *data = [self optionDataForOption:input value:&value];
		if (data == GBCommandLineKeys.notAnOption) break; // no more options, only arguments left...
		
		NSString *name = [data valueForKey:GBCommandLineKeys.longOption];
		GBParseFlags flags = GBParseFlagOption;
		
		if (data == nil) {
			// If no registered option matches given one, notify observer.
			name = input;
			flags = GBParseFlagUnknownOption;
			result = NO;
		} else {
			// Prepare the value or notify about problem with it.
			GBValueRequirements requirement = [[data objectForKey:GBCommandLineKeys.requirement] unsignedIntegerValue];
			switch (requirement) {
				case GBValueRequired:
					// Option requires value: check next option and if it "looks like" an option (i.e. starts with -- or -), notify about missing value. Also notify about missing value if this is the last option. If we already have the value (via --name=value syntax), no need to search.
					if (!value) {
						if (index < arguments.count - 1) {
							value = [arguments objectAtIndex:index + 1];
							if ([self isShortOrLongOptionName:value]) {
								flags = GBParseFlagMissingValue;
							} else {
								index++;
							}
						} else {
							flags = GBParseFlagMissingValue;
						}
					}
					break;
				case GBValueOptional:
					// Options can have optional value: check next option and if it "looks like" a value (i.e. doens't start with -- or -), use it. Otherwie assume YES (the same if there's no more option). If we already have the value (via --name=value syntax), no need to search.
					if (!value) {
						if (index < arguments.count - 1) {
							value = [arguments objectAtIndex:index + 1];
							if ([self isShortOrLongOptionName:value]) {
								value = [NSNumber numberWithInt:YES];
							} else {
								index++;
							}
						} else {
							value = [NSNumber numberWithInt:YES];
						}
					}
					break;
				default:
					// Option is a boolean "switch": return either YES or NO, depending on the switch name (--option or --no-option). Note that we always report positive option name (we only use negative form internally)! If we already have a valud (via --name=value syntax), convert value to boolean.
					if ([input hasPrefix:@"--no-"]) {
						if (value) {
							BOOL cmdLineValue = [value boolValue];
							value = [NSNumber numberWithBool:!cmdLineValue];
						} else {
							value = [NSNumber numberWithBool:NO];
						}
					} else {
						if (value) {
							BOOL cmdLineValue = [value boolValue];
							value = [NSNumber numberWithBool:cmdLineValue];
						} else {
							value = [NSNumber numberWithBool:YES];
						}
					}
					break;
			}
		}
		
		// Prepare remaining parameters and notify observer. If observer stops the operation, quit immediately.
		handler(flags, name, value, &stop);
		if (stop) return NO;
		
		// Remember parsed option and continue with next one.
		if (value) [self.parsedOptions setObject:value forKey:name];
		index++;
	}
	
	// Prepare arguments (arguments are command line options after options).
	while (index < arguments.count) {
		NSString *input = [arguments objectAtIndex:index];
		[self.parsedArguments addObject:input];
		handler(GBParseFlagArgument, nil, input, &stop);
		if (stop) return NO;
		index++;
	}
	
	return result;
}

#pragma mark - Helper methods

- (NSDictionary *)optionDataForOption:(NSString *)shortOrLongName value:(NSString **)value {
	NSString *name = nil;
	NSDictionary *options = nil;
	
	// Extract the option name.
	if ([shortOrLongName hasPrefix:@"--"]) {
		name = [shortOrLongName substringFromIndex:2];
		options = self.registeredOptionsByLongNames;
	} else if ([shortOrLongName hasPrefix:@"-"]) {
		name = [shortOrLongName substringFromIndex:1];
		options = self.registeredOptionsByShortNames;
	} else {
		return GBCommandLineKeys.notAnOption;
	}
	
	// If the name includes value, extract that too.
	NSRange valueRange = [name rangeOfString:@"=" options:NSBackwardsSearch];
	if (valueRange.location != NSNotFound) {
		if (value) *value = [name substringFromIndex:valueRange.location + 1];
		name = [name substringToIndex:valueRange.location];
	}
	return [options objectForKey:name];
}

- (BOOL)isShortOrLongOptionName:(NSString *)value {
	if ([value hasPrefix:@"--"]) return YES;
	if ([value hasPrefix:@"-"]) return YES;
	return NO;
}

#pragma mark - Getting parsed results

- (id)valueForOption:(NSString *)longOption {
	return [self.parsedOptions objectForKey:longOption];
}

- (NSArray *)arguments {
	return [self.parsedArguments copy];
}

@end
