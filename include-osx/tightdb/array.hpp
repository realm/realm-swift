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

/*
Searching: The main finding function is:
    template<class cond, Action action, size_t bitwidth, class Callback> void find(int64_t value, size_t start, size_t end, size_t baseindex, QueryState *state, Callback callback) const

    cond:       One of Equal, NotEqual, Greater, etc. classes
    Action:     One of act_ReturnFirst, act_FindAll, act_Max, act_CallbackIdx, etc, constants
    Callback:   Optional function to call for each search result. Will be called if action == act_CallbackIdx

    find() will call find_action_pattern() or find_action() that again calls match() for each search result which optionally calls callback():

        find() -> find_action() -------> bool match() -> bool callback()
             |                            ^
             +-> find_action_pattern()----+

    If callback() returns false, find() will exit, otherwise it will keep searching remaining items in array.
*/

#ifndef TIGHTDB_ARRAY_HPP
#define TIGHTDB_ARRAY_HPP

#include <cmath>
#include <cstdlib> // std::size_t
#include <algorithm>
#include <utility>
#include <vector>
#include <ostream>

#include <stdint.h> // unint8_t etc

#include <tightdb/util/meta.hpp>
#include <tightdb/util/assert.hpp>
#include <tightdb/utilities.hpp>
#include <tightdb/alloc.hpp>
#include <tightdb/string_data.hpp>
#include <tightdb/query_conditions.hpp>

/*
    MMX: mmintrin.h
    SSE: xmmintrin.h
    SSE2: emmintrin.h
    SSE3: pmmintrin.h
    SSSE3: tmmintrin.h
    SSE4A: ammintrin.h
    SSE4.1: smmintrin.h
    SSE4.2: nmmintrin.h
*/
#ifdef TIGHTDB_COMPILER_SSE
#  include <emmintrin.h> // SSE2
#  include <tightdb/tightdb_nmmintrin.h> // SSE42
#endif

namespace tightdb {

enum Action {act_ReturnFirst, act_Sum, act_Max, act_Min, act_Count, act_FindAll, act_CallIdx, act_CallbackIdx,
             act_CallbackVal, act_CallbackNone, act_CallbackBoth};

template<class T> inline T no0(T v) { return v == 0 ? 1 : v; }

/// Special index value. It has various meanings depending on
/// context. It is returned by some search functions to indicate 'not
/// found'. It is similar in function to std::string::npos.
const std::size_t npos = std::size_t(-1);

/// Alias for tightdb::npos.
const std::size_t not_found = npos;

 /* wid == 16/32 likely when accessing offsets in B tree */
#define TIGHTDB_TEMPEX(fun, wid, arg) \
    if (wid == 16) {fun<16> arg;} \
    else if (wid == 32) {fun<32> arg;} \
    else if (wid == 0) {fun<0> arg;} \
    else if (wid == 1) {fun<1> arg;} \
    else if (wid == 2) {fun<2> arg;} \
    else if (wid == 4) {fun<4> arg;} \
    else if (wid == 8) {fun<8> arg;} \
    else if (wid == 64) {fun<64> arg;} \
    else {TIGHTDB_ASSERT(false); fun<0> arg;}

#define TIGHTDB_TEMPEX2(fun, targ, wid, arg) \
    if (wid == 16) {fun<targ, 16> arg;} \
    else if (wid == 32) {fun<targ, 32> arg;} \
    else if (wid == 0) {fun<targ, 0> arg;} \
    else if (wid == 1) {fun<targ, 1> arg;} \
    else if (wid == 2) {fun<targ, 2> arg;} \
    else if (wid == 4) {fun<targ, 4> arg;} \
    else if (wid == 8) {fun<targ, 8> arg;} \
    else if (wid == 64) {fun<targ, 64> arg;} \
    else {TIGHTDB_ASSERT(false); fun<targ, 0> arg;}

#define TIGHTDB_TEMPEX3(fun, targ1, targ2, wid, arg) \
    if (wid == 16) {fun<targ1, targ2, 16> arg;} \
    else if (wid == 32) {fun<targ1, targ2, 32> arg;} \
    else if (wid == 0) {fun<targ1, targ2, 0> arg;} \
    else if (wid == 1) {fun<targ1, targ2, 1> arg;} \
    else if (wid == 2) {fun<targ1, targ2, 2> arg;} \
    else if (wid == 4) {fun<targ1, targ2, 4> arg;} \
    else if (wid == 8) {fun<targ1, targ2, 8> arg;} \
    else if (wid == 64) {fun<targ1, targ2, 64> arg;} \
    else {TIGHTDB_ASSERT(false); fun<targ1, targ2, 0> arg;}

#define TIGHTDB_TEMPEX4(fun, targ1, targ2, wid, targ3, arg) \
    if (wid == 16) {fun<targ1, targ2, 16, targ3> arg;} \
    else if (wid == 32) {fun<targ1, targ2, 32, targ3> arg;} \
    else if (wid == 0) {fun<targ1, targ2, 0, targ3> arg;} \
    else if (wid == 1) {fun<targ1, targ2, 1, targ3> arg;} \
    else if (wid == 2) {fun<targ1, targ2, 2, targ3> arg;} \
    else if (wid == 4) {fun<targ1, targ2, 4, targ3> arg;} \
    else if (wid == 8) {fun<targ1, targ2, 8, targ3> arg;} \
    else if (wid == 64) {fun<targ1, targ2, 64, targ3> arg;} \
    else {TIGHTDB_ASSERT(false); fun<targ1, targ2, 0, targ3> arg;}

#define TIGHTDB_TEMPEX5(fun, targ1, targ2, targ3, targ4, wid, arg) \
    if (wid == 16) {fun<targ1, targ2, targ3, targ4, 16> arg;} \
    else if (wid == 32) {fun<targ1, targ2, targ3, targ4, 32> arg;} \
    else if (wid == 0) {fun<targ1, targ2, targ3, targ4, 0> arg;} \
    else if (wid == 1) {fun<targ1, targ2, targ3, targ4, 1> arg;} \
    else if (wid == 2) {fun<targ1, targ2, targ3, targ4, 2> arg;} \
    else if (wid == 4) {fun<targ1, targ2, targ3, targ4, 4> arg;} \
    else if (wid == 8) {fun<targ1, targ2, targ3, targ4, 8> arg;} \
    else if (wid == 64) {fun<targ1, targ2, targ3, targ4, 64> arg;} \
    else {TIGHTDB_ASSERT(false); fun<targ1, targ2, targ3, targ4, 0> arg;}


// Pre-definitions
class Array;
class AdaptiveStringColumn;
class GroupWriter;
class Column;
template<class T> class QueryState;


#ifdef TIGHTDB_DEBUG
class MemStats {
public:
    MemStats():
        allocated(0),
        used(0),
        array_count(0)
    {
    }
    std::size_t allocated;
    std::size_t used;
    std::size_t array_count;
};
#endif


class ArrayParent
{
public:
    virtual ~ArrayParent() TIGHTDB_NOEXCEPT {}

protected:
    virtual void update_child_ref(std::size_t child_ndx, ref_type new_ref) = 0;

    virtual ref_type get_child_ref(std::size_t child_ndx) const TIGHTDB_NOEXCEPT = 0;

#ifdef TIGHTDB_DEBUG
    // Used only by Array::to_dot().
    virtual std::pair<ref_type, std::size_t> get_to_dot_parent(std::size_t ndx_in_parent) const = 0;
#endif

    friend class Array;
};


/// Provides access to individual array nodes of the database.
///
/// This class serves purely as an accessor, it assumes no ownership of the
/// referenced memory.
///
/// An array accessor can be in one of two states: attached or unattached. It is
/// in the attached state if, and only if is_attached() returns true. Most
/// non-static member functions of this class have undefined behaviour if the
/// accessor is in the unattached state. The exceptions are: is_attached(),
/// detach(), create(), init_from_ref(), init_from_mem(), init_from_parent(),
/// has_parent(), get_parent(), set_parent(), get_ndx_in_parent(),
/// set_ndx_in_parent(), adjust_ndx_in_parent(), and get_ref_from_parent().
///
/// An array accessor contains information about the parent of the referenced
/// array node. This 'reverse' reference is not explicitely present in the
/// underlying node hierarchy, but it is needed when modifying an array. A
/// modification may lead to relocation of the underlying array node, and the
/// parent must be updated accordingly. Since this applies recursivly all the
/// way to the root node, it is essential that the entire chain of parent
/// accessors is constructed and propperly maintained when a particular array is
/// modified.
///
/// The parent reference (`pointer to parent`, `index in parent`) is updated
/// independently from the state of attachment to an underlying node. In
/// particular, the parent reference remains valid and is unannfected by changes
/// in attachment. These two aspects of the state of the accessor is updated
/// independently, and it is entirely the responsibility of the caller to update
/// them such that they are consistent with the underlying node hierarchy before
/// calling any method that modifies the underlying array node.
///
/// FIXME: This class currently has fragments of ownership, in particular the
/// constructors that allocate underlying memory. On the other hand, the
/// destructor never frees the memory. This is a disastrous situation, because
/// it so easily becomes an obscure source of leaks. There are three options for
/// a fix of which the third is most attractive but hardest to implement: (1)
/// Remove all traces of ownership semantics, that is, remove the constructors
/// that allocate memory, but keep the trivial copy constructor. For this to
/// work, it is important that the constness of the accessor has nothing to do
/// with the constness of the underlying memory, otherwise constness can be
/// violated simply by copying the accessor. (2) Disallov copying but associate
/// the constness of the accessor with the constness of the underlying
/// memory. (3) Provide full ownership semantics like is done for Table
/// accessors, and provide a proper copy constructor that really produces a copy
/// of the array. For this to work, the class should assume ownership if, and
/// only if there is no parent. A copy produced by a copy constructor will not
/// have a parent. Even if the original was part of a database, the copy will be
/// free-standing, that is, not be part of any database. For intra, or inter
/// database copying, one would have to also specify the target allocator.
class Array: public ArrayParent {
public:

//    void state_init(int action, QueryState *state);
//    bool match(int action, std::size_t index, int64_t value, QueryState *state);

    /// Create an array accessor in the unattached state.
    explicit Array(Allocator&) TIGHTDB_NOEXCEPT;

    // Fastest way to instantiate an array, if you just want to utilize its
    // methods
    struct no_prealloc_tag {};
    explicit Array(no_prealloc_tag) TIGHTDB_NOEXCEPT;

    ~Array() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    enum Type {
        type_Normal,

        /// This array is the main array of an innner node of a B+-tree as used
        /// in table columns.
        type_InnerBptreeNode,

        /// This array may contain refs to subarrays. An element whose least
        /// significant bit is zero, is a ref pointing to a subarray. An element
        /// whose least significant bit is one, is just a value. It is the
        /// responsibility of the application to ensure that non-ref values have
        /// their least significant bit set. This will generally be done by
        /// shifting the desired vlue to the left by one bit position, and then
        /// setting the vacated bit to one.
        type_HasRefs
    };

    /// Create a new empty array of the specified type and attach this accessor
    /// to it. This does not modify the parent reference information of this
    /// accessor.
    ///
    /// Note that the caller assumes ownership of the allocated underlying
    /// node. It is not owned by the accessor.
    ///
    /// FIXME: Belongs in IntegerArray
    void create(Type, bool context_flag = false);

    /// Reinitialize this array accessor to point to the specified new
    /// underlying memory. This does not modify the parent reference information
    /// of this accessor.
    void init_from_ref(ref_type) TIGHTDB_NOEXCEPT;

    /// Same as init_from_ref(ref_type) but avoid the mapping of 'ref' to memory
    /// pointer.
    void init_from_mem(MemRef) TIGHTDB_NOEXCEPT;

    /// Same as `init_from_ref(get_ref_from_parent())`.
    void init_from_parent() TIGHTDB_NOEXCEPT;

    /// Update the parents reference to this child. This requires, of course,
    /// that the parent information stored in this child is up to date. If the
    /// parent pointer is set to null, this function has no effect.
    void update_parent();

    /// Called in the context of Group::commit() to ensure that attached
    /// accessors stay valid across a commit. Please note that this works only
    /// for non-transactional commits. Accessors obtained during a transaction
    /// are always detached when the transaction ends.
    ///
    /// Returns true if, and only if the array has changed. If the array has not
    /// changed, then its children are guaranteed to also not have changed.
    bool update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;

    /// Change the type of an already attached array node.
    ///
    /// The effect of calling this function on an unattached accessor is
    /// undefined.
    void set_type(Type);

    /// Construct a complete copy of this array (including its subarrays) using
    /// the specified target allocator and return just the reference to the
    /// underlying memory.
    MemRef clone_deep(Allocator& target_alloc) const;

    void move_assign(Array&) TIGHTDB_NOEXCEPT; // Move semantics for assignment

    /// Construct an array of the specified type and size, and return just the
    /// reference to the underlying memory. All elements will be initialized to
    /// the specified value.
    ///
    /// FIXME: Belongs in IntegerArray
    static MemRef create_array(Type, bool context_flag, std::size_t size, int_fast64_t value,
                               Allocator&);

    /// Construct an empty array of the specified type, and return just the
    /// reference to the underlying memory.
    ///
    /// FIXME: Belongs in IntegerArray
    static MemRef create_empty_array(Type, bool context_flag, Allocator&);

    /// Construct a shallow copy of the specified slice of this array using the
    /// specified target allocator. Subarrays will **not** be cloned. See
    /// slice_and_clone_children() for an alternative.
    ///
    /// FIXME: Belongs in IntegerArray
    MemRef slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const;

    /// Construct a deep copy of the specified slice of this array using the
    /// specified target allocator. Subarrays will be cloned.
    ///
    /// FIXME: Belongs in IntegerArray
    MemRef slice_and_clone_children(std::size_t offset, std::size_t size,
                                    Allocator& target_alloc) const;

    // Parent tracking
    bool has_parent() const TIGHTDB_NOEXCEPT;
    ArrayParent* get_parent() const TIGHTDB_NOEXCEPT;

