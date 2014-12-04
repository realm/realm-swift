/*
Main method: import_csv(). Arguments:
---------------------------------------------------------------------------------------------------------------------
empty_as_string_flag:
    Imports a column that has occurences of empty strings as String type column. Else fields arec onverted to false/0/0.0

type_detection_rows:
    tells how many rows to read before analyzing data types (to see if numeric rows are really
    numeric everywhere, and not strings that happen to just mostly contain numeric characters


This library supports:
---------------------------------------------------------------------------------------------------------------------
    * Auto detection of float vs. double, depending on number of significant digits
    * Bool types can be case insensitive "true, false, 0, 1, yes, no"
    * Newline inside data fields, plus auto detection of non-conforming non-quoted newlines (as in some IBM sample files)
    * TightDB types String, Integer, Bool, Float and Double
    * Auto detection of header and naming of TightDB columns accordingly
    * double-quoted and non-quoted fields, and these can be mixed arbitrarely
    * double-quotes inside data field
    * *nix + MacOSv9 + Windows line feed
    * Scientific notation of floats/doubles (+1.23e-10)
    * Comma in floats - but ONLY if field is double-quoted
    * FAST FAST FAST (200 MB/s). Uses state-machine instead of traditional char-by-char loop with state checks inside


Problems:
---------------------------------------------------------------------------------------------------------------------
    A csv file does not tell its sheme. So we auto-detect it, based on the first N rows. However if a given column
    contains 'false, false, false, hello' and we detect and create TightDB table scheme using the first 3 rows, we fail
    when we meet 'hello' (this error is handled with a thorough error message)

    Does not support commas in floats unless field is double-quoted


Design:
---------------------------------------------------------------------------------------------------------------------

import_csv(csv file handle, tightdb table)
    Calls tokenize(csv file handle):
        reads payload chunk and returns vector<vector<string>> with the right dimensions filled with rows and columns of
        the chunk payload
    Calls parse_float(), parse_bool(), etc, which tests for type and returns converted values
    Calls table.add_empty_row(), table.set_float(), table.set_bool()
*/

#include <stddef.h>

// Disk read chunk size. This MUST be large enough to contain at least TWO rows of csv plaintext! It's a good idea
// to set it as low as ever possible (like 32 K) even though it's counter-intuitive with respect to performance. It
// will make the operating system read 32 K from disk and return it, and then read-ahead 32-64 K more after fread()
// has returned. This read-ahead behaviour does NOT occur if we request megabyte-sized chunks (observed on Windows 7 /
// Ubuntu)
static const size_t chunk_size = 32*1024;

// Number of rows to csv-parse + insert into tightdb in each iteration.
static const size_t record_chunks = 100;

// Width of each column when printing them on screen (non-Quiet mode)
const size_t print_width = 25;

#include <vector>
#include <tightdb.hpp>

using namespace std;
using namespace tightdb;

class Importer
{
public:
    Importer();
    size_t import_csv_auto(FILE* file, Table& table, size_t type_detection_rows = 1000,
                            size_t import_rows = static_cast<size_t>(-1));

    size_t import_csv_manual(FILE* file, Table& table, vector<DataType> scheme, vector<string> column_names,
                             size_t skip_first_rows = 0, size_t import_rows = static_cast<size_t>(-1));

    bool Quiet;              // Quiet mode, only print to screen upon errors
    char Separator;          // csv delimitor/separator
    bool Empty_as_string;    // Import columns that have occurences of empty strings as String type column

private:
    size_t import_csv(FILE* file, Table& table, vector<DataType> *scheme, vector<string> *column_names,
                      size_t type_detection_rows, size_t skip_first_rows, size_t import_rows);
    template <bool can_fail> float parse_float(const char*col, bool* success = null_ptr);
    template <bool can_fail> double parse_double(const char* col, bool* success = null_ptr, size_t* significants = null_ptr);
    template <bool can_fail> int64_t parse_integer(const char* col, bool* success = null_ptr);
    template <bool can_fail> bool parse_bool(const char*col, bool* success = null_ptr);
    vector<DataType> types (vector<string> v);
    size_t tokenize(vector<vector<string> > & payload, size_t records);
    vector<DataType> detect_scheme (vector<vector<string> > payload, size_t begin, size_t end);
    vector<DataType> lowest_common (vector<DataType> types1, vector<DataType> types2);

    char src[2*chunk_size];    // .csv input buffer
    size_t m_top;              // points at top of buffer
    size_t m_curpos;           // points at next byte to parse
    FILE* m_file;              // handle to .csv file
    size_t m_fields;           // number of fields in each row
    size_t m_row;              // current row in .csv file, including field-embedded line breaks. Used for err msg only
};


