//
//  GBOptionsHelper.m
//  GBCli
//
//  Created by Tomaž Kragelj on 3/15/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

#import "GBSettings.h"
#import "GBCommandLineParser.h"
#import "GBOptionsHelper.h"

@interface OptionDefinition : NSObject
@property (nonatomic, assign) char shortOption;
@property (nonatomic, copy) NSString *longOption;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, assign) GBOptionFlags flags;
@end

@implementation OptionDefinition
@synthesize shortOption;
@synthesize longOption;
@synthesize description;
@synthesize flags;
@end

#pragma mark - 

@interface GBOptionsHelper ()
- (void)replacePlaceholdersAndPrintStringFromBlock:(GBOptionStringBlock)block;
- (void)enumerateOptions:(void(^)(OptionDefinition *definition, BOOL *stop))handler;
- (NSUInteger)requirements:(OptionDefinition *)definition;
- (BOOL)isSeparator:(OptionDefinition *)definition;
- (BOOL)isCmdLine:(OptionDefinition *)definition;
- (BOOL)isPrint:(OptionDefinition *)definition;
- (BOOL)isHelp:(OptionDefinition *)definition;
@property (nonatomic, readonly) NSString *applicationNameFromBlockOrDefault;
@property (nonatomic, readonly) NSString *applicationVersionFromBlockOrNil;
@property (nonatomic, readonly) NSString *applicationBuildFromBlockOrNil;
@property (nonatomic, strong) NSMutableArray *registeredOptions;
@end

#pragma mark -

@implementation GBOptionsHelper

@synthesize registeredOptions = _registeredOptions;
@synthesize applicationName;
@synthesize applicationVersion;
@synthesize applicationBuild;
@synthesize printValuesHeader;
@synthesize printValuesArgumentsHeader;
@synthesize printValuesOptionsHeader;
@synthesize printValuesFooter;
@synthesize printHelpHeader;
@synthesize printHelpFooter;

#pragma mark - Initialization & disposal