    /// Setting a new parent affects ownership of the attached array node, if
    /// any. If a non-null parent is specified, and there was no parent
    /// originally, then the caller passes ownership to the parent, and vice
    /// versa. This assumes, of course, that the change in parentship reflects a
    /// corresponding change in the list of children in the affected parents.
    void set_parent(ArrayParent* parent, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT;

    std::size_t get_ndx_in_parent() const TIGHTDB_NOEXCEPT;
    void set_ndx_in_parent(std::size_t) TIGHTDB_NOEXCEPT;
    void adjust_ndx_in_parent(int diff) TIGHTDB_NOEXCEPT;

    /// Get the ref of this array as known to the parent. The caller must ensure
    /// that the parent information ('pointer to parent' and 'index in parent')
    /// is correct before calling this function.
    ref_type get_ref_from_parent() const TIGHTDB_NOEXCEPT;

    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Detach from the underlying array node. This method has no effect if the
    /// accessor is currently unattached (idempotency).
    void detach() TIGHTDB_NOEXCEPT;

    std::size_t size() const TIGHTDB_NOEXCEPT;
    bool is_empty() const TIGHTDB_NOEXCEPT;
    Type get_type() const TIGHTDB_NOEXCEPT;

    // Exists for find_all() because array.hpp cannot append results directly to a Column type (incomplete class)
    static void add_to_column(Column* column, int64_t value);

    void insert(std::size_t ndx, int_fast64_t value);
    void add(int_fast64_t value);

    /// This function is guaranteed to not throw if the current width is
    /// sufficient for the specified value (e.g. if you have called
    /// ensure_minimum_width(value)) and get_alloc().is_read_only(get_ref())
    /// returns false (noexcept:array-set). Note that for a value of zero, the
    /// first criterion is trivially satisfied.
    void set(std::size_t ndx, int64_t value);

    template<std::size_t w> void Set(std::size_t ndx, int64_t value);

    int64_t get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    template<std::size_t w> int64_t Get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void get_chunk(size_t ndx, int64_t res[8]) const TIGHTDB_NOEXCEPT;
    template<size_t w> void get_chunk(size_t ndx, int64_t res[8]) const TIGHTDB_NOEXCEPT;

    ref_type get_as_ref(std::size_t ndx) const TIGHTDB_NOEXCEPT;

    int64_t operator[](std::size_t ndx) const TIGHTDB_NOEXCEPT { return get(ndx); }
    int64_t front() const TIGHTDB_NOEXCEPT;
    int64_t back() const TIGHTDB_NOEXCEPT;

    /// Remove the element at the specified index, and move elements at higher
    /// indexes to the next lower index.
    ///
    /// This function does **not** destroy removed subarrays. That is, if the
    /// erased element is a 'ref' pointing to a subarray, then that subarray
    /// will not be destroyed automatically.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the
    /// call. This is automatically guaranteed if the array is used in a
    /// non-transactional context, or if the array has already been successfully
    /// modified within the current write transaction.
    void erase(std::size_t ndx);

    /// Same as erase(std::size_t), but remove all elements in the specified
    /// range.
    ///
    /// Please note that this function does **not** destroy removed subarrays.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void erase(std::size_t begin, std::size_t end);

    /// Reduce the size of this array to the specified number of elements. It is
    /// an error to specify a size that is greater than the current size of this
    /// array. The effect of doing so is undefined. This is just a shorthand for
    /// calling the ranged erase() function with appropriate arguments.
    ///
    /// Please note that this function does **not** destroy removed
    /// subarrays. See clear_and_destroy_children() for an alternative.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void truncate(std::size_t size);

    /// Reduce the size of this array to the specified number of elements. It is
    /// an error to specify a size that is greater than the current size of this
    /// array. The effect of doing so is undefined. Subarrays will be destroyed
    /// recursively, as if by a call to `destroy_deep(subarray_ref, alloc)`.
    ///
    /// This function is guaranteed not to throw if
    /// get_alloc().is_read_only(get_ref()) returns false.
    void truncate_and_destroy_children(std::size_t size);

    /// Remove every element from this array. This is just a shorthand for
    /// calling truncate(0).
    ///
    /// Please note that this function does **not** destroy removed
    /// subarrays. See clear_and_destroy_children() for an alternative.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void clear();

    /// Remove every element in this array. Subarrays will be destroyed
    /// recursively, as if by a call to `destroy_deep(subarray_ref,
    /// alloc)`. This is just a shorthand for calling
    /// truncate_and_destroy_children(0).
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void clear_and_destroy_children();

    /// If neccessary, expand the representation so that it can store the
    /// specified value.
    void ensure_minimum_width(int64_t value);

    // Direct access methods
    const Array* GetBlock(std::size_t ndx, Array& arr, std::size_t& off,
                          bool use_retval = false) const TIGHTDB_NOEXCEPT; // FIXME: Constness is not propagated to the sub-array

    typedef StringData (*StringGetter)(void*, std::size_t, char*); // Pre-declare getter function from string index
    size_t IndexStringFindFirst(StringData value, void* column, StringGetter get_func) const;
    void   IndexStringFindAll(Column& result, StringData value, void* column, StringGetter get_func) const;
    size_t IndexStringCount(StringData value, void* column, StringGetter get_func) const;
    FindRes IndexStringFindAllNoCopy(StringData value, size_t& res_ref, void* column, StringGetter get_func) const;

    /// This one may change the represenation of the array, so be carefull if
    /// you call it after ensure_minimum_width().
    void set_all_to_zero();

    /// Add \a diff to the element at the specified index.
    void adjust(std::size_t ndx, int_fast64_t diff);

    /// Add \a diff to all the elements in the specified index range.
    void adjust(std::size_t begin, std::size_t end, int_fast64_t diff);

    /// Add signed \a diff to all elements that are greater than, or equal to \a
    /// limit.
    void adjust_ge(int_fast64_t limit, int_fast64_t diff);

    //@{
    /// These are similar in spirit to std::move() and std::move_backward from
    /// <algorithm>. \a dest_begin must not be in the range [`begin`,`end`), and
    /// \a dest_end must not be in the range (`begin`,`end`].
    ///
    /// These functions are guaranteed to not throw if
    /// `get_alloc().is_read_only(get_ref())` returns false.
    void move(std::size_t begin, std::size_t end, std::size_t dest_begin);
    void move_backward(std::size_t begin, std::size_t end, std::size_t dest_end);
    //@}

    //@{
    /// Find the lower/upper bound of the specified value in a sequence of
    /// integers which must already be sorted ascendingly.
    ///
    /// For an integer value '`v`', lower_bound_int(v) returns the index '`l`'
    /// of the first element such that `get(l) &ge; v`, and upper_bound_int(v)
    /// returns the index '`u`' of the first element such that `get(u) &gt;
    /// v`. In both cases, if no such element is found, the returned value is
    /// the number of elements in the array.
    ///
    ///     3 3 3 4 4 4 5 6 7 9 9 9
    ///     ^     ^     ^     ^     ^
    ///     |     |     |     |     |
    ///     |     |     |     |      -- Lower and upper bound of 15
    ///     |     |     |     |
    ///     |     |     |      -- Lower and upper bound of 8
    ///     |     |     |
    ///     |     |      -- Upper bound of 4
    ///     |     |
    ///     |      -- Lower bound of 4
    ///     |
    ///      -- Lower and upper bound of 1
    ///
    /// These functions are similar to std::lower_bound() and
    /// std::upper_bound().
    ///
    /// We currently use binary search. See for example
    /// http://www.tbray.org/ongoing/When/200x/2003/03/22/Binary.
    ///
    /// FIXME: It may be worth considering if overall efficiency can be improved
    /// by doing a linear search for short sequences.
    std::size_t lower_bound_int(int64_t value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_int(int64_t value) const TIGHTDB_NOEXCEPT;
    //@}

    std::size_t FindGTE(int64_t target, std::size_t start, const Array* indirection) const;
    void Preset(int64_t min, int64_t max, std::size_t count);
    void Preset(std::size_t bitwidth, std::size_t count);

    int64_t sum(std::size_t start = 0, std::size_t end = std::size_t(-1)) const;
    std::size_t count(int64_t value) const TIGHTDB_NOEXCEPT;

    bool maximum(int64_t& result, std::size_t start = 0, std::size_t end = std::size_t(-1),
                 std::size_t* return_ndx = null_ptr) const;

    bool minimum(int64_t& result, std::size_t start = 0, std::size_t end = std::size_t(-1),
                 std::size_t* return_ndx = null_ptr) const;

    void sort();
    void ReferenceSort(Array& ref) const;

    /// This information is guaranteed to be cached in the array accessor.
    bool is_inner_bptree_node() const TIGHTDB_NOEXCEPT;

    /// Returns true if type is either type_HasRefs or type_InnerColumnNode.
    ///
    /// This information is guaranteed to be cached in the array accessor.
    bool has_refs() const TIGHTDB_NOEXCEPT;

    /// This information is guaranteed to be cached in the array accessor.
    ///
    /// Columns and indexes can use the context bit to differentiate leaf types.
    bool get_context_flag() const TIGHTDB_NOEXCEPT;
    void set_context_flag(bool) TIGHTDB_NOEXCEPT;

    ref_type get_ref() const TIGHTDB_NOEXCEPT;
    MemRef get_mem() const TIGHTDB_NOEXCEPT;

    /// Destroy only the array that this accessor is attached to, not the
    /// children of that array. See non-static destroy_deep() for an
    /// alternative. If this accessor is already in the detached state, this
    /// function has no effect (idempotency).
    void destroy() TIGHTDB_NOEXCEPT;

    /// Recursively destroy children (as if calling
    /// clear_and_destroy_children()), then put this accessor into the detached
    /// state (as if calling detach()), then free the allocated memory. If this
    /// accessor is already in the detached state, this function has no effect
    /// (idempotency).
    void destroy_deep() TIGHTDB_NOEXCEPT;

    /// Shorthand for `destroy(MemRef(ref, alloc), alloc)`.
    static void destroy(ref_type ref, Allocator& alloc) TIGHTDB_NOEXCEPT;

    /// Destroy only the specified array node, not its children. See also
    /// destroy_deep(MemRef, Allocator&).
    static void destroy(MemRef, Allocator&) TIGHTDB_NOEXCEPT;

    /// Shorthand for `destroy_deep(MemRef(ref, alloc), alloc)`.
    static void destroy_deep(ref_type ref, Allocator& alloc) TIGHTDB_NOEXCEPT;

    /// Destroy the specified array node and all of its children, recursively.
    ///
    /// This is done by freeing the specified array node after calling
    /// destroy_deep() for every contained 'ref' element.
    static void destroy_deep(MemRef, Allocator&) TIGHTDB_NOEXCEPT;

    Allocator& get_alloc() const TIGHTDB_NOEXCEPT { return m_alloc; }

    // Serialization

    /// Returns the position in the target where the first byte of this array
    /// was written.
    ///
    /// The number of bytes that will be written by a non-recursive invocation
    /// of this function is exactly the number returned by get_byte_size().
    template<class S>
    std::size_t write(S& target, bool recurse = true, bool persist = false) const;

    std::vector<int64_t> ToVector() const;

    /// Compare two arrays for equality.
    bool compare_int(const Array&) const TIGHTDB_NOEXCEPT;

    // Main finding function - used for find_first, find_all, sum, max, min, etc.
    bool find(int cond, Action action, int64_t value, size_t start, size_t end, size_t baseindex,
              QueryState<int64_t>* state) const;

    template<class cond, Action action, size_t bitwidth, class Callback>
    bool find(int64_t value, size_t start, size_t end, size_t baseindex,
              QueryState<int64_t>* state, Callback callback) const;

    // This is the one installed into the m_finder slots.
    template<class cond, Action action, size_t bitwidth>
    bool find(int64_t value, size_t start, size_t end, size_t baseindex,
              QueryState<int64_t>* state) const;

    template<class cond, Action action, class Callback>
    bool find(int64_t value, size_t start, size_t end, size_t baseindex,
              QueryState<int64_t>* state, Callback callback) const;

    // Optimized implementation for release mode
    template<class cond2, Action action, size_t bitwidth, class Callback>
    bool find_optimized(int64_t value, size_t start, size_t end, size_t baseindex,
                        QueryState<int64_t>* state, Callback callback) const;

    // Called for each search result
    template<Action action, class Callback>
    bool find_action(size_t index, int64_t value,
                     QueryState<int64_t>* state, Callback callback) const;

    template<Action action, class Callback>
    bool find_action_pattern(size_t index, uint64_t pattern,
                             QueryState<int64_t>* state, Callback callback) const;

    // Wrappers for backwards compatibility and for simple use without
    // setting up state initialization etc
    template<class cond>
    std::size_t find_first(int64_t value, std::size_t start = 0,
                           std::size_t end = std::size_t(-1)) const;

    void find_all(Column* result, int64_t value, std::size_t col_offset = 0,
                  std::size_t begin = 0, std::size_t end = std::size_t(-1)) const;

    std::size_t find_first(int64_t value, std::size_t begin = 0,
                           std::size_t end = size_t(-1)) const;

    // Non-SSE find for the four functions Equal/NotEqual/Less/Greater
    template<class cond2, Action action, size_t bitwidth, class Callback>
    bool Compare(int64_t value, size_t start, size_t end, size_t baseindex,
                 QueryState<int64_t>* state, Callback callback) const;

    // Non-SSE find for Equal/NotEqual
    template<bool eq, Action action, size_t width, class Callback>
    inline bool CompareEquality(int64_t value, size_t start, size_t end, size_t baseindex,
                                QueryState<int64_t>* state, Callback callback) const;

    // Non-SSE find for Less/Greater
    template<bool gt, Action action, size_t bitwidth, class Callback>
    bool CompareRelation(int64_t value, size_t start, size_t end, size_t baseindex,
                         QueryState<int64_t>* state, Callback callback) const;

    template<class cond, Action action, size_t foreign_width, class Callback, size_t width>
    bool CompareLeafs4(const Array* foreign, size_t start, size_t end, size_t baseindex,
                       QueryState<int64_t>* state, Callback callback) const;

    template<class cond, Action action, class Callback, size_t bitwidth, size_t foreign_bitwidth>
    bool CompareLeafs(const Array* foreign, size_t start, size_t end, size_t baseindex,
                      QueryState<int64_t>* state, Callback callback) const;

    template<class cond, Action action, class Callback>
    bool CompareLeafs(const Array* foreign, size_t start, size_t end, size_t baseindex,
                      QueryState<int64_t>* state, Callback callback) const;

    template<class cond, Action action, size_t width, class Callback>
    bool CompareLeafs(const Array* foreign, size_t start, size_t end, size_t baseindex,
                      QueryState<int64_t>* state, Callback callback) const;

    // SSE find for the four functions Equal/NotEqual/Less/Greater
#ifdef TIGHTDB_COMPILER_SSE
    template<class cond2, Action action, size_t width, class Callback>
    bool FindSSE(int64_t value, __m128i *data, size_t items, QueryState<int64_t>* state,
                 size_t baseindex, Callback callback) const;

    template<class cond2, Action action, size_t width, class Callback>
    TIGHTDB_FORCEINLINE bool FindSSE_intern(__m128i* action_data, __m128i* data, size_t items,
                                            QueryState<int64_t>* state, size_t baseindex,
                                            Callback callback) const;

#endif

    template<size_t width> inline bool TestZero(uint64_t value) const;         // Tests value for 0-elements
    template<bool eq, size_t width>size_t FindZero(uint64_t v) const;          // Finds position of 0/non-zero element
    template<size_t width> uint64_t cascade(uint64_t a) const;                 // Sets uppermost bits of non-zero elements
    template<bool gt, size_t width>int64_t FindGTLT_Magic(int64_t v) const;    // Compute magic constant needed for searching for value 'v' using bit hacks
    template<size_t width> inline int64_t LowerBits() const;                   // Return chunk with lower bit set in each element
    std::size_t FirstSetBit(unsigned int v) const;
    std::size_t FirstSetBit64(int64_t v) const;
    template<std::size_t w> int64_t GetUniversal(const char* const data, const std::size_t ndx) const;

    // Find value greater/less in 64-bit chunk - only works for positive values
    template<bool gt, Action action, std::size_t width, class Callback>
    bool FindGTLT_Fast(uint64_t chunk, uint64_t magic, QueryState<int64_t>* state, std::size_t baseindex,
                       Callback callback) const;

    // Find value greater/less in 64-bit chunk - no constraints
    template<bool gt, Action action, std::size_t width, class Callback>
    bool FindGTLT(int64_t v, uint64_t chunk, QueryState<int64_t>* state, std::size_t baseindex,
                  Callback callback) const;


    /// Get the number of elements in the B+-tree rooted at this array
    /// node. The root must not be a leaf.
    ///
    /// Please avoid using this function (consider it deprecated). It
    /// will have to be removed if we choose to get rid of the last
    /// element of the main array of an inner B+-tree node that stores
    /// the total number of elements in the subtree. The motivation
    /// for removing it, is that it will significantly improve the
    /// efficiency when inserting after, and erasing the last element.
    std::size_t get_bptree_size() const TIGHTDB_NOEXCEPT;

    /// The root must not be a leaf.
    static std::size_t get_bptree_size_from_header(const char* root_header) TIGHTDB_NOEXCEPT;


    /// Find the leaf node corresponding to the specified element
    /// index index. The specified element index must refer to an
    /// element that exists in the tree. This function must be called
    /// on an inner B+-tree node, never a leaf. Note that according to
    /// invar:bptree-nonempty-inner and invar:bptree-nonempty-leaf, an
    /// inner B+-tree node can never be empty.
    ///
    /// This function is not obliged to instantiate intermediate array
    /// accessors. For this reason, this function cannot be used for
    /// operations that modify the tree, as that requires an unbroken
    /// chain of parent array accessors between the root and the
    /// leaf. Thus, despite the fact that the returned MemRef object
    /// appears to allow modification of the referenced memory, the
    /// caller must handle the memory reference as if it was
    /// const-qualified.
    ///
    /// \return (`leaf_header`, `ndx_in_leaf`) where `leaf_header`
    /// points to the the header of the located leaf, and
    /// `ndx_in_leaf` is the local index within that leaf
    /// corresponding to the specified element index.
    std::pair<MemRef, std::size_t> get_bptree_leaf(std::size_t elem_ndx) const TIGHTDB_NOEXCEPT;


    class NodeInfo;
    class VisitHandler;

    /// Visit leaves of the B+-tree rooted at this inner node,
    /// starting with the leaf that contains the element at the
    /// specified element index start offset, and ending when the
    /// handler returns false. The specified element index offset must
    /// refer to an element that exists in the tree. This function
    /// must be called on an inner B+-tree node, never a leaf. Note
    /// that according to invar:bptree-nonempty-inner and
    /// invar:bptree-nonempty-leaf, an inner B+-tree node can never be
    /// empty.
    ///
    /// \param elems_in_tree The total number of element in the tree.
    ///
    /// \return True if, and only if the handler has returned true for
    /// all visited leafs.
    bool visit_bptree_leaves(std::size_t elem_ndx_offset, std::size_t elems_in_tree,
                             VisitHandler&);


    class UpdateHandler;

    /// Call the handler for every leaf. This function must be called
    /// on an inner B+-tree node, never a leaf.
    void update_bptree_leaves(UpdateHandler&);

    /// Call the handler for the leaf that contains the element at the
    /// specified index. This function must be called on an inner
    /// B+-tree node, never a leaf.
    void update_bptree_elem(std::size_t elem_ndx, UpdateHandler&);


    class EraseHandler;

    /// Erase the element at the specified index in the B+-tree with
    /// the specified root. When erasing the last element, you must
    /// pass npos in place of the index. This function must be called
    /// with a root that is an inner B+-tree node, never a leaf.
    ///
    /// This function is guaranteed to succeed (not throw) if the
    /// specified element was inserted during the current transaction,
    /// and no other modifying operation has been carried out since
    /// then (noexcept:bptree-erase-alt).
    ///
    /// FIXME: ExceptionSafety: The exception guarantee explained
    /// above is not as powerfull as we would like it to be. Here is
    /// what we would like: This function is guaranteed to succeed
    /// (not throw) if the specified element was inserted during the
    /// current transaction (noexcept:bptree-erase). This must be true
    /// even if the element is modified after insertion, and/or if
    /// other elements are inserted or erased around it. There are two
    /// aspects of the current design that stand in the way of this
    /// guarantee: (A) The fact that the node accessor, that is cached
    /// in the column accessor, has to be reallocated/reinstantiated
    /// when the root switches between being a leaf and an inner
    /// node. This problem would go away if we always cached the last
    /// used leaf accessor in the column accessor instead. (B) The
    /// fact that replacing one child ref with another can fail,
    /// because it may require reallocation of memory to expand the
    /// bit-width. This can be fixed in two ways: Either have the
    /// inner B+-tree nodes always have a bit-width of 64, or allow
    /// the root node to be discarded and the column ref to be set to
    /// zero in Table::m_columns.
    static void erase_bptree_elem(Array* root, std::size_t elem_ndx, EraseHandler&);


    struct TreeInsertBase {
        std::size_t m_split_offset;
        std::size_t m_split_size;
    };

    template<class TreeTraits> struct TreeInsert: TreeInsertBase {
        typename TreeTraits::value_type m_value;
    };

    /// Same as bptree_insert() but insert after the last element.
    template<class TreeTraits>
    ref_type bptree_append(TreeInsert<TreeTraits>& state);

    /// Insert an element into the B+-subtree rooted at this array
    /// node. The element is inserted before the specified element
    /// index. This function must be called on an inner B+-tree node,
    /// never a leaf. If this inner node had to be split, this
    /// function returns the `ref` of the new sibling.
    template<class TreeTraits>
    ref_type bptree_insert(std::size_t elem_ndx, TreeInsert<TreeTraits>& state);

    ref_type bptree_leaf_insert(std::size_t ndx, int64_t, TreeInsertBase& state);

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static int_fast64_t get(const char* header, std::size_t ndx) TIGHTDB_NOEXCEPT;

    /// Like get(const char*, std::size_t) but gets two consecutive
    /// elements.
    static std::pair<int_least64_t, int_least64_t> get_two(const char* header,
                                                           std::size_t ndx) TIGHTDB_NOEXCEPT;

    /// The meaning of 'width' depends on the context in which this
    /// array is used.
    std::size_t get_width() const TIGHTDB_NOEXCEPT { return m_width; }

    // FIXME: Should not be mutable
    // FIXME: Should not be public
    mutable char* m_data; // Points to first byte after header

    static char* get_data_from_header(char*) TIGHTDB_NOEXCEPT;
    static char* get_header_from_data(char*) TIGHTDB_NOEXCEPT;
    static const char* get_data_from_header(const char*) TIGHTDB_NOEXCEPT;

    enum WidthType {
        wtype_Bits     = 0,
        wtype_Multiply = 1,
        wtype_Ignore   = 2
    };

    static bool get_is_inner_bptree_node_from_header(const char*) TIGHTDB_NOEXCEPT;
    static bool get_hasrefs_from_header(const char*) TIGHTDB_NOEXCEPT;
    static bool get_context_flag_from_header(const char*) TIGHTDB_NOEXCEPT;
    static WidthType get_wtype_from_header(const char*) TIGHTDB_NOEXCEPT;
    static int get_width_from_header(const char*) TIGHTDB_NOEXCEPT;
    static std::size_t get_size_from_header(const char*) TIGHTDB_NOEXCEPT;

    static Type get_type_from_header(const char*) TIGHTDB_NOEXCEPT;

    /// Get the number of bytes currently in use by this array. This
    /// includes the array header, but it does not include allocated
    /// bytes corresponding to excess capacity. The result is
    /// guaranteed to be a multiple of 8 (i.e., 64-bit aligned).
    ///
    /// This number is exactly the number of bytes that will be
    /// written by a non-recursive invocation of write().
    std::size_t get_byte_size() const TIGHTDB_NOEXCEPT;

    /// Get the maximum number of bytes that can be written by a
    /// non-recursive invocation of write() on an array with the
    /// specified number of elements, that is, the maximum value that
    /// can be returned by get_byte_size().
    static std::size_t get_max_byte_size(std::size_t num_elems) TIGHTDB_NOEXCEPT;

    /// FIXME: Belongs in IntegerArray
    static std::size_t calc_aligned_byte_size(std::size_t size, int width);

#ifdef TIGHTDB_DEBUG
    void print() const;
    void Verify() const;
    typedef std::size_t (*LeafVerifier)(MemRef, Allocator&);
    void verify_bptree(LeafVerifier) const;
    class MemUsageHandler {
    public:
        virtual void handle(ref_type ref, std::size_t allocated, std::size_t used) = 0;
    };
    void report_memory_usage(MemUsageHandler&) const;
    void stats(MemStats& stats) const;
    typedef void (*LeafDumper)(MemRef, Allocator&, std::ostream&, int level);
    void dump_bptree_structure(std::ostream&, int level, LeafDumper) const;
    void to_dot(std::ostream&, StringData title = StringData()) const;
    class ToDotHandler {
    public:
        virtual void to_dot(MemRef leaf_mem, ArrayParent*, std::size_t ndx_in_parent,
                            std::ostream&) = 0;
        ~ToDotHandler() {}
    };
    void bptree_to_dot(std::ostream&, ToDotHandler&) const;
    void to_dot_parent_edge(std::ostream&) const;
#endif

protected:
    static const int header_size = 8; // Number of bytes used by header

private:
    typedef bool (*CallbackDummy)(int64_t);

    template<size_t w> bool MinMax(size_t from, size_t to, uint64_t maxdiff,
                                   int64_t* min, int64_t* max) const;
    Array& operator=(const Array&); // not allowed
    template<size_t w> void QuickSort(size_t lo, size_t hi);
    void QuickSort(size_t lo, size_t hi);
    void ReferenceQuickSort(Array& ref) const;
    template<size_t w> void ReferenceQuickSort(size_t lo, size_t hi, Array& ref) const;

    template<size_t w> void sort();
    template<size_t w> void ReferenceSort(Array& ref) const;

    template<size_t w> int64_t sum(size_t start, size_t end) const;

    /// Insert a new child after original. If the parent has to be
    /// split, this function returns the `ref` of the new parent node.
    ref_type insert_bptree_child(Array& offsets, std::size_t orig_child_ndx,
                                 ref_type new_sibling_ref, TreeInsertBase& state);

    void ensure_bptree_offsets(Array& offsets);
    void create_bptree_offsets(Array& offsets, int_fast64_t first_value);

    bool do_erase_bptree_elem(std::size_t elem_ndx, EraseHandler&);


    template <IndexMethod method, class T> size_t index_string(StringData value, Column& result, size_t &result_ref, void* column, StringGetter get_func) const;
protected:
//    void AddPositiveLocal(int64_t value);

    void CreateFromHeaderDirect(char* header, ref_type = 0) TIGHTDB_NOEXCEPT;

    // Includes array header. Not necessarily 8-byte aligned.
    virtual std::size_t CalcByteLen(std::size_t size, std::size_t width) const;

    virtual std::size_t CalcItemCount(std::size_t bytes, std::size_t width) const TIGHTDB_NOEXCEPT;
    virtual WidthType GetWidthType() const { return wtype_Bits; }

    bool get_is_inner_bptree_node_from_header() const TIGHTDB_NOEXCEPT;
    bool get_hasrefs_from_header() const TIGHTDB_NOEXCEPT;
    bool get_context_flag_from_header() const TIGHTDB_NOEXCEPT;
    WidthType get_wtype_from_header() const TIGHTDB_NOEXCEPT;
    int get_width_from_header() const TIGHTDB_NOEXCEPT;
    std::size_t get_size_from_header() const TIGHTDB_NOEXCEPT;

    // Undefined behavior if m_alloc.is_read_only(m_ref) returns true
    std::size_t get_capacity_from_header() const TIGHTDB_NOEXCEPT;

    void set_header_is_inner_bptree_node(bool value) TIGHTDB_NOEXCEPT;
    void set_header_hasrefs(bool value) TIGHTDB_NOEXCEPT;
    void set_header_context_flag(bool value) TIGHTDB_NOEXCEPT;
    void set_header_wtype(WidthType value) TIGHTDB_NOEXCEPT;
    void set_header_width(int value) TIGHTDB_NOEXCEPT;
    void set_header_size(std::size_t value) TIGHTDB_NOEXCEPT;
    void set_header_capacity(std::size_t value) TIGHTDB_NOEXCEPT;

    static void set_header_is_inner_bptree_node(bool value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_hasrefs(bool value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_context_flag(bool value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_wtype(WidthType value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_width(int value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_size(std::size_t value, char* header) TIGHTDB_NOEXCEPT;
    static void set_header_capacity(std::size_t value, char* header) TIGHTDB_NOEXCEPT;

    static void init_header(char* header, bool is_inner_bptree_node, bool has_refs,
                            bool context_flag, WidthType width_type, int width,
                            std::size_t size, std::size_t capacity) TIGHTDB_NOEXCEPT;

    template<std::size_t width> void set_width() TIGHTDB_NOEXCEPT;
    void set_width(std::size_t) TIGHTDB_NOEXCEPT;
    void alloc(std::size_t count, std::size_t width);
    void copy_on_write();

private:
    std::size_t m_ref;
    template<bool max, std::size_t w> bool minmax(int64_t& result, std::size_t start,
                                                  std::size_t end, std::size_t* return_ndx) const;

protected:
    std::size_t m_size;     // Number of elements currently stored.
    std::size_t m_capacity; // Number of elements that fit inside the allocated memory.
// FIXME: m_width Should be an 'int'
    std::size_t m_width;    // Size of an element (meaning depend on type of array).
    bool m_is_inner_bptree_node; // This array is an inner node of B+-tree.
    bool m_has_refs;        // Elements whose first bit is zero are refs to subarrays.
    bool m_context_flag;    // Meaning depends on context.

private:
    ArrayParent* m_parent;
    std::size_t m_ndx_in_parent; // Ignored if m_parent is null.

protected:
    Allocator& m_alloc;

    /// The total size in bytes (including the header) of a new empty
    /// array. Must be a multiple of 8 (i.e., 64-bit aligned).
    static const std::size_t initial_capacity = 128;

    /// It is an error to specify a non-zero value unless the width
    /// type is wtype_Bits. It is also an error to specify a non-zero
    /// size if the width type is wtype_Ignore.
    static MemRef create(Type, bool context_flag, WidthType, std::size_t size,
                         int_fast64_t value, Allocator&);

    static MemRef clone(const char* header, Allocator& alloc, Allocator& target_alloc);

    /// Get the address of the header of this array.
    char* get_header() TIGHTDB_NOEXCEPT;

    /// Same as get_byte_size().
    static std::size_t get_byte_size_from_header(const char*) TIGHTDB_NOEXCEPT;

    // Undefined behavior if array is in immutable memory
    static std::size_t get_capacity_from_header(const char*) TIGHTDB_NOEXCEPT;

    // Overriding method in ArrayParent
    void update_child_ref(std::size_t, ref_type) TIGHTDB_OVERRIDE;

    // Overriding method in ArrayParent
    ref_type get_child_ref(std::size_t) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void destroy_children(std::size_t offset = 0) TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_DEBUG
    std::pair<ref_type, std::size_t>
    get_to_dot_parent(std::size_t ndx_in_parent) const TIGHTDB_OVERRIDE;
#endif

// FIXME: below should be moved to a specific IntegerArray class
protected:
    // Getters and Setters for adaptive-packed arrays
    typedef int64_t (Array::*Getter)(std::size_t) const; // Note: getters must not throw
    typedef void (Array::*Setter)(std::size_t, int64_t);
    typedef bool (Array::*Finder)(int64_t, std::size_t, std::size_t, std::size_t, QueryState<int64_t>*) const;
    typedef void (Array::*ChunkGetter)(size_t, int64_t res[8]) const; // Note: getters must not throw

private:
    Getter m_getter;
    ChunkGetter m_chunk_getter;
    Setter m_setter;
    Finder m_finder[cond_Count]; // one for each COND_XXX enum

    int64_t m_lbound;       // min number that can be stored with current m_width
    int64_t m_ubound;       // max number that can be stored with current m_width

#ifdef TIGHTDB_DEBUG
    void report_memory_usage_2(MemUsageHandler&) const;
#endif

    friend class SlabAlloc;
    friend class GroupWriter;
    friend class AdaptiveStringColumn;
};



class Array::NodeInfo {
public:
    MemRef m_mem;
    Array* m_parent;
    std::size_t m_ndx_in_parent;
    std::size_t m_offset, m_size;
};

class Array::VisitHandler {
public:
    virtual bool visit(const NodeInfo& leaf_info) = 0;
    virtual ~VisitHandler() TIGHTDB_NOEXCEPT {}
};


class Array::UpdateHandler {
public:
    virtual void update(MemRef, ArrayParent*, std::size_t leaf_ndx_in_parent,
                        std::size_t elem_ndx_in_leaf) = 0;
    virtual ~UpdateHandler() TIGHTDB_NOEXCEPT {}
};


class Array::EraseHandler {
public:
    /// If the specified leaf has more than one element, this function
    /// must erase the specified element from the leaf and return
    /// false. Otherwise, when the leaf has a single element, this
    /// function must return true without modifying the leaf. If \a
    /// elem_ndx_in_leaf is `npos`, it refers to the last element in
    /// the leaf. The implementation of this function must be
    /// exception safe. This function is guaranteed to be called at
    /// most once during each execution of Array::erase_bptree_elem(),
    /// and *exactly* once during each *successful* execution of
    /// Array::erase_bptree_elem().
    virtual bool erase_leaf_elem(MemRef, ArrayParent*,
                                 std::size_t leaf_ndx_in_parent,
                                 std::size_t elem_ndx_in_leaf) = 0;

    virtual void destroy_leaf(MemRef leaf_mem) TIGHTDB_NOEXCEPT = 0;

    /// Must replace the current root with the specified leaf. The
    /// implementation of this function must not destroy the
    /// underlying root node, or any of its children, as that will be
    /// done by Array::erase_bptree_elem(). The implementation of this
    /// function must be exception safe.
    virtual void replace_root_by_leaf(MemRef leaf_mem) = 0;

    /// Same as replace_root_by_leaf(), but must replace the root with
    /// an empty leaf. Also, if this function is called during an
    /// execution of Array::erase_bptree_elem(), it is guaranteed that
    /// it will be preceeded by a call to erase_leaf_elem().
    virtual void replace_root_by_empty_leaf() = 0;

    virtual ~EraseHandler() TIGHTDB_NOEXCEPT {}
};





// Implementation:

class QueryStateBase { virtual void dyncast(){} };

template<> class QueryState<int64_t>: public QueryStateBase {
public:
    int64_t m_state;
    size_t m_match_count;
    size_t m_limit;
    size_t m_minmax_index; // used only for min/max, to save index of current min/max value

    template<Action action> bool uses_val()
    {
        if (action == act_Max || action == act_Min || action == act_Sum)
            return true;
        else
            return false;
    }

    void init(Action action, Column* akku, size_t limit)
    {
        m_match_count = 0;
        m_limit = limit;
        m_minmax_index = not_found;

        if (action == act_Max)
            m_state = -0x7fffffffffffffffLL - 1LL;
        else if (action == act_Min)
            m_state = 0x7fffffffffffffffLL;
        else if (action == act_ReturnFirst)
            m_state = not_found;
        else if (action == act_Sum)
            m_state = 0;
        else if (action == act_Count)
            m_state = 0;
        else if (action == act_FindAll)
            m_state = reinterpret_cast<int64_t>(akku);
        else if (action == act_CallbackIdx) {
        }
        else
            TIGHTDB_ASSERT(false);
    }

    template <Action action, bool pattern>
    inline bool match(size_t index, uint64_t indexpattern, int64_t value)
    {
        if (pattern) {
            if (action == act_Count) {
                // If we are close to 'limit' argument in query, we cannot count-up a complete chunk. Count up single
                // elements instead
                if (m_match_count + 64 >= m_limit)
                    return false;

                m_state += fast_popcount64(indexpattern);
                m_match_count = size_t(m_state);
                return true;
            }
            // Other aggregates cannot (yet) use bit pattern for anything. Make Array-finder call with pattern = false instead
            return false;
        }

        ++m_match_count;

        if (action == act_Max) {
            if (value > m_state) {
                m_state = value;
                m_minmax_index = index;
            }
        }
        else if (action == act_Min) {
            if (value < m_state) {
                m_state = value;
                m_minmax_index = index;
            }
        }
        else if (action == act_Sum)
            m_state += value;
        else if (action == act_Count) {
            m_state++;
            m_match_count = size_t(m_state);
        }
        else if (action == act_FindAll) {
            Array::add_to_column(reinterpret_cast<Column*>(m_state), index);
        }
        else if (action == act_ReturnFirst) {
            m_state = index;
            return false;
        }
        else
            TIGHTDB_ASSERT(false);

        return (m_limit > m_match_count);
    }
};

// Used only for Basic-types: currently float and double
template<class R> class QueryState : public QueryStateBase {
public:
    R m_state;
    size_t m_match_count;
    size_t m_limit;
    size_t m_minmax_index; // used only for min/max, to save index of current min/max value

    template<Action action> bool uses_val()
    {
        return (action == act_Max || action == act_Min || action == act_Sum);
    }

    void init(Action action, Array*, size_t limit)
    {
        TIGHTDB_STATIC_ASSERT((util::SameType<R, float>::value ||
                               util::SameType<R, double>::value), "");
        m_match_count = 0;
        m_limit = limit;
        m_minmax_index = not_found;

        if (action == act_Max)
            m_state = -std::numeric_limits<R>::infinity();
        else if (action == act_Min)
            m_state = std::numeric_limits<R>::infinity();
        else if (action == act_Sum)
            m_state = 0.0;
        else
            TIGHTDB_ASSERT(false);
    }

    template<Action action, bool pattern, typename resulttype>
    inline bool match(size_t index, uint64_t /*indexpattern*/, resulttype value)
    {
        if (pattern)
            return false;

        TIGHTDB_STATIC_ASSERT(action == act_Sum || action == act_Max || action == act_Min, "");
        ++m_match_count;

        if (action == act_Max) {
            if (value > m_state) {
                m_state = value;
                m_minmax_index = index;
            }
        }
        else if (action == act_Min) {
            if (value < m_state) {
                m_state = value;
                m_minmax_index = index;
            }
        }
        else if (action == act_Sum)
            m_state += value;
        else
            TIGHTDB_ASSERT(false);

        return (m_limit > m_match_count);
    }
};



inline Array::Array(Allocator& alloc) TIGHTDB_NOEXCEPT:
    m_data(0),
    m_parent(0),
    m_ndx_in_parent(0),
    m_alloc(alloc)
{
}

// Fastest way to instantiate an Array. For use with GetDirect() that only fills out m_width, m_data
// and a few other basic things needed for read-only access. Or for use if you just want a way to call
// some methods written in Array.*
inline Array::Array(no_prealloc_tag) TIGHTDB_NOEXCEPT:
    m_alloc(*static_cast<Allocator*>(0))
{
}


inline void Array::create(Type type, bool context_flag)
{
    MemRef mem = create_empty_array(type, context_flag, m_alloc); // Throws
    init_from_mem(mem);
}


inline void Array::init_from_ref(ref_type ref) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ref);
    char* header = m_alloc.translate(ref);
    init_from_mem(MemRef(header, ref));
}


inline void Array::init_from_parent() TIGHTDB_NOEXCEPT
{
    ref_type ref = get_ref_from_parent();
    init_from_ref(ref);
}


inline Array::Type Array::get_type() const TIGHTDB_NOEXCEPT
{
    if (m_is_inner_bptree_node) {
        TIGHTDB_ASSERT(m_has_refs);
        return type_InnerBptreeNode;
    }
    if (m_has_refs)
        return type_HasRefs;
    return type_Normal;
}


inline void Array::get_chunk(std::size_t ndx, int64_t res[8]) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_size);
    (this->*m_chunk_getter)(ndx, res);
}


inline int64_t Array::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(ndx < m_size);
    return (this->*m_getter)(ndx);

// Two ideas that are not efficient but may be worth looking into again:
/*
    // Assume correct width is found early in TIGHTDB_TEMPEX, which is the case for B tree offsets that
    // are probably either 2^16 long. Turns out to be 25% faster if found immediately, but 50-300% slower
    // if found later
    TIGHTDB_TEMPEX(return Get, (ndx));
*/
/*
    // Slightly slower in both of the if-cases. Also needs an matchcount m_size check too, to avoid
    // reading beyond array.
    if (m_width >= 8 && m_size > ndx + 7)
        return Get<64>(ndx >> m_shift) & m_widthmask;
    else
        return (this->*m_getter)(ndx);
*/
}

inline int64_t Array::front() const TIGHTDB_NOEXCEPT
{
    return get(0);
}

inline int64_t Array::back() const TIGHTDB_NOEXCEPT
{
    return get(m_size - 1);
}

inline ref_type Array::get_as_ref(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(m_has_refs);
    int64_t v = get(ndx);
    return to_ref(v);
}

inline bool Array::is_inner_bptree_node() const TIGHTDB_NOEXCEPT
{
    return m_is_inner_bptree_node;
}

inline bool Array::has_refs() const TIGHTDB_NOEXCEPT
{
    return m_has_refs;
}

inline bool Array::get_context_flag() const TIGHTDB_NOEXCEPT
{
    return m_context_flag;
}

inline void Array::set_context_flag(bool value) TIGHTDB_NOEXCEPT
{
    m_context_flag = value;
    set_header_context_flag(value);
}

inline ref_type Array::get_ref() const TIGHTDB_NOEXCEPT
{
    return m_ref;
}

inline MemRef Array::get_mem() const TIGHTDB_NOEXCEPT
{
    return MemRef(get_header_from_data(m_data), m_ref);
}

inline void Array::destroy() TIGHTDB_NOEXCEPT
{
    if (!is_attached())
        return;
    char* header = get_header_from_data(m_data);
    m_alloc.free_(m_ref, header);
    m_data = 0;
}

inline void Array::destroy_deep() TIGHTDB_NOEXCEPT
{
    if (!is_attached())
        return;

    if (m_has_refs)
        destroy_children();

    char* header = get_header_from_data(m_data);
    m_alloc.free_(m_ref, header);
    m_data = 0;
}


inline void Array::add(int_fast64_t value)
{
    insert(m_size, value);
}


inline void Array::erase(std::size_t ndx)
{
    // This can throw, but only if array is currently in read-only
    // memory.
    move(ndx+1, size(), ndx);

    // Update size (also in header)
    --m_size;
    set_header_size(m_size);
}


inline void Array::erase(std::size_t begin, std::size_t end)
{
    if (begin != end) {
        // This can throw, but only if array is currently in read-only memory.
        move(end, size(), begin); // Throws

        // Update size (also in header)
        m_size -= end - begin;
        set_header_size(m_size);
    }
}

inline void Array::clear()
{
    truncate(0); // Throws
}

inline void Array::clear_and_destroy_children()
{
    truncate_and_destroy_children(0);
}

inline void Array::destroy(ref_type ref, Allocator& alloc) TIGHTDB_NOEXCEPT
{
    destroy(MemRef(ref, alloc), alloc);
}

inline void Array::destroy(MemRef mem, Allocator& alloc) TIGHTDB_NOEXCEPT
{
    alloc.free_(mem);
}

inline void Array::destroy_deep(ref_type ref, Allocator& alloc) TIGHTDB_NOEXCEPT
{
    destroy_deep(MemRef(ref, alloc), alloc);
}

inline void Array::destroy_deep(MemRef mem, Allocator& alloc) TIGHTDB_NOEXCEPT
{
    if (!get_hasrefs_from_header(mem.m_addr)) {
        alloc.free_(mem);
        return;
    }
    Array array(alloc);
    array.init_from_mem(mem);
    array.destroy_deep();
}


inline void Array::adjust(std::size_t ndx, int_fast64_t diff)
{
    // FIXME: Should be optimized
    TIGHTDB_ASSERT(ndx <= m_size);
    int_fast64_t v = get(ndx);
    set(ndx, int64_t(v + diff)); // Throws
}

inline void Array::adjust(std::size_t begin, std::size_t end, int_fast64_t diff)
{
    // FIXME: Should be optimized
    for (std::size_t i = begin; i != end; ++i)
        adjust(i, diff); // Throws
}

inline void Array::adjust_ge(int_fast64_t limit, int_fast64_t diff)
{
    size_t n = size();
    for (std::size_t i = 0; i != n; ++i) {
        int_fast64_t v = get(i);
        if (v >= limit)
            set(i, int64_t(v + diff)); // Throws
    }
}



//-------------------------------------------------

inline bool Array::get_is_inner_bptree_node_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (int(h[4]) & 0x80) != 0;
}
inline bool Array::get_hasrefs_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (int(h[4]) & 0x40) != 0;
}
inline bool Array::get_context_flag_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (int(h[4]) & 0x20) != 0;
}
inline Array::WidthType Array::get_wtype_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return WidthType((int(h[4]) & 0x18) >> 3);
}
inline int Array::get_width_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (1 << (int(h[4]) & 0x07)) >> 1;
}
inline std::size_t Array::get_size_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (std::size_t(h[5]) << 16) + (std::size_t(h[6]) << 8) + h[7];
}
inline std::size_t Array::get_capacity_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    const uchar* h = reinterpret_cast<const uchar*>(header);
    return (std::size_t(h[0]) << 16) + (std::size_t(h[1]) << 8) + h[2];
}


