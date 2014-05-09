/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

// Test tool in test/test_csv/test.pl

#define NOMINMAX

#include <cstring>
#include <iostream>
#include <tightdb.hpp>
#include <tightdb/utilities.hpp>
#include <tightdb/importer.hpp>
#include <stdarg.h>
#import <Realm/Realm.h>

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

void import_csv(int argc, char *argv[])
{
#if 0
    char* hey[] = {"self", "-f", "d:/csv/managers.csv", "d:/csv/test.tightdb"};
    argc = sizeof(hey) / sizeof(hey[0]);
    argv = hey;
#endif
    
    abort2(argc < 3, legend);
    
    vector<DataType> scheme;
    vector<string> column_names;
    string tablename = "table";
    
    // Parse from 1'st argument until before source and destination args
    for(int a = 1; a < argc - 2; ++a) {
        abort2(strlen(argv[a]) == 0 || argv[a][strlen(argv[a]) - 1] == '=' || argv[a + 1][0] == '=', "Please remove space characters before and after '=' signs in command line flags");
        
        if(strncmp(argv[a], "-a=", 3) == 0)
            auto_detection_flag = atoi(&argv[a][3]);
        else if(strncmp(argv[a], "-n", 2) == 0) {
            import_rows_flag = atoi(&argv[a][3]);
            abort2(import_rows_flag == 0, "Invalid value for -n flag");
        }
        else if(strncmp(argv[a], "-s", 2) == 0) {
            skip_rows_flag = atoi(&argv[a][3]);
            abort2(skip_rows_flag == 0, "Invalid value for -s flag");
        }
        else if(strncmp(argv[a], "-e", 2) == 0)
            empty_as_string_flag = true;
        else if(strncmp(argv[a], "-f", 2) == 0)
            force_flag = true;
        else if(strncmp(argv[a], "-q", 2) == 0)
            quiet_flag = true;
        else if(strncmp(argv[a], "-t", 2) == 0) {
            
            // Parse column types and names
            char* types = &argv[a][3];
            size_t columns = strlen(argv[a]) - 3;
            for(size_t n = 0; n < columns; n++) {
                abort2(argv[a + 1][0] == '-', "Too few column names on the command line with -t flag");
                column_names.push_back(argv[a + 1]);
                
                if(types[n] == 's')
                    scheme.push_back(type_String);
                else if(types[n] == 'd')
                    scheme.push_back(type_Double);
                else if(types[n] == 'f')
                    scheme.push_back(type_Float);
                else if(types[n] == 'i')
                    scheme.push_back(type_Int);
                else if(types[n] == 'b')
                    scheme.push_back(type_Bool);
                else
                    abort2(true, "'%c' is not a valid column type", types[n]);
                
                a++;
            }
        }
        else if(strncmp(argv[a], "-l", 2) == 0) {
            abort2(a >= argc-4 , "Too few arguments");
            tablename = argv[++a];
        }
        else {
            abort2(true, legend);
        }
    }
    
    // Check invalid combinations of flags
    abort2(auto_detection_flag > 0 && skip_rows_flag > 0, "-a flag and -s flag cannot be used at the same time");
    abort2(auto_detection_flag > 0 && scheme.size() > 0, "-a flag cannot be used when scheme is specified manually with -t flag");
    abort2(empty_as_string_flag && scheme.size() > 0, "-e flag cannot be used when scheme is specified manually with -t flag");
    
    abort2(!force_flag && util::File::exists(argv[argc - 1]), "Destination file '%s' already exists.", argv[argc - 1]);
    
    if(util::File::exists(argv[argc - 1]))
        util::File::try_remove(argv[argc - 1]);
    
    in_file = open_files(argv[argc - 2]);
    string path = argv[argc - 1];
    Group group;
    TableRef table2 = group.get_table(tablename);
    Table &table = *table2;
    
    size_t imported_rows;
    
    Importer importer;
    importer.Quiet = quiet_flag;
    importer.Separator = ',';
    importer.Empty_as_string = empty_as_string_flag;
    
    try {
        if(scheme.size() > 0) {
            // Manual specification of scheme
            imported_rows = importer.import_csv_manual(in_file, table, scheme, column_names, skip_rows_flag, import_rows_flag ? import_rows_flag : static_cast<size_t>(-1));
        }
        else if (argc >= 3) {
            // Auto detection
            abort2(skip_rows_flag > 0, "-s flag cannot be used in Simple auto-import mode");
            imported_rows = importer.import_csv_auto(in_file, table, auto_detection_flag ? auto_detection_flag : 10000, import_rows_flag ? import_rows_flag : static_cast<size_t>(-1));
        }
        else {
            
        }
        
    }
    catch (const runtime_error& error) {
        cerr << error.what();
        exit(-1);
    }
    
    group.write(path);
    
    if(!quiet_flag)
        cout << "Imported " << imported_rows << " rows into table named '" << tablename << "'\n";
}

int main(int argc, char* argv[])
{    
    abort2(argc < 3, legend);
    
    NSString *fileString = [NSString stringWithUTF8String:argv[argc - 2]];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:fileString];
    NSString *fileExtension = [fileURL pathExtension];
    
    if ([fileExtension isEqualToString:@"csv"]) {
        NSLog(@"Importing CSV");
        import_csv(argc, argv);
    }
    else if ([fileExtension isEqualToString:@"json"]) {
        NSLog(@"Importing JSON");
    }
    
    return 0;
}