- (id)init {
	self = [super init];
	if (self) {
		self.registeredOptions = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Options registration

- (void)registerOptionsFromDefinitions:(GBOptionDefinition *)definitions {
	GBOptionDefinition *definition = definitions;
	while (definition->longOption || definition->description) {
		[self registerOption:definition->shortOption long:definition->longOption description:definition->description flags:definition->flags];
		definition++;
	}
}

- (void)registerSeparator:(NSString *)description {
	[self registerOption:0 long:nil description:description flags:GBOptionSeparator];
}
	 
- (void)registerOption:(char)shortName long:(NSString *)longName description:(NSString *)description flags:(GBOptionFlags)flags {
	OptionDefinition *definition = [[OptionDefinition alloc] init];
	definition.shortOption = shortName;
	definition.longOption = longName;
	definition.description = description;
	definition.flags = flags;
	[self.registeredOptions addObject:definition];
}

#pragma mark - Integration with other components

- (void)registerOptionsToCommandLineParser:(GBCommandLineParser *)parser {
	[self enumerateOptions:^(OptionDefinition *definition, BOOL *stop) {
		if ([self isSeparator:definition]) return;
		if (![self isCmdLine:definition]) return;
		NSUInteger requirements = [self requirements:definition];
		[parser registerOption:definition.longOption shortcut:definition.shortOption requirement:requirements];
	}];
}

#pragma mark - Diagnostic info

- (void)printValuesFromSettings:(GBSettings *)settings {	
#define GB_UPDATE_MAX_LENGTH(value) \
	NSNumber *length = [lengths objectAtIndex:columns.count]; \
	NSUInteger maxLength = MAX(value.length, length.unsignedIntegerValue); \
	if (maxLength > length.unsignedIntegerValue) { \
	NSNumber *newMaxLength = [NSNumber numberWithUnsignedInteger:maxLength]; \
	[lengths replaceObjectAtIndex:columns.count withObject:newMaxLength]; \
}
	NSMutableArray *rows = [NSMutableArray array];
	NSMutableArray *lengths = [NSMutableArray array];
	__weak GBOptionsHelper *blockSelf = self;
	__block NSUInteger settingsHierarchyLevels = 0;
	
	// First add header row. Note that first element is the setting.
	NSMutableArray *headers = [NSMutableArray arrayWithObject:@"Option"];
	[lengths addObject:[NSNumber numberWithUnsignedInteger:[headers.lastObject length]]];
	[settings enumerateSettings:^(GBSettings *settings, BOOL *stop) {
		[headers addObject:settings.name];
		[lengths addObject:[NSNumber numberWithUnsignedInteger:settings.name.length]];
		settingsHierarchyLevels++;
	}];
	[rows addObject:headers];
	
	// Append all rows for options.
	__block NSUInteger lastSeparatorIndex = 0;
	[self enumerateOptions:^(OptionDefinition *definition, BOOL *stop) {
		if (![blockSelf isPrint:definition]) return;
		
		// Add separator. Note that we don't care about its length, we'll simply draw it over the whole line if needed.
		if ([blockSelf isSeparator:definition]) {
			if (rows.count == lastSeparatorIndex) {
				[rows removeLastObject];
				[rows removeLastObject];
			}
			NSArray *separators = [NSArray arrayWithObject:definition.description];
			[rows addObject:[NSArray array]];
			[rows addObject:separators];
			lastSeparatorIndex = rows.count;
			return;
		}
		
		// Prepare values array. Note that the first element is simply the name of the option.
		NSMutableArray *columns = [NSMutableArray array];
		NSString *longOption = definition.longOption;
		GB_UPDATE_MAX_LENGTH(longOption)
		[columns addObject:longOption];
		
		// Now append value for the option on each settings level and update maximum size.
		[settings enumerateSettings:^(GBSettings *settings, BOOL *stop) {
			NSString *columnData = @"";
			if ([settings isKeyPresentAtThisLevel:longOption]) {
				id value = [settings objectForKey:longOption];
				if ([settings isKeyArray:longOption]) {
					NSMutableString *arrayValue = [NSMutableString string];
					[(NSArray *)value enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
						GBSettings *level = [settings settingsForArrayValue:obj key:longOption];
						if (level != settings) return;
						if (arrayValue.length > 0) [arrayValue appendString:@", "];
						[arrayValue appendString:obj];
					}];
					columnData = arrayValue;
				} else {
					columnData = [value description];
				}
			}
			GB_UPDATE_MAX_LENGTH(columnData)
			[columns addObject:columnData];
		}];
		
		// Add the row.
		[rows addObject:columns];
	}];
	
	// Remove last separator if there were no values.
	if (rows.count == lastSeparatorIndex) {
		[rows removeLastObject];
		[rows removeLastObject];
	}

	// Render header.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesHeader];
	
	// Render all arguments if any.
	if (settings.arguments.count > 0) {
		[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesArgumentsHeader];
		[settings.arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL *stop) {
			printf("- %s", argument.UTF8String);
			if (settingsHierarchyLevels > 1) {
				GBSettings *level = [settings settingsForArgument:argument];
				printf(" (%s)", level.name.UTF8String);
			}
			printf("\n");
		}];
		printf("\n");
	}
	
	// Render all rows.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesOptionsHeader];
	[rows enumerateObjectsUsingBlock:^(NSArray *columns, NSUInteger rowIdx, BOOL *stopRow) {
		NSMutableString *output = [NSMutableString string];
		[columns enumerateObjectsUsingBlock:^(NSString *value, NSUInteger colIdx, BOOL *stopCol) {
			NSUInteger columnSize = [[lengths objectAtIndex:colIdx] unsignedIntegerValue];
			NSUInteger valueSize = value.length;
			[output appendString:value];
			while (valueSize <= columnSize) {
				[output appendString:@" "];
				valueSize++;
			}
		}];
		printf("%s\n", output.UTF8String);
	}];
	
	// Render footer.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesFooter];
}

- (void)printVersion {
	NSMutableString *output = [NSMutableString stringWithFormat:@"%@", self.applicationNameFromBlockOrDefault];
	NSString *version = self.applicationVersionFromBlockOrNil;
	NSString *build = self.applicationBuildFromBlockOrNil;
	if (version) [output appendFormat:@": version %@", version];
	if (build) [output appendFormat:@" (build %@)", build];
	printf("%s\n", output.UTF8String);
}