inline char* Array::get_data_from_header(char* header) TIGHTDB_NOEXCEPT
{
    return header + header_size;
}
inline char* Array::get_header_from_data(char* data) TIGHTDB_NOEXCEPT
{
    return data - header_size;
}
inline const char* Array::get_data_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    return get_data_from_header(const_cast<char*>(header));
}


inline bool Array::get_is_inner_bptree_node_from_header() const TIGHTDB_NOEXCEPT
{
    return get_is_inner_bptree_node_from_header(get_header_from_data(m_data));
}
inline bool Array::get_hasrefs_from_header() const TIGHTDB_NOEXCEPT
{
    return get_hasrefs_from_header(get_header_from_data(m_data));
}
inline bool Array::get_context_flag_from_header() const TIGHTDB_NOEXCEPT
{
    return get_context_flag_from_header(get_header_from_data(m_data));
}
inline Array::WidthType Array::get_wtype_from_header() const TIGHTDB_NOEXCEPT
{
    return get_wtype_from_header(get_header_from_data(m_data));
}
inline int Array::get_width_from_header() const TIGHTDB_NOEXCEPT
{
    return get_width_from_header(get_header_from_data(m_data));
}
inline std::size_t Array::get_size_from_header() const TIGHTDB_NOEXCEPT
{
    return get_size_from_header(get_header_from_data(m_data));
}
inline std::size_t Array::get_capacity_from_header() const TIGHTDB_NOEXCEPT
{
    return get_capacity_from_header(get_header_from_data(m_data));
}


