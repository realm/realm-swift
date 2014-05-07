//
//  GBCommandLineParser.h
//  GBCli
//
//  Created by Tomaž Kragelj on 3/12/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

typedef NSUInteger GBValueRequirements;
typedef NSUInteger GBParseFlags;
typedef void(^GBCommandLineParseBlock)(GBParseFlags flags, NSString *argument, id value, BOOL *stop);

/** Handles command line arguments parsing.
 
 To use the class, instantiate it, register all options, ask it to parse command line arguments and finally use accessors to read the data. Here's one possible way:
 
 ```
 int main(int argv, char **argv) {
	GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
	[parser registerOption:@"verbose" shortcut:'v' requirement:GBValueRequired];
	[parser registerSwitch:@"help" shortcut:'h'];
	...
	[parser parseOptionsWithArguments:argv count:argc block:^(NSString *argument, id value, BOOL *stop) {
		if (value == GBCommandLineArgumentResults.unknownArgument) {
			*stop = YES;
			return;
		} else if (value == GBCommandLineArgumentResults.missingValue) {
			*stop = YES;
			return;
		}
		... you can do somethig with valid argument here if needed
	}];
	... you can access all parsed options and arguments here...
	id value1 = [parser valueForOption:@"verbose"];
	NSArray *arguments = parser.arguments;
	return 0;
 }
 ```
 
 @warning **Important:** This class is similar to `DDCli` from Dave Dribin, but works under arc! It also uses a different approach to command line parsing - instead of using "push" model like `DDCli` (i.e. sending KVO notifications to pass arguments to a delegate), it uses "pull" model: you let it parse the values and then ask the class for specific argument values. With this approach, it centralizes arguments handling - instead of splitting it over various delegate and KVO mutator methods, you can do it in a single place.
 */
@interface GBCommandLineParser : NSObject

#pragma mark - Options registration

- (void)registerOption:(NSString *)longOption shortcut:(char)shortOption requirement:(GBValueRequirements)requirement;
- (void)registerOption:(NSString *)longOption requirement:(GBValueRequirements)requirement;
- (void)registerSwitch:(NSString *)longOption shortcut:(char)shortOption;
- (void)registerSwitch:(NSString *)longOption;

#pragma mark - Options parsing

- (BOOL)parseOptionsUsingDefaultArgumentsWithBlock:(GBCommandLineParseBlock)handler;
- (BOOL)parseOptionsWithArguments:(char **)argv count:(int)argc block:(GBCommandLineParseBlock)handler;
- (BOOL)parseOptionsWithArguments:(NSArray *)arguments commandLine:(NSString *)cmd block:(GBCommandLineParseBlock)handler;

#pragma mark - Getting parsed results

- (id)valueForOption:(NSString *)longOption;
- (NSArray *)arguments;

@end

#pragma mark -

/** Various command line argument value requirements. */
enum {
	GBValueRequired, ///< Command line argument requires a value.
	GBValueOptional, ///< Command line argument can optionally have a value, but is not required.
	GBValueNone ///< Command line argument is on/off switch.
};

/** Various parsing flags. */
enum {
	GBParseFlagOption,
	GBParseFlagArgument,
	GBParseFlagMissingValue,
	GBParseFlagUnknownOption,
};