- (void)printHelp {	
	// Prepare all rows.
	__block NSUInteger maxNameTypeLength = 0;
	__block NSUInteger lastSeparatorIndex = NSNotFound;
	NSMutableArray *rows = [NSMutableArray array];
	[self enumerateOptions:^(OptionDefinition *definition, BOOL *stop) {
		if (![self isHelp:definition]) return;
		
		// Prepare separator. Remove previous one if there were no values prepared for it.
		if ([self isSeparator:definition]) {
			if (rows.count == lastSeparatorIndex) {
				[rows removeLastObject];
				[rows removeLastObject];
			}
			[rows addObject:[NSArray array]];
			[rows addObject:[NSArray arrayWithObject:definition.description]];
			lastSeparatorIndex = rows.count;
			return;
		}
		
		// Prepare option description.
		NSString *shortOption = (definition.shortOption > 0) ? [NSString stringWithFormat:@"-%c", definition.shortOption] : @"  ";
		NSString *longOption = [NSString stringWithFormat:@"--%@", definition.longOption];
		NSString *description = definition.description;
		NSUInteger requirements = [self requirements:definition];
		
		// Prepare option type and update longest option+type string size for better alignment later on.
		NSString *type = @"";
		if (requirements == GBValueRequired)
			type = @" <value>";
		else if (requirements == GBValueOptional)
			type = @" [<value>]";
		maxNameTypeLength = MAX(longOption.length + type.length, maxNameTypeLength);
		NSString *nameAndType = [NSString stringWithFormat:@"%@%@", longOption, type];
		
		// Add option info to rows array.
		NSMutableArray *columns = [NSMutableArray array];
		[columns addObject:shortOption];
		[columns addObject:nameAndType];
		[columns addObject:description];
		[rows addObject:columns];
	}];
	
	// Remove last separator if there were no values.
	if (rows.count == lastSeparatorIndex) {
		[rows removeLastObject];
		[rows removeLastObject];
	}
	
	// Render header.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printHelpHeader];
	
	// Render all rows aligning long option columns properly.
	[rows enumerateObjectsUsingBlock:^(NSArray *columns, NSUInteger rowIdx, BOOL *stop) {
		NSMutableString *output = [NSMutableString string];
		[columns enumerateObjectsUsingBlock:^(NSString *column, NSUInteger colIdx, BOOL *stop) {
			[output appendFormat:@"%@ ", column];
			if (colIdx == 1) {
				NSUInteger length = column.length;
				while (length < maxNameTypeLength) {
					[output appendString:@" "];
					length++;
				}
			}
		}];
		printf("%s\n", output.UTF8String);
	}];
	
	// Render footer.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printHelpFooter];
}

#pragma mark - Application information

- (NSString *)applicationNameFromBlockOrDefault {
	if (self.applicationName) return self.applicationName();
	NSProcessInfo *process = [NSProcessInfo processInfo];
	return process.processName;
}

- (NSString *)applicationVersionFromBlockOrNil {
	if (self.applicationVersion) return self.applicationVersion();
	return nil;
}

- (NSString *)applicationBuildFromBlockOrNil {
	if (self.applicationBuild) return self.applicationBuild();
	return nil;
}

#pragma mark - Rendering helpers

- (void)replacePlaceholdersAndPrintStringFromBlock:(GBOptionStringBlock)block {
	if (!block) {
		printf("\n");
		return;
	}
	NSString *string = block();
	string = [string stringByReplacingOccurrencesOfString:@"%APPNAME" withString:self.applicationNameFromBlockOrDefault];
  if ( self.applicationVersionFromBlockOrNil )
    string = [string stringByReplacingOccurrencesOfString:@"%APPVERSION" withString:self.applicationVersionFromBlockOrNil];
  if ( self.applicationBuildFromBlockOrNil )
    string = [string stringByReplacingOccurrencesOfString:@"%APPBUILD" withString:self.applicationBuildFromBlockOrNil];
	printf("%s\n", string.UTF8String);
}

#pragma mark - Helper methods

- (void)enumerateOptions:(void(^)(OptionDefinition *definition, BOOL *stop))handler {
	[self.registeredOptions enumerateObjectsUsingBlock:^(OptionDefinition *definition, NSUInteger idx, BOOL *stop) {
		handler(definition, stop);
	}];
}

- (NSUInteger)requirements:(OptionDefinition *)definition {
	return (definition.flags & 0b11);
}

- (BOOL)isSeparator:(OptionDefinition *)definition {
	return ((definition.flags & GBOptionSeparator) > 0);
}

- (BOOL)isCmdLine:(OptionDefinition *)definition {
	return ((definition.flags & GBOptionNoCmdLine) == 0);
}

- (BOOL)isPrint:(OptionDefinition *)definition {
	return ((definition.flags & GBOptionNoPrint) == 0);
}

- (BOOL)isHelp:(OptionDefinition *)definition {
	return ((definition.flags & GBOptionNoHelp) == 0);
}

@end