inline void Array::set_header_is_inner_bptree_node(bool value, char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[4] = uchar((int(h[4]) & ~0x80) | int(value) << 7);
}

inline void Array::set_header_hasrefs(bool value, char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[4] = uchar((int(h[4]) & ~0x40) | int(value) << 6);
}

inline void Array::set_header_context_flag(bool value, char* header) TIGHTDB_NOEXCEPT
{
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[4] = uchar((int(h[4]) & ~0x20) | int(value) << 5);
}

inline void Array::set_header_wtype(WidthType value, char* header) TIGHTDB_NOEXCEPT
{
    // Indicates how to calculate size in bytes based on width
    // 0: bits      (width/8) * size
    // 1: multiply  width * size
    // 2: ignore    1 * size
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[4] = uchar((int(h[4]) & ~0x18) | int(value) << 3);
}

inline void Array::set_header_width(int value, char* header) TIGHTDB_NOEXCEPT
{
    // Pack width in 3 bits (log2)
    int w = 0;
    while (value) {
        ++w;
        value >>= 1;
    }
    TIGHTDB_ASSERT(w < 8);

    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[4] = uchar((int(h[4]) & ~0x7) | w);
}

inline void Array::set_header_size(std::size_t value, char* header) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(value <= 0xFFFFFFL);
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[5] = uchar((value >> 16) & 0x000000FF);
    h[6] = uchar((value >>  8) & 0x000000FF);
    h[7] = uchar( value        & 0x000000FF);
}

