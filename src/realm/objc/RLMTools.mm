//
//  RLMTools.m
//  Realm
//
//  Created by Fiel Guhit on 5/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTools.h"
#include <tightdb/importer.hpp>

#define NOMINMAX

#include <cstring>
#include <iostream>
#include <tightdb.hpp>
#include <tightdb/utilities.hpp>

#include <stdarg.h>

using namespace std;
using namespace tightdb;

FILE* out_file;
FILE* in_file;

size_t auto_detection_flag = 0;
size_t import_rows_flag = 0;
size_t skip_rows_flag = 0;
char separator_flag = ',';
bool force_flag = false;
bool quiet_flag = false;
bool empty_as_string_flag = false;

const char* legend =
"Simple auto-import (works in most cases):\n"
"  csv <.csv file | -stdin> <.tightdb file>\n"
"\n"
"Advanced auto-detection of scheme:\n"
"  csv [-a=N] [-n=N] [-e] [-f] [-q] [-l tablename] <.csv file | -stdin> <.tightdb file>\n"
"\n"
"Manual specification of scheme:\n"
"  csv -t={s|i|b|f|d}{s|i|b|f|d}... name1 name2 ... [-s=N] [-n=N] <.csv file | -stdin> <.tightdb file>\n"
"\n"
" -a: Use the first N rows to auto-detect scheme (default =10000). Lower is faster but more error prone\n"
" -e: TightDB does not support null values. Set the -e flag to import a column as a String type column if\n"
"     it has occurences of empty fields. Otherwise empty fields may be converted to 0, 0.0 or false\n"
" -n: Only import first N rows of payload\n"
" -t: List of column types where s=string, i=integer, b=bool, f=float, d=double\n"
" -s: Skip first N rows (can be used to skip headers)\n"
" -q: Quiet, only print upon errors\n"
" -f: Overwrite destination file if existing (default is to abort)\n"
" -l: Name of the resulting table (default is 'table')\n"
"\n"
"Examples:\n"
"  csv file.csv file.tightdb\n"
"  csv -a=200000 -e file.csv file.tightdb\n"
"  csv -t=ssdbi Name Email Height Gender Age file.csv -s=1 file.tightdb\n"
"  csv -stdin file.tightdb < cat file.csv";

void abort2(bool b, const char* fmt, ...)
{
    if(b) {
        va_list argv;
        va_start(argv, fmt);
        fprintf(stderr, "csv: ");
        vfprintf(stderr, fmt, argv);
        va_end(argv);
        fprintf(stderr, "\n");
        exit(1);
    }
}

FILE* open_files(char* in)
{
    if(strcmp(in, "-stdin") == 0)
        return stdin;
    else {
        FILE* f = fopen(in, "rb");
        abort2(f == null_ptr, "Error opening input file '%s' for reading", in);
        return f;
    }
}

@implementation RLMTools

- (void)parseCSVFile:(NSString *)fileName
{
    in_file = open_files([fileName UTF8String]);
    Group group;
    string tablename = "table";
    TableRef table2 = group.get_table(tablename);
    Table table = *table2;
    
    size_t imported_rows;
    
    Importer importer;
    importer.Quiet = quiet_flag;
    importer.Separator = ',';
    importer.Empty_as_string = empty_as_string_flag;
    
    try {
        imported_rows = importer.import_csv_auto(in_file, table, auto_detection_flag ? auto_detection_flag : 10000, import_rows_flag ? import_rows_flag : static_cast<size_t>(-1));
    } catch (const runtime_error& error) {
        cerr << error.what();
        exit(-1);
    }
    
    group.write([fileName UTF8String]);
    
    if (!quiet_flag) {
        cout << "Imported " << imported_rows << " rows into table named '" << tablename << "'\n";
    }
}

@end