// Note: There is a copy of this function is test_alloc.cpp
inline void Array::set_header_capacity(std::size_t value, char* header) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(value <= 0xFFFFFFL);
    typedef unsigned char uchar;
    uchar* h = reinterpret_cast<uchar*>(header);
    h[0] = uchar((value >> 16) & 0x000000FF);
    h[1] = uchar((value >>  8) & 0x000000FF);
    h[2] = uchar( value        & 0x000000FF);
}



inline void Array::set_header_is_inner_bptree_node(bool value) TIGHTDB_NOEXCEPT
{
    set_header_is_inner_bptree_node(value, get_header_from_data(m_data));
}
inline void Array::set_header_hasrefs(bool value) TIGHTDB_NOEXCEPT
{
    set_header_hasrefs(value, get_header_from_data(m_data));
}
inline void Array::set_header_context_flag(bool value) TIGHTDB_NOEXCEPT
{
    set_header_context_flag(value, get_header_from_data(m_data));
}
inline void Array::set_header_wtype(WidthType value) TIGHTDB_NOEXCEPT
{
    set_header_wtype(value, get_header_from_data(m_data));
}
inline void Array::set_header_width(int value) TIGHTDB_NOEXCEPT
{
    set_header_width(value, get_header_from_data(m_data));
}
inline void Array::set_header_size(std::size_t value) TIGHTDB_NOEXCEPT
{
    set_header_size(value, get_header_from_data(m_data));
}
inline void Array::set_header_capacity(std::size_t value) TIGHTDB_NOEXCEPT
{
    set_header_capacity(value, get_header_from_data(m_data));
}


inline Array::Type Array::get_type_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    if (get_is_inner_bptree_node_from_header(header))
        return type_InnerBptreeNode;
    if (get_hasrefs_from_header(header))
        return type_HasRefs;
    return type_Normal;
}


inline char* Array::get_header() TIGHTDB_NOEXCEPT
{
    return get_header_from_data(m_data);
}


inline std::size_t Array::get_byte_size() const TIGHTDB_NOEXCEPT
{
    std::size_t num_bytes = 0;
    const char* header = get_header_from_data(m_data);
    switch (get_wtype_from_header(header)) {
        case wtype_Bits: {
            // FIXME: The following arithmetic could overflow, that
            // is, even though both the total number of elements and
            // the total number of bytes can be represented in
            // uint_fast64_t, the total number of bits may not
            // fit. Note that "num_bytes = width < 8 ? size / (8 /
            // width) : size * (width / 8)" would be guaranteed to
            // never overflow, but it potentially involves two slow
            // divisions.
            uint_fast64_t num_bits = uint_fast64_t(m_size) * m_width;
            num_bytes = std::size_t(num_bits / 8);
            if (num_bits & 0x7)
                ++num_bytes;
            goto found;
        }
        case wtype_Multiply: {
            num_bytes = m_size * m_width;
            goto found;
        }
        case wtype_Ignore:
            num_bytes = m_size;
            goto found;
    }
    TIGHTDB_ASSERT(false);

  found:
    // Ensure 8-byte alignment
    std::size_t rest = (~num_bytes & 0x7) + 1;
    if (rest < 8)
        num_bytes += rest;

    num_bytes += header_size;

    TIGHTDB_ASSERT(m_alloc.is_read_only(m_ref) ||
                   num_bytes <= get_capacity_from_header(header));

    return num_bytes;
}


inline std::size_t Array::get_byte_size_from_header(const char* header) TIGHTDB_NOEXCEPT
{
    std::size_t num_bytes = 0;
    std::size_t size = get_size_from_header(header);
    switch (get_wtype_from_header(header)) {
        case wtype_Bits: {
            int width = get_width_from_header(header);
            std::size_t num_bits = (size * width); // FIXME: Prone to overflow
            num_bytes = num_bits / 8;
            if (num_bits & 0x7)
                ++num_bytes;
            goto found;
        }
        case wtype_Multiply: {
            int width = get_width_from_header(header);
            num_bytes = size * width;
            goto found;
        }
        case wtype_Ignore:
            num_bytes = size;
            goto found;
    }
    TIGHTDB_ASSERT(false);

  found:
    // Ensure 8-byte alignment
    std::size_t rest = (~num_bytes & 0x7) + 1;
    if (rest < 8)
        num_bytes += rest;

    num_bytes += header_size;

    return num_bytes;
}


inline void Array::init_header(char* header, bool is_inner_bptree_node, bool has_refs,
                               bool context_flag, WidthType width_type, int width,
                               std::size_t size, std::size_t capacity) TIGHTDB_NOEXCEPT
{
    // Note: Since the header layout contains unallocated bit and/or
    // bytes, it is important that we put the entire header into a
    // well defined state initially.
    std::fill(header, header + header_size, 0);
    set_header_is_inner_bptree_node(is_inner_bptree_node, header);
    set_header_hasrefs(has_refs, header);
    set_header_context_flag(context_flag, header);
    set_header_wtype(width_type, header);
    set_header_width(width, header);
    set_header_size(size, header);
    set_header_capacity(capacity, header);
}


//-------------------------------------------------

template<class S> std::size_t Array::write(S& out, bool recurse, bool persist) const
{
    TIGHTDB_ASSERT(is_attached());

    // Ignore un-changed arrays when persisting
    if (persist && m_alloc.is_read_only(m_ref))
        return m_ref;

    if (!recurse || !m_has_refs) {
        // FIXME: Replace capacity with checksum

        // Write flat array
        const char* header = get_header_from_data(m_data);
        std::size_t size = get_byte_size();
        uint_fast32_t dummy_checksum = 0x01010101UL;
        std::size_t array_pos = out.write_array(header, size, dummy_checksum);
        TIGHTDB_ASSERT(array_pos % 8 == 0); // 8-byte alignment

        return array_pos;
    }

    // Temp array for updated refs
    Array new_refs(Allocator::get_default());
    Type type = m_is_inner_bptree_node ? type_InnerBptreeNode : type_HasRefs;
    new_refs.create(type, m_context_flag); // Throws

    try {
        // First write out all sub-arrays
        std::size_t n = size();
        for (std::size_t i = 0; i != n; ++i) {
            int_fast64_t value = get(i);
            if (value == 0 || value % 2 != 0) {
                // Zero-refs and values that are not 8-byte aligned do
                // not point to subarrays.
                new_refs.add(value); // Throws
            }
            else if (persist && m_alloc.is_read_only(to_ref(value))) {
                // Ignore un-changed arrays when persisting
                new_refs.add(value); // Throws
            }
            else {
                Array sub(get_alloc());
                sub.init_from_ref(to_ref(value));
                bool subrecurse = true;
                std::size_t sub_pos = sub.write(out, subrecurse, persist); // Throws
                TIGHTDB_ASSERT(sub_pos % 8 == 0); // 8-byte alignment
                new_refs.add(sub_pos); // Throws
            }
        }

        // Write out the replacement array
        // (but don't write sub-tree as it has alredy been written)
        bool subrecurse = false;
        std::size_t refs_pos = new_refs.write(out, subrecurse, persist); // Throws

        new_refs.destroy(); // Shallow

        return refs_pos; // Return position
    }
    catch (...) {
        new_refs.destroy(); // Shallow
        throw;
    }
}

inline MemRef Array::clone_deep(Allocator& target_alloc) const
{
    const char* header = get_header_from_data(m_data);
    return clone(header, m_alloc, target_alloc); // Throws
}

inline void Array::move_assign(Array& a) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(&get_alloc() == &a.get_alloc());
    // FIXME: Be carefull with the old parent info here. Should it be
    // copied?

    // FIXME: It will likely be a lot better for the optimizer if we
    // did a member-wise copy, rather than recreating the state from
    // the referenced data. This is important because TableView efficiency, for
    // example, relies on long chains of moves to be optimized away
    // completely. This change should be a 'no-brainer'.
    destroy_deep();
    init_from_ref(a.get_ref());
    a.detach();
}

inline MemRef Array::create_array(Type type, bool context_flag, std::size_t size,
                                  int_fast64_t value, Allocator& alloc)
{
    return create(type, context_flag, wtype_Bits, size, value, alloc); // Throws
}

inline MemRef Array::create_empty_array(Type type, bool context_flag, Allocator& alloc)
{
    std::size_t size = 0;
    int_fast64_t value = 0;
    return create_array(type, context_flag, size, value, alloc); // Throws
}

inline bool Array::has_parent() const TIGHTDB_NOEXCEPT
{
    return m_parent != 0;
}

inline ArrayParent* Array::get_parent() const TIGHTDB_NOEXCEPT
{
    return m_parent;
}

inline void Array::set_parent(ArrayParent* parent, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT
{
    m_parent = parent;
    m_ndx_in_parent = ndx_in_parent;
}

inline std::size_t Array::get_ndx_in_parent() const TIGHTDB_NOEXCEPT
{
    return m_ndx_in_parent;
}

inline void Array::set_ndx_in_parent(std::size_t ndx) TIGHTDB_NOEXCEPT
{
    m_ndx_in_parent = ndx;
}

inline void Array::adjust_ndx_in_parent(int diff) TIGHTDB_NOEXCEPT
{
    // Note that `diff` is promoted to an unsigned type, and that
    // C++03 still guarantees the expected result regardless of the
    // sizes of `int` and `decltype(m_ndx_in_parent)`.
    m_ndx_in_parent += diff;
}

inline ref_type Array::get_ref_from_parent() const TIGHTDB_NOEXCEPT
{
    ref_type ref = m_parent->get_child_ref(m_ndx_in_parent);
    return ref;
}

inline bool Array::is_attached() const TIGHTDB_NOEXCEPT
{
    return m_data != 0;
}

inline void Array::detach() TIGHTDB_NOEXCEPT
{
    m_data = 0;
}

inline std::size_t Array::size() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_size;
}

inline bool Array::is_empty() const TIGHTDB_NOEXCEPT
{
    return size() == 0;
}

inline std::size_t Array::get_max_byte_size(std::size_t num_elems) TIGHTDB_NOEXCEPT
{
    int max_bytes_per_elem = 8;
    return header_size + num_elems * max_bytes_per_elem; // FIXME: Prone to overflow
}

inline void Array::update_parent()
{
    if (m_parent)
        m_parent->update_child_ref(m_ndx_in_parent, m_ref);
}


inline void Array::update_child_ref(size_t child_ndx, ref_type new_ref)
{
    set(child_ndx, new_ref);
}

inline ref_type Array::get_child_ref(size_t child_ndx) const TIGHTDB_NOEXCEPT
{
    return get_as_ref(child_ndx);
}

inline std::size_t Array::get_bptree_size() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_inner_bptree_node());
    int_fast64_t v = back();
    return std::size_t(v / 2); // v = 1 + 2*total_elems_in_tree
}

inline std::size_t Array::get_bptree_size_from_header(const char* root_header) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(get_is_inner_bptree_node_from_header(root_header));
    size_t root_size = get_size_from_header(root_header);
    int_fast64_t v = get(root_header, root_size-1);
    return size_t(v / 2); // v = 1 + 2*total_elems_in_tree
}

inline void Array::ensure_bptree_offsets(Array& offsets)
{
    int_fast64_t first_value = get(0);
    if (first_value % 2 == 0) {
        offsets.init_from_ref(to_ref(first_value));
    }
    else {
        create_bptree_offsets(offsets, first_value); // Throws
    }
    offsets.set_parent(this, 0);
}


template<class TreeTraits>
ref_type Array::bptree_append(TreeInsert<TreeTraits>& state)
{
    // FIXME: Consider exception safety. Especially, how can the split
    // be carried out in an exception safe manner?
    //
    // Can split be done as a separate preparation step, such that if
    // the actual insert fails, the split will still have occured.
    //
    // Unfortunately, it requires a rather significant rearrangement
    // of the insertion flow. Instead of returning the sibling ref
    // from insert functions, the leaf-insert functions must instead
    // call the special bptree_insert() function on the parent, which
    // will then cascade the split towards the root as required.
    //
    // At each level where a split is required (starting at the leaf):
    //
    //  1. Create the new sibling.
    //
    //  2. Copy relevant entries over such that new sibling is in
    //     its final state.
    //
    //  3. Call Array::bptree_insert() on parent with sibling ref.
    //
    //  4. Rearrange entries in original sibling and truncate as
    //     required (must not throw).
    //
    // What about the 'offsets' array? It will always be
    // present. Consider this carefully.

    TIGHTDB_ASSERT(size() >= 1 + 1 + 1); // At least one child

    ArrayParent& childs_parent = *this;
    std::size_t child_ref_ndx = size() - 2;
    ref_type child_ref = get_as_ref(child_ref_ndx), new_sibling_ref;
    char* child_header = static_cast<char*>(m_alloc.translate(child_ref));

    bool child_is_leaf = !get_is_inner_bptree_node_from_header(child_header);
    if (child_is_leaf) {
        std::size_t elem_ndx_in_child = npos; // Append
        new_sibling_ref =
            TreeTraits::leaf_insert(MemRef(child_header, child_ref), childs_parent,
                                    child_ref_ndx, m_alloc, elem_ndx_in_child, state); // Throws
    }
    else {
        Array child(m_alloc);
        child.init_from_mem(MemRef(child_header, child_ref));
        child.set_parent(&childs_parent, child_ref_ndx);
        new_sibling_ref = child.bptree_append(state); // Throws
    }

    if (TIGHTDB_LIKELY(!new_sibling_ref)) {
        // +2 because stored value is 1 + 2*total_elems_in_subtree
        adjust(size()-1, +2); // Throws
        return 0; // Child was not split, so parent was not split either
    }

    Array offsets(m_alloc);
    int_fast64_t first_value = get(0);
    if (first_value % 2 == 0) {
        // Offsets array is present (general form)
        offsets.init_from_ref(to_ref(first_value));
        offsets.set_parent(this, 0);
    }
    size_t child_ndx = child_ref_ndx - 1;
    return insert_bptree_child(offsets, child_ndx, new_sibling_ref, state); // Throws
}


template<class TreeTraits>
ref_type Array::bptree_insert(std::size_t elem_ndx, TreeInsert<TreeTraits>& state)
{
    TIGHTDB_ASSERT(size() >= 1 + 1 + 1); // At least one child

    // Conversion to general form if in compact form. Since this
    // conversion will occur from root to leaf, it will maintain
    // invar:bptree-node-form.
    Array offsets(m_alloc);
    ensure_bptree_offsets(offsets); // Throws

    std::size_t child_ndx, elem_ndx_in_child;
    if (elem_ndx == 0) {
        // Optimization for prepend
        child_ndx = 0;
        elem_ndx_in_child = 0;
    }
    else {
        // There is a choice to be made when the element is to be
        // inserted between two subtrees. It can either be appended to
        // the first subtree, or it can be prepended to the second
        // one. We currently always append to the first subtree. It is
        // essentially a matter of using the lower vs. the upper bound
        // when searching through the offsets array.
        child_ndx = offsets.lower_bound_int(elem_ndx);
        TIGHTDB_ASSERT(child_ndx < size() - 2);
        std::size_t elem_ndx_offset = child_ndx == 0 ? 0 : to_size_t(offsets.get(child_ndx-1));
        elem_ndx_in_child = elem_ndx - elem_ndx_offset;
    }

    ArrayParent& childs_parent = *this;
    std::size_t child_ref_ndx = child_ndx + 1;
    ref_type child_ref = get_as_ref(child_ref_ndx), new_sibling_ref;
    char* child_header = static_cast<char*>(m_alloc.translate(child_ref));
    bool child_is_leaf = !get_is_inner_bptree_node_from_header(child_header);
    if (child_is_leaf) {
        TIGHTDB_ASSERT(elem_ndx_in_child <= TIGHTDB_MAX_BPNODE_SIZE);
        new_sibling_ref =
            TreeTraits::leaf_insert(MemRef(child_header, child_ref), childs_parent,
                                    child_ref_ndx, m_alloc, elem_ndx_in_child, state); // Throws
    }
    else {
        Array child(m_alloc);
        child.init_from_mem(MemRef(child_header, child_ref));
        child.set_parent(&childs_parent, child_ref_ndx);
        new_sibling_ref = child.bptree_insert(elem_ndx_in_child, state); // Throws
    }

    if (TIGHTDB_LIKELY(!new_sibling_ref)) {
        // +2 because stored value is 1 + 2*total_elems_in_subtree
        adjust(size()-1, +2); // Throws
        offsets.adjust(child_ndx, offsets.size(), +1);
        return 0; // Child was not split, so parent was not split either
    }

    return insert_bptree_child(offsets, child_ndx, new_sibling_ref, state); // Throws
}



//*************************************************************************************
// Finding code                                                                       *
//*************************************************************************************

template<std::size_t w> int64_t Array::Get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    return GetUniversal<w>(m_data, ndx);
}

template<std::size_t w> int64_t Array::GetUniversal(const char* data, std::size_t ndx) const
{
    if (w == 0) {
        return 0;
    }
    else if (w == 1) {
        std::size_t offset = ndx >> 3;
        return (data[offset] >> (ndx & 7)) & 0x01;
    }
    else if (w == 2) {
        std::size_t offset = ndx >> 2;
        return (data[offset] >> ((ndx & 3) << 1)) & 0x03;
    }
    else if (w == 4) {
        std::size_t offset = ndx >> 1;
        return (data[offset] >> ((ndx & 1) << 2)) & 0x0F;
    }
    else if (w == 8) {
        return *reinterpret_cast<const signed char*>(data + ndx);
    }
    else if (w == 16) {
        std::size_t offset = ndx * 2;
        return *reinterpret_cast<const int16_t*>(data + offset);
    }
    else if (w == 32) {
        std::size_t offset = ndx * 4;
        return *reinterpret_cast<const int32_t*>(data + offset);
    }
    else if (w == 64) {
        std::size_t offset = ndx * 8;
        return *reinterpret_cast<const int64_t*>(data + offset);
    }
    else {
        TIGHTDB_ASSERT(false);
        return int64_t(-1);
    }
}

/*
find() (calls find_optimized()) will call match() for each search result.

If pattern == true:
    'indexpattern' contains a 64-bit chunk of elements, each of 'width' bits in size where each element indicates a match if its lower bit is set, otherwise
    it indicates a non-match. 'index' tells the database row index of the first element. You must return true if you chose to 'consume' the chunk or false
    if not. If not, then Array-finder will afterwards call match() successive times with pattern == false.

If pattern == false:
    'index' tells the row index of a single match and 'value' tells its value. Return false to make Array-finder break its search or return true to let it continue until
    'end' or 'limit'.

Array-finder decides itself if - and when - it wants to pass you an indexpattern. It depends on array bit width, match frequency, and wether the arithemetic and
computations for the given search criteria makes it feasible to construct such a pattern.
*/

// These wrapper functions only exist to enable a possibility to make the compiler see that 'value' and/or 'index' are unused, such that caller's
// computation of these values will not be made. Only works if find_action() and find_action_pattern() rewritten as macros. Note: This problem has been fixed in
// next upcoming array.hpp version
template<Action action, class Callback>
bool Array::find_action(size_t index, int64_t value, QueryState<int64_t>* state, Callback callback) const
{
    if (action == act_CallbackIdx)
        return callback(index);
    else
        return state->match<action, false>(index, 0, value);
}
template<Action action, class Callback>
bool Array::find_action_pattern(size_t index, uint64_t pattern, QueryState<int64_t>* state, Callback callback) const
{
    static_cast<void>(callback);
    if (action == act_CallbackIdx) {
        // Possible future optimization: call callback(index) like in above find_action(), in a loop for each bit set in 'pattern'
        return false;
    }
    return state->match<action, true>(index, pattern, 0);
}


template<size_t width> uint64_t Array::cascade(uint64_t a) const
{
    // Takes a chunk of values as argument and sets the uppermost bit for each element which is 0. Example:
    // width == 4 and v = 01000000 00001000 10000001 00001000 00000000 10100100 00001100 00111110 01110100 00010000 00000000 00000001 10000000 01111110
    // will return:       00001000 00010000 00010000 00010000 00010001 00000000 00010000 00000000 00000000 00000001 00010001 00010000 00000001 00000000

    // static values needed for fast population count
    const uint64_t m1  = 0x5555555555555555ULL;

    if (width == 1) {
        return ~a;
    }
    else if (width == 2) {
        // Masks to avoid spillover between segments in cascades
        const uint64_t c1 = ~0ULL/0x3 * 0x1;

        a |= (a >> 1) & c1; // cascade ones in non-zeroed segments
        a &= m1;     // isolate single bit in each segment
        a ^= m1;     // reverse isolated bits

        return a;
    }
    else if (width == 4) {
        const uint64_t m  = ~0ULL/0xF * 0x1;

        // Masks to avoid spillover between segments in cascades
        const uint64_t c1 = ~0ULL/0xF * 0x7;
        const uint64_t c2 = ~0ULL/0xF * 0x3;

        a |= (a >> 1) & c1; // cascade ones in non-zeroed segments
        a |= (a >> 2) & c2;
        a &= m;     // isolate single bit in each segment
        a ^= m;     // reverse isolated bits

        return a;
    }
    else if (width == 8) {
        const uint64_t m  = ~0ULL/0xFF * 0x1;

        // Masks to avoid spillover between segments in cascades
        const uint64_t c1 = ~0ULL/0xFF * 0x7F;
        const uint64_t c2 = ~0ULL/0xFF * 0x3F;
        const uint64_t c3 = ~0ULL/0xFF * 0x0F;

        a |= (a >> 1) & c1; // cascade ones in non-zeroed segments
        a |= (a >> 2) & c2;
        a |= (a >> 4) & c3;
        a &= m;     // isolate single bit in each segment
        a ^= m;     // reverse isolated bits

        return a;
    }
    else if (width == 16) {
        const uint64_t m  = ~0ULL/0xFFFF * 0x1;

        // Masks to avoid spillover between segments in cascades
        const uint64_t c1 = ~0ULL/0xFFFF * 0x7FFF;
        const uint64_t c2 = ~0ULL/0xFFFF * 0x3FFF;
        const uint64_t c3 = ~0ULL/0xFFFF * 0x0FFF;
        const uint64_t c4 = ~0ULL/0xFFFF * 0x00FF;

        a |= (a >> 1) & c1; // cascade ones in non-zeroed segments
        a |= (a >> 2) & c2;
        a |= (a >> 4) & c3;
        a |= (a >> 8) & c4;
        a &= m;     // isolate single bit in each segment
        a ^= m;     // reverse isolated bits

        return a;
    }

    else if (width == 32) {
        const uint64_t m  = ~0ULL/0xFFFFFFFF * 0x1;

        // Masks to avoid spillover between segments in cascades
        const uint64_t c1 = ~0ULL/0xFFFFFFFF * 0x7FFFFFFF;
        const uint64_t c2 = ~0ULL/0xFFFFFFFF * 0x3FFFFFFF;
        const uint64_t c3 = ~0ULL/0xFFFFFFFF * 0x0FFFFFFF;
        const uint64_t c4 = ~0ULL/0xFFFFFFFF * 0x00FFFFFF;
        const uint64_t c5 = ~0ULL/0xFFFFFFFF * 0x0000FFFF;

        a |= (a >> 1) & c1; // cascade ones in non-zeroed segments
        a |= (a >> 2) & c2;
        a |= (a >> 4) & c3;
        a |= (a >> 8) & c4;
        a |= (a >> 16) & c5;
        a &= m;     // isolate single bit in each segment
        a ^= m;     // reverse isolated bits

        return a;
    }
    else if (width == 64) {
        return a == 0 ? 1 : 0;
    }
    else {
        TIGHTDB_ASSERT(false);
        return uint64_t(-1);
    }
}

// This is the main finding function for Array. Other finding functions are just wrappers around this one.
// Search for 'value' using condition cond2 (Equal, NotEqual, Less, etc) and call find_action() or find_action_pattern()
// for each match. Break and return if find_action() returns false or 'end' is reached.
template<class cond2, Action action, size_t bitwidth, class Callback> bool Array::find_optimized(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state, Callback callback) const
{
    cond2 c;
    TIGHTDB_ASSERT(start <= m_size && (end <= m_size || end == std::size_t(-1)) && start <= end);

    // Test first few items with no initial time overhead
    if (start > 0) {
        if (m_size > start && c(Get<bitwidth>(start), value) && start < end) {
            if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }

        ++start;

        if (m_size > start && c(Get<bitwidth>(start), value) && start < end) {
            if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }

        ++start;

        if (m_size > start && c(Get<bitwidth>(start), value) && start < end) {
            if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }

        ++start;

        if (m_size > start && c(Get<bitwidth>(start), value) && start < end) {
            if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }

        ++start;
    }

    if (!(m_size > start && start < end))
        return true;

    if (end == std::size_t(-1))
        end = m_size;

    // Return immediately if no items in array can match (such as if cond2 == Greater && value == 100 && m_ubound == 15)
    if (!c.can_match(value, m_lbound, m_ubound))
        return true;

    // optimization if all items are guaranteed to match (such as cond2 == NotEqual && value == 100 && m_ubound == 15)
    if (c.will_match(value, m_lbound, m_ubound)) {
        size_t end2;

        if (action == act_CallbackIdx)
            end2 = end;
        else {
            TIGHTDB_ASSERT(state->m_match_count < state->m_limit);
            size_t process = state->m_limit - state->m_match_count;
            end2 = end - start > process ? start + process : end;
        }
        if (action == act_Sum || action == act_Max || action == act_Min) {
            int64_t res;
            size_t res_ndx = 0;
            if (action == act_Sum)
                res = Array::sum(start, end2);
            if (action == act_Max)
                Array::maximum(res, start, end2, &res_ndx);
            if (action == act_Min)
                Array::minimum(res, start, end2, &res_ndx);

            find_action<action, Callback>(res_ndx + baseindex, res, state, callback);
            state->m_match_count += end2 - start;

        }
        else if (action == act_Count) {
            state->m_state += end2 - start;
        }
        else {
            for (; start < end2; start++)
                if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                    return false;
        }
        return true;
    }

    // finder cannot handle this bitwidth
    TIGHTDB_ASSERT(m_width != 0);

#if defined(TIGHTDB_COMPILER_SSE)
    if ((sseavx<42>() &&                                        (end - start >= sizeof (__m128i) && m_width >= 8))
    ||  (sseavx<30>() && (util::SameType<cond2, Equal>::value && end - start >= sizeof (__m128i) && m_width >= 8 && m_width < 64))) {

        // FindSSE() must start at 16-byte boundary, so search area before that using CompareEquality()
        __m128i* const a = reinterpret_cast<__m128i*>(round_up(m_data + start * bitwidth / 8, sizeof (__m128i)));
        __m128i* const b = reinterpret_cast<__m128i*>(round_down(m_data + end * bitwidth / 8, sizeof (__m128i)));

        if (!Compare<cond2, action, bitwidth, Callback>(value, start, (reinterpret_cast<char*>(a) - m_data) * 8 / no0(bitwidth), baseindex, state, callback))
            return false;

        // Search aligned area with SSE
        if (b > a) {
            if (sseavx<42>()) {
                if (!FindSSE<cond2, action, bitwidth, Callback>(value, a, b - a, state, baseindex + ((reinterpret_cast<char*>(a) - m_data) * 8 / no0(bitwidth)), callback))
                    return false;
                }
                else if (sseavx<30>()) {

                if (!FindSSE<Equal, action, bitwidth, Callback>(value, a, b - a, state, baseindex + ((reinterpret_cast<char*>(a) - m_data) * 8 / no0(bitwidth)), callback))
                    return false;
                }
        }

        // Search remainder with CompareEquality()
        if (!Compare<cond2, action, bitwidth, Callback>(value, (reinterpret_cast<char*>(b) - m_data) * 8 / no0(bitwidth), end, baseindex, state, callback))
            return false;

        return true;
    }
    else {
        return Compare<cond2, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
    }
#else
return Compare<cond2, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
#endif
}

template<size_t width> inline int64_t Array::LowerBits() const
{
    if (width == 1)
        return 0xFFFFFFFFFFFFFFFFULL;
    else if (width == 2)
        return 0x5555555555555555ULL;
    else if (width == 4)
        return 0x1111111111111111ULL;
    else if (width == 8)
        return 0x0101010101010101ULL;
    else if (width == 16)
        return 0x0001000100010001ULL;
    else if (width == 32)
        return 0x0000000100000001ULL;
    else if (width == 64)
        return 0x0000000000000001ULL;
    else {
        TIGHTDB_ASSERT(false);
        return int64_t(-1);
    }
}

// Tests if any chunk in 'value' is 0
template<size_t width> inline bool Array::TestZero(uint64_t value) const
{
    uint64_t hasZeroByte;
    uint64_t lower = LowerBits<width>();
    uint64_t upper = LowerBits<width>() * 1ULL << (width == 0 ? 0 : (width - 1ULL));
    hasZeroByte = (value - lower) & ~value & upper;
    return hasZeroByte != 0;
}

// Finds first zero (if eq == true) or non-zero (if eq == false) element in v and returns its position.
// IMPORTANT: This function assumes that at least 1 item matches (test this with TestZero() or other means first)!
template<bool eq, size_t width>size_t Array::FindZero(uint64_t v) const
{
    size_t start = 0;
    uint64_t hasZeroByte;
    // Warning free way of computing (1ULL << width) - 1
    uint64_t mask = (width == 64 ? ~0ULL : ((1ULL << (width == 64 ? 0 : width)) - 1ULL));

    if (eq == (((v >> (width * start)) & mask) == 0)) {
        return 0;
    }

    // Bisection optimization, speeds up small bitwidths with high match frequency. More partions than 2 do NOT pay
    // off because the work done by TestZero() is wasted for the cases where the value exists in first half, but
    // useful if it exists in last half. Sweet spot turns out to be the widths and partitions below.
    if (width <= 8) {
        hasZeroByte = TestZero<width>(v | 0xffffffff00000000ULL);
        if (eq ? !hasZeroByte : (v & 0x00000000ffffffffULL) == 0) {
            // 00?? -> increasing
            start += 64 / no0(width) / 2;
            if (width <= 4) {
                hasZeroByte = TestZero<width>(v | 0xffff000000000000ULL);
                if (eq ? !hasZeroByte : (v & 0x0000ffffffffffffULL) == 0) {
                    // 000?
                    start += 64 / no0(width) / 4;
                }
            }
        }
        else {
            if (width <= 4) {
                // ??00
                hasZeroByte = TestZero<width>(v | 0xffffffffffff0000ULL);
                if (eq ? !hasZeroByte : (v & 0x000000000000ffffULL) == 0) {
                    // 0?00
                    start += 64 / no0(width) / 4;
                }
            }
        }
    }

    while (eq == (((v >> (width * start)) & mask) != 0)) {
        // You must only call FindZero() if you are sure that at least 1 item matches
        TIGHTDB_ASSERT(start <= 8 * sizeof(v));
        start++;
    }

    return start;
}

// Generate a magic constant used for later bithacks
template<bool gt, size_t width>int64_t Array::FindGTLT_Magic(int64_t v) const
{
    uint64_t mask1 = (width == 64 ? ~0ULL : ((1ULL << (width == 64 ? 0 : width)) - 1ULL)); // Warning free way of computing (1ULL << width) - 1
    uint64_t mask2 = mask1 >> 1;
    uint64_t magic = gt ? (~0ULL / no0(mask1) * (mask2 - v)) : (~0ULL / no0(mask1) * v);
    return magic;
}

template<bool gt, Action action, size_t width, class Callback> bool Array::FindGTLT_Fast(uint64_t chunk, uint64_t magic, QueryState<int64_t>* state, size_t baseindex, Callback callback) const
{
    // Tests if a a chunk of values contains values that are greater (if gt == true) or less (if gt == false) than v.
    // Fast, but limited to work when all values in the chunk are positive.

    uint64_t mask1 = (width == 64 ? ~0ULL : ((1ULL << (width == 64 ? 0 : width)) - 1ULL)); // Warning free way of computing (1ULL << width) - 1
    uint64_t mask2 = mask1 >> 1;
    uint64_t m = gt ? (((chunk + magic) | chunk) & ~0ULL / no0(mask1) * (mask2 + 1)) : ((chunk - magic) & ~chunk&~0ULL/no0(mask1)*(mask2+1));
    size_t p = 0;
    while (m) {
        if (find_action_pattern<action, Callback>(baseindex, m >> (no0(width) - 1), state, callback))
            break; // consumed, so do not call find_action()

        size_t t = FirstSetBit64(m) / no0(width);
        p += t;
        if (!find_action<action, Callback>(p + baseindex, (chunk >> (p * width)) & mask1, state, callback))
            return false;

        if ((t + 1) * width == 64)
            m = 0;
        else
            m >>= (t + 1) * width;
        p++;
    }

    return true;
}


template<bool gt, Action action, size_t width, class Callback> bool Array::FindGTLT(int64_t v, uint64_t chunk, QueryState<int64_t>* state, size_t baseindex, Callback callback) const
{
    // Find items in 'chunk' that are greater (if gt == true) or smaller (if gt == false) than 'v'. Fixme, __forceinline can make it crash in vS2010 - find out why
    if (width == 1) {
        for (size_t t = 0; t < 64; t++) {
            if (gt ? static_cast<int64_t>(chunk & 0x1) > v : static_cast<int64_t>(chunk & 0x1) < v) {if (!find_action<action, Callback>( t + baseindex, static_cast<int64_t>(chunk & 0x1), state, callback)) return false;} chunk >>= 1;
        }
    }
    else if (width == 2) {
        // Alot (50% +) faster than loop/compiler-unrolled loop
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 1 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 2 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 3 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 4 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 5 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 6 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 7 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;

        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 8 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 9 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 10 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 11 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 12 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 13 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 14 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 15 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;

        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 16 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 17 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 18 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 19 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 20 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 21 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 22 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 23 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;

        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 24 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 25 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 26 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 27 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 28 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 29 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 30 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
        if (gt ? static_cast<int64_t>(chunk & 0x3) > v : static_cast<int64_t>(chunk & 0x3) < v) {if (!find_action<action, Callback>( 31 + baseindex, static_cast<int64_t>(chunk & 0x3), state, callback)) return false;} chunk >>= 2;
    }
    else if (width == 4) {
        // 128 ms:
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 1 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 2 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 3 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 4 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 5 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 6 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 7 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;

        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 8 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 9 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 10 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 11 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 12 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 13 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 14 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;
        if (gt ? static_cast<int64_t>(chunk & 0xf) > v : static_cast<int64_t>(chunk & 0xf) < v) {if (!find_action<action, Callback>( 15 + baseindex, static_cast<int64_t>(chunk & 0xf), state, callback)) return false;} chunk >>= 4;

        // 187 ms:
        // if (gt ? static_cast<int64_t>(chunk >> 0*4) & 0xf > v : static_cast<int64_t>(chunk >> 0*4) & 0xf < v) return 0;
    }
    else if (width == 8) {
        // 88 ms:
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 1 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 2 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 3 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 4 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 5 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 6 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;
        if (gt ? static_cast<char>(chunk) > v : static_cast<char>(chunk) < v) {if (!find_action<action, Callback>( 7 + baseindex, static_cast<char>(chunk), state, callback)) return false;} chunk >>= 8;

        //97 ms ms:
        // if (gt ? static_cast<char>(chunk >> 0*8) > v : static_cast<char>(chunk >> 0*8) < v) return 0;
    }
    else if (width == 16) {

        if (gt ? static_cast<short int>(chunk >> 0*16) > v : static_cast<short int>(chunk >> 0*16) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<short int>(chunk >> 0*16), state, callback)) return false;};
        if (gt ? static_cast<short int>(chunk >> 1*16) > v : static_cast<short int>(chunk >> 1*16) < v) {if (!find_action<action, Callback>( 1 + baseindex, static_cast<short int>(chunk >> 1*16), state, callback)) return false;};
        if (gt ? static_cast<short int>(chunk >> 2*16) > v : static_cast<short int>(chunk >> 2*16) < v) {if (!find_action<action, Callback>( 2 + baseindex, static_cast<short int>(chunk >> 2*16), state, callback)) return false;};
        if (gt ? static_cast<short int>(chunk >> 3*16) > v : static_cast<short int>(chunk >> 3*16) < v) {if (!find_action<action, Callback>( 3 + baseindex, static_cast<short int>(chunk >> 3*16), state, callback)) return false;};

        /*
        // Faster but disabled due to bug in VC2010 compiler (fixed in 2012 toolchain) where last 'if' is errorneously optimized away
        if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {if (!state->AddPositiveLocal(0 + baseindex); else return 0;} chunk >>= 16;
        if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {if (!state->AddPositiveLocal(1 + baseindex); else return 1;} chunk >>= 16;
        if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {if (!state->AddPositiveLocal(2 + baseindex); else return 2;} chunk >>= 16;
        if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {if (!state->AddPositiveLocal(3 + baseindex); else return 3;} chunk >>= 16;

        // Following illustrates it:
        #include <stdint.h>
        #include <stdio.h>
        #include <stdlib.h>

        size_t bug(int64_t v, uint64_t chunk)
        {
            bool gt = true;

            if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {return 0;} chunk >>= 16;
            if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {return 1;} chunk >>= 16;
            if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {return 2;} chunk >>= 16;
            if (gt ? static_cast<short int>chunk > v : static_cast<short int>chunk < v) {return 3;} chunk >>= 16;

            return -1;
        }

        int main(int argc, char const *const argv[])
        {
            int64_t v;
            FIXME: We cannot use rand() as it is not thread-safe.
            if (rand()*rand() == 3) {
                v = rand()*rand()*rand()*rand()*rand();
                printf("Change '3' to something else and run test again\n");
            }
            else {
                v = 0x2222000000000000ULL;
            }

            size_t idx;

            idx = bug(200, v);
            if (idx != 3)
                printf("Compiler failed: idx == %d (expected idx == 3)\n", idx);

            v = 0x2222000000000000ULL;
            idx = bug(200, v);
            if (idx == 3)
                printf("Touching v made it work\n", idx);
        }
        */
    }
    else if (width == 32) {
        if (gt ? static_cast<int>(chunk) > v : static_cast<int>(chunk) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<int>(chunk), state, callback)) return false;} chunk >>= 32;
        if (gt ? static_cast<int>(chunk) > v : static_cast<int>(chunk) < v) {if (!find_action<action, Callback>( 1 + baseindex, static_cast<int>(chunk), state, callback)) return false;} chunk >>= 32;
    }
    else if (width == 64) {
        if (gt ? static_cast<int64_t>(v) > v : static_cast<int64_t>(v) < v) {if (!find_action<action, Callback>( 0 + baseindex, static_cast<int64_t>(v), state, callback)) return false;};
    }

    return true;
}


template<bool eq, Action action, size_t width, class Callback> inline bool Array::CompareEquality(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state, Callback callback) const
{
    // Find items in this Array that are equal (eq == true) or different (eq = false) from 'value'

    TIGHTDB_ASSERT(start <= m_size && (end <= m_size || end == std::size_t(-1)) && start <= end);

    size_t ee = round_up(start, 64 / no0(width));
    ee = ee > end ? end : ee;
    for (; start < ee; ++start)
        if (eq ? (Get<width>(start) == value) : (Get<width>(start) != value)) {
            if (!find_action<action, Callback>(start + baseindex, Get<width>(start), state, callback))
                return false;
        }

    if (start >= end)
        return true;

    if (width != 32 && width != 64) {
        const int64_t* p = reinterpret_cast<const int64_t*>(m_data + (start * width / 8));
        const int64_t* const e = reinterpret_cast<int64_t*>(m_data + (end * width / 8)) - 1;
        const uint64_t mask = (width == 64 ? ~0ULL : ((1ULL << (width == 64 ? 0 : width)) - 1ULL)); // Warning free way of computing (1ULL << width) - 1
        const uint64_t valuemask = ~0ULL / no0(mask) * (value & mask); // the "== ? :" is to avoid division by 0 compiler error

        while (p < e) {
            uint64_t chunk = *p;
            uint64_t v2 = chunk ^ valuemask;
            start = (p - reinterpret_cast<int64_t*>(m_data)) * 8 * 8 / no0(width);
            size_t a = 0;

            while (eq ? TestZero<width>(v2) : v2) {

                if (find_action_pattern<action, Callback>(start + baseindex, cascade<width>(eq ? v2 : ~v2), state, callback))
                    break; // consumed

                size_t t = FindZero<eq, width>(v2);
                a += t;

                if (a >= 64 / no0(width))
                    break;

                if (!find_action<action, Callback>(a + start + baseindex, Get<width>(start + t), state, callback))
                    return false;
                v2 >>= (t + 1) * width;
                a += 1;
            }

            ++p;
        }

        // Loop ended because we are near end or end of array. No need to optimize search in remainder in this case because end of array means that
        // lots of search work has taken place prior to ending here. So time spent searching remainder is relatively tiny
        start = (p - reinterpret_cast<int64_t*>(m_data)) * 8 * 8 / no0(width);
    }

    while (start < end) {
        if (eq ? Get<width>(start) == value : Get<width>(start) != value) {
            if (!find_action<action, Callback>( start + baseindex, Get<width>(start), state, callback))
                return false;
        }
        ++start;
    }

        return true;
}

// There exists a couple of find() functions that take more or less template arguments. Always call the one that
// takes as most as possible to get best performance.

// This is the one installed into the m_finder slots.
template<class cond, Action action, size_t bitwidth>
bool Array::find(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state) const
{
    return find<cond, action, bitwidth>(value, start, end, baseindex, state, CallbackDummy());
}

template<class cond, Action action, class Callback>
bool Array::find(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                 Callback callback) const
{
    TIGHTDB_TEMPEX4(return find, cond, action, m_width, Callback, (value, start, end, baseindex, state, callback));
}

template<class cond, Action action, size_t bitwidth, class Callback>
bool Array::find(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                 Callback callback) const
{
    return find_optimized<cond, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
}

#ifdef TIGHTDB_COMPILER_SSE
// 'items' is the number of 16-byte SSE chunks. Returns index of packed element relative to first integer of first chunk
template<class cond2, Action action, size_t width, class Callback>
bool Array::FindSSE(int64_t value, __m128i *data, size_t items, QueryState<int64_t>* state, size_t baseindex,
                    Callback callback) const
{
    __m128i search = {0};

    // FIXME: Lasse, should these casts not be to int8_t, int16_t, int32_t respecitvely?
    if (width == 8)
        search = _mm_set1_epi8(static_cast<char>(value)); // FIXME: Lasse, Should this not be a cast to 'signed char'?
    else if (width == 16)
        search = _mm_set1_epi16(static_cast<short int>(value));
    else if (width == 32)
        search = _mm_set1_epi32(static_cast<int>(value));
    else if (width == 64) {
        search = _mm_set_epi64x(value, value);
    }

    return FindSSE_intern<cond2, action, width, Callback>(data, &search, items, state, baseindex, callback);
}

// Compares packed action_data with packed data (equal, less, etc) and performs aggregate action (max, min, sum,
// find_all, etc) on value inside action_data for first match, if any
template<class cond2, Action action, size_t width, class Callback>
TIGHTDB_FORCEINLINE bool Array::FindSSE_intern(__m128i* action_data, __m128i* data, size_t items,
                                               QueryState<int64_t>* state, size_t baseindex, Callback callback) const
{
    int cond = cond2::condition;
    size_t i = 0;
    __m128i compare = {0};
    unsigned int resmask;

    // Search loop. Unrolling it has been tested to NOT increase performance (apparently mem bound)
    for (i = 0; i < items; ++i) {
        // equal / not-equal
        if (cond == cond_Equal || cond == cond_NotEqual) {
            if (width == 8)
                compare = _mm_cmpeq_epi8(action_data[i], *data);
            if (width == 16)
                compare = _mm_cmpeq_epi16(action_data[i], *data);
            if (width == 32)
                compare = _mm_cmpeq_epi32(action_data[i], *data);
            if (width == 64) {
                compare = _mm_cmpeq_epi64(action_data[i], *data); // SSE 4.2 only
            }
        }

        // greater
        else if (cond == cond_Greater) {
            if (width == 8)
                compare = _mm_cmpgt_epi8(action_data[i], *data);
            if (width == 16)
                compare = _mm_cmpgt_epi16(action_data[i], *data);
            if (width == 32)
                compare = _mm_cmpgt_epi32(action_data[i], *data);
            if (width == 64)
                compare = _mm_cmpgt_epi64(action_data[i], *data);
        }
        // less
        else if (cond == cond_Less) {
            if (width == 8)
                compare = _mm_cmplt_epi8(action_data[i], *data);
            if (width == 16)
                compare = _mm_cmplt_epi16(action_data[i], *data);
            if (width == 32)
                compare = _mm_cmplt_epi32(action_data[i], *data);
            if (width == 64){
                // There exists no _mm_cmplt_epi64 instruction, so emulate it. _mm_set1_epi8(0xff) is pre-calculated by compiler.
                compare = _mm_cmpeq_epi64(action_data[i], *data);
                compare = _mm_andnot_si128(compare, _mm_set1_epi32(0xffffffff));
            }
        }

        resmask = _mm_movemask_epi8(compare);

        if (cond == cond_NotEqual)
            resmask = ~resmask & 0x0000ffff;

//        if (resmask != 0)
//            printf("resmask=%d\n", resmask);

        size_t s = i * sizeof (__m128i) * 8 / no0(width);

        while (resmask != 0) {

            uint64_t upper = LowerBits<width / 8>() << (no0(width / 8) - 1);
            uint64_t pattern = resmask & upper; // fixme, bits at wrong offsets. Only OK because we only use them in 'count' aggregate
            if (find_action_pattern<action, Callback>(s + baseindex, pattern, state, callback))
                break;

            size_t idx = FirstSetBit(resmask) * 8 / no0(width);
            s += idx;
            if (!find_action<action, Callback>( s + baseindex, GetUniversal<width>(reinterpret_cast<char*>(action_data), s), state, callback))
                return false;
            resmask >>= (idx + 1) * no0(width) / 8;
            ++s;
        }
    }

    return true;
}
#endif //TIGHTDB_COMPILER_SSE

template<class cond, Action action, class Callback>
bool Array::CompareLeafs(const Array* foreign, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                         Callback callback) const
{
    cond c;
    TIGHTDB_ASSERT(start <= end);
    if (start == end)
        return true;


    int64_t v;

    // We can compare first element without checking for out-of-range
    v = get(start);
    if (c(v, foreign->get(start))) {
        if (!find_action<action, Callback>(start + baseindex, v, state, callback))
            return false;
    }

    start++;

    if (start + 3 < end) {
        v = get(start);
        if (c(v, foreign->get(start)))
            if (!find_action<action, Callback>(start + baseindex, v, state, callback))
                return false;

        v = get(start + 1);
        if (c(v, foreign->get(start + 1)))
            if (!find_action<action, Callback>(start + 1 + baseindex, v, state, callback))
                return false;

        v = get(start + 2);
        if (c(v, foreign->get(start + 2)))
            if (!find_action<action, Callback>(start + 2 + baseindex, v, state, callback))
                return false;

        start += 3;
    }
    else if (start == end) {
        return true;
    }

    bool r;
    TIGHTDB_TEMPEX4(r = CompareLeafs, cond, action, m_width, Callback, (foreign, start, end, baseindex, state, callback))
    return r;
}


template<class cond, Action action, size_t width, class Callback> bool Array::CompareLeafs(const Array* foreign, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state, Callback callback) const
{
    size_t fw = foreign->m_width;
    bool r;
    TIGHTDB_TEMPEX5(r = CompareLeafs4, cond, action, width, Callback, fw, (foreign, start, end, baseindex, state, callback))
    return r;
}


template<class cond, Action action, size_t width, class Callback, size_t foreign_width>
bool Array::CompareLeafs4(const Array* foreign, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                          Callback callback) const
{
    cond c;
    char* foreign_m_data = foreign->m_data;

    if (width == 0 && foreign_width == 0) {
        if (c(0, 0)) {
            while (start < end) {
                if (!find_action<action, Callback>(start + baseindex, 0, state, callback))
                    return false;
                start++;
            }
        }
        else {
            return true;
        }
    }


#if defined(TIGHTDB_COMPILER_SSE)
    if (sseavx<42>() && width == foreign_width && (width == 8 || width == 16 || width == 32)) {
        // We can only use SSE if both bitwidths are equal and above 8 bits and all values are signed
        while (start < end && (((reinterpret_cast<size_t>(m_data) & 0xf) * 8 + start * width) % (128) != 0)) {
            int64_t v = GetUniversal<width>(m_data, start);
            int64_t fv = GetUniversal<foreign_width>(foreign_m_data, start);
            if (c(v, fv)) {
                if (!find_action<action, Callback>(start + baseindex, v, state, callback))
                    return false;
            }
            start++;
        }
        if (start == end)
            return true;


        size_t sse_items = (end - start) * width / 128;
        size_t sse_end = start + sse_items * 128 / no0(width);

        while (start < sse_end) {
            __m128i* a = reinterpret_cast<__m128i*>(m_data + start * width / 8);
            __m128i* b = reinterpret_cast<__m128i*>(foreign_m_data + start * width / 8);

            bool continue_search = FindSSE_intern<cond, action, width, Callback>(a, b, 1, state, baseindex + start, callback);

            if (!continue_search)
                return false;

            start += 128 / no0(width);
        }
    }
#endif


#if 0 // this method turned out to be 33% slower than a naive loop. Find out why

    // index from which both arrays are 64-bit aligned
    size_t a = round_up(start, 8 * sizeof (int64_t) / (width < foreign_width ? width : foreign_width));

    while (start < end && start < a) {
        int64_t v = GetUniversal<width>(m_data, start);
        int64_t fv = GetUniversal<foreign_width>(foreign_m_data, start);

        if (v == fv)
            r++;

        start++;
    }

    if (start >= end)
        return r;

    uint64_t chunk;
    uint64_t fchunk;

    size_t unroll_outer = (foreign_width > width ? foreign_width : width) / (foreign_width < width ? foreign_width : width);
    size_t unroll_inner = 64 / (foreign_width > width ? foreign_width : width);

    while (start + unroll_outer * unroll_inner < end) {

        // fetch new most narrow chunk
        if (foreign_width <= width)
            fchunk = *reinterpret_cast<int64_t*>(foreign_m_data + start * foreign_width / 8);
        else
            chunk = *reinterpret_cast<int64_t*>(m_data + start * width / 8);

        for (size_t uo = 0; uo < unroll_outer; uo++) {

            // fetch new widest chunk
            if (foreign_width > width)
                fchunk = *reinterpret_cast<int64_t*>(foreign_m_data + start * foreign_width / 8);
            else
                chunk = *reinterpret_cast<int64_t*>(m_data + start * width / 8);

            size_t newstart = start + unroll_inner;
            while (start < newstart) {

                // Isolate first value from chunk
                int64_t v = (chunk << (64 - width)) >> (64 - width);
                int64_t fv = (fchunk << (64 - foreign_width)) >> (64 - foreign_width);
                chunk >>= width;
                fchunk >>= foreign_width;

                // Sign extend if required
                v = (width <= 4) ? v : (width == 8) ? int8_t(v) : (width == 16) ? int16_t(v) : (width == 32) ? int32_t(v) : int64_t(v);
                fv = (foreign_width <= 4) ? fv : (foreign_width == 8) ? int8_t(fv) : (foreign_width == 16) ? int16_t(fv) : (foreign_width == 32) ? int32_t(fv) : int64_t(fv);

                if (v == fv)
                    r++;

                start++;

            }


        }
    }
#endif



/*
    // Unrolling helped less than 2% (non-frequent matches). Todo, investigate further
    while (start + 1 < end) {
        int64_t v = GetUniversal<width>(m_data, start);
        int64_t v2 = GetUniversal<width>(m_data, start + 1);

        int64_t fv = GetUniversal<foreign_width>(foreign_m_data, start);
        int64_t fv2 = GetUniversal<foreign_width>(foreign_m_data, start + 1);

        if (c(v, fv)) {
            if (!find_action<action, Callback>(start + baseindex, v, state, callback))
                return false;
        }

        if (c(v2, fv2)) {
            if (!find_action<action, Callback>(start + 1 + baseindex, v2, state, callback))
                return false;
        }

        start += 2;
    }
 */

    while (start < end) {
        int64_t v = GetUniversal<width>(m_data, start);
        int64_t fv = GetUniversal<foreign_width>(foreign_m_data, start);

        if (c(v, fv)) {
            if (!find_action<action, Callback>(start + baseindex, v, state, callback))
                return false;
        }

        start++;
    }

    return true;
}


template<class cond2, Action action, size_t bitwidth, class Callback>
bool Array::Compare(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                    Callback callback) const
{
    int cond = cond2::condition;
    bool ret = false;

    if (cond == cond_Equal)
        ret = CompareEquality<true, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
    else if (cond == cond_NotEqual)
        ret = CompareEquality<false, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
    else if (cond == cond_Greater)
        ret = CompareRelation<true, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
    else if (cond == cond_Less)
        ret = CompareRelation<false, action, bitwidth, Callback>(value, start, end, baseindex, state, callback);
    else
        TIGHTDB_ASSERT(false);

    return ret;
}

template<bool gt, Action action, size_t bitwidth, class Callback>
bool Array::CompareRelation(int64_t value, size_t start, size_t end, size_t baseindex, QueryState<int64_t>* state,
                            Callback callback) const
{
    TIGHTDB_ASSERT(start <= m_size && (end <= m_size || end == std::size_t(-1)) && start <= end);
    uint64_t mask = (bitwidth == 64 ? ~0ULL : ((1ULL << (bitwidth == 64 ? 0 : bitwidth)) - 1ULL)); // Warning free way of computing (1ULL << width) - 1

    size_t ee = round_up(start, 64 / no0(bitwidth));
    ee = ee > end ? end : ee;
    for (; start < ee; start++) {
        if (gt ? (Get<bitwidth>(start) > value) : (Get<bitwidth>(start) < value)) {
            if (!find_action<action, Callback>(start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }
    }

    if (start >= end)
        return true; // none found, continue (return true) regardless what find_action() would have returned on match

    const int64_t* p = reinterpret_cast<const int64_t*>(m_data + (start * bitwidth / 8));
    const int64_t* const e = reinterpret_cast<int64_t*>(m_data + (end * bitwidth / 8)) - 1;

    // Matches are rare enough to setup fast linear search for remaining items. We use
    // bit hacks from http://graphics.stanford.edu/~seander/bithacks.html#HasLessInWord

    if (bitwidth == 1 || bitwidth == 2 || bitwidth == 4 || bitwidth == 8 || bitwidth == 16) {
        uint64_t magic = FindGTLT_Magic<gt, bitwidth>(value);

        // Bit hacks only work if searched item <= 127 for 'greater than' and item <= 128 for 'less than'
        if (value != int64_t((magic & mask)) && value >= 0 && bitwidth >= 2 && value <= static_cast<int64_t>((mask >> 1) - (gt ? 1 : 0))) {
            // 15 ms
            while (p < e) {
                uint64_t upper = LowerBits<bitwidth>() << (no0(bitwidth) - 1);

                const int64_t v = *p;
                size_t idx;

                // Bit hacks only works for positive items in chunk, so test their sign bits
                upper = upper & v;

                if ((bitwidth > 4 ? !upper : true)) {
                    // Assert that all values in chunk are positive.
                    TIGHTDB_ASSERT(bitwidth <= 4 || ((LowerBits<bitwidth>() << (no0(bitwidth) - 1)) & value) == 0);
                    idx = FindGTLT_Fast<gt, action, bitwidth, Callback>(v, magic, state, (p - reinterpret_cast<int64_t*>(m_data)) * 8 * 8 / no0(bitwidth) + baseindex, callback);
                }
                else
                    idx = FindGTLT<gt, action, bitwidth, Callback>(value, v, state, (p - reinterpret_cast<int64_t*>(m_data)) * 8 * 8 / no0(bitwidth) + baseindex, callback);

                if (!idx)
                    return false;
                ++p;
            }
        }
        else {
            // 24 ms
            while (p < e) {
                int64_t v = *p;
                if (!FindGTLT<gt, action, bitwidth, Callback>(value, v, state, (p - reinterpret_cast<int64_t*>(m_data)) * 8 * 8 / no0(bitwidth) + baseindex, callback))
                    return false;
                ++p;
            }
        }
        start = (p - reinterpret_cast<int64_t *>(m_data)) * 8 * 8 / no0(bitwidth);
    }

    // matchcount logic in SIMD no longer pays off for 32/64 bit ints because we have just 4/2 elements

    // Test unaligned end and/or values of width > 16 manually
    while (start < end) {
        if (gt ? Get<bitwidth>(start) > value : Get<bitwidth>(start) < value) {
            if (!find_action<action, Callback>( start + baseindex, Get<bitwidth>(start), state, callback))
                return false;
        }
        ++start;
    }
    return true;

}

template<class cond> size_t Array::find_first(int64_t value, size_t start, size_t end) const
{
    TIGHTDB_ASSERT(start <= m_size && (end <= m_size || end == std::size_t(-1)) && start <= end);
    QueryState<int64_t> state;
    state.init(act_ReturnFirst, null_ptr, 1); // todo, would be nice to avoid this in order to speed up find_first loops
    Finder finder = m_finder[cond::condition];
    (this->*finder)(value, start, end, 0, &state);

    return static_cast<size_t>(state.m_state);
}

//*************************************************************************************
// Finding code ends                                                                  *
//*************************************************************************************


} // namespace tightdb

#endif // TIGHTDB_ARRAY_HPP
