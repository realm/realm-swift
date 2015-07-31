#!/usr/bin/python
##############################################################################
#
# Copyright 2014 Realm Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
##############################################################################

# In the lldb shell, load with:
# command script import [Realm path]/plugin/rlm_lldb.py --allow-reload
# To load automatically, add that line to your ~/.lldbinit file (which you will
# have to create if you have not set up any previous lldb scripts), or run this
# file as a Python script outside of Xcode to install it automatically

if __name__ == '__main__':
    # Script is being run directly, so install it
    import errno
    import shutil
    import os

    source = os.path.realpath(__file__)
    destination = os.path.expanduser("~/Library/Application Support/Realm")

    # Copy the file into place
    try:
        os.makedirs(destination, 0744)
    except os.error as e:
        # It's fine if the directory already exists
        if e.errno != errno.EEXIST:
            raise

    shutil.copy2(source, destination + '/rlm_lldb.py')

    # Add it to ~/.lldbinit
    load_line = 'command script import "~/Library/Application Support/Realm/rlm_lldb.py" --allow-reload\n'
    is_installed = False
    try:
        with open(os.path.expanduser('~/.lldbinit')) as f:
            for line in f:
                if line == load_line:
                    is_installed = True
                    break
    except IOError as e:
        if e.errno != errno.ENOENT:
            raise
        # File not existing yet is fine

    if not is_installed:
        with open(os.path.expanduser('~/.lldbinit'), 'a') as f:
            f.write('\n' + load_line)

    exit(0)

import lldb

property_types = {
    0: 'int64_t',
    10: 'double',
    1: 'bool',
    9: 'float',
}

def cache_lookup(cache, key, generator):
    value = cache.get(key, None)
    if not value:
        value = generator(key)
        cache[key] = value
    return value

ivar_cache = {}
def get_ivar_info(obj, ivar):
    def get_offset(ivar):
        class_name, ivar_name = ivar.split('.')
        frame = obj.GetThread().GetSelectedFrame()
        ptr = frame.EvaluateExpression("&(({} *)0)->{}".format(class_name, ivar_name))
        return (ptr.GetValueAsUnsigned(), ptr.deref.type, ptr.deref.size)

    return cache_lookup(ivar_cache, ivar, get_offset)

def get_ivar(obj, addr, ivar):
    offset, _, size = get_ivar_info(obj, ivar)
    if isinstance(addr, lldb.SBAddress):
        addr = int(str(addr), 16)
    return obj.GetProcess().ReadUnsignedFromMemory(addr + offset, size, lldb.SBError())

object_table_ptr_offset = None
def is_object_deleted(obj):
    addr = int(str(obj.GetAddress()), 16)
    global object_table_ptr_offset
    if not object_table_ptr_offset:
        row, _, _ = get_ivar_info(obj, 'RLMObject._row')
        table, _, _ = get_ivar_info(obj, 'realm::Row.m_table')
        ptr, _, _ = get_ivar_info(obj, 'realm::TableRef.m_ptr')
        object_table_ptr_offset = row + table + ptr

    ptr = obj.GetProcess().ReadUnsignedFromMemory(addr + object_table_ptr_offset,
            obj.target.addr_size, lldb.SBError())
    return ptr == 0

class SyntheticChildrenProvider(object):
    def _eval(self, expr):
        frame = self.obj.GetThread().GetSelectedFrame()
        return frame.EvaluateExpression(expr)

    def _get_ivar(self, addr, ivar):
        return get_ivar(self.obj, addr, ivar)

    def _to_str(self, val):
        return self.obj.GetProcess().ReadCStringFromMemory(val, 1024, lldb.SBError())

    def _value_from_ivar(self, ivar):
        offset, ivar_type, _ = get_ivar_info(self.obj, 'RLMObject._' + ivar)
        return self.obj.CreateChildAtOffset(ivar, offset, ivar_type)

def RLMObject_SummaryProvider(obj, _):
    if is_object_deleted(obj):
        return '[Deleted object]'
    return None

schema_cache = {}
class RLMObject_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, obj, _):
        self.obj = obj

        if not obj.GetAddress() or is_object_deleted(obj):
            self.props = []
            return

        object_schema = self._get_ivar(self.obj.GetAddress(), 'RLMObject._objectSchema')

        self.bool_type = obj.GetTarget().FindFirstType('BOOL')
        self.realm_type = obj.GetTarget().FindFirstType('RLMRealm')
        self.object_schema_type = obj.GetTarget().FindFirstType('RLMObjectSchema')

        def get_schema(object_schema):
            properties = self._get_ivar(object_schema, 'RLMObjectSchema._properties')
            if not properties:
                return None
            count = self._eval("(NSUInteger)[((NSArray *){}) count]".format(properties)).GetValueAsUnsigned()
            return [self._get_prop(properties, i) for i in range(count)]

        self.props = cache_lookup(schema_cache, object_schema, get_schema)

    def num_children(self):
        return len(self.props) + 2

    def has_children(self):
        return not is_object_deleted(self.obj)

    def get_child_index(self, name):
        if name == 'realm':
            return 0
        if name == 'objectSchema':
            return 1
        return next(i for i, (prop_name, _) in enumerate(self.props) if prop_name == name)

    def get_child_at_index(self, index):
        if index == 0:
            return self._value_from_ivar('realm')
        if index == 1:
            return self._value_from_ivar('objectSchema')

        name, getter = self.props[index - 2]
        value = self._eval(getter)
        return self.obj.CreateValueFromData(name, value.GetData(), value.GetType())

    def update(self):
        pass

    def _get_prop(self, props, i):
        prop = self._eval("(NSUInteger)[((NSArray *){}) objectAtIndex:{}]".format(props, i)).GetValueAsUnsigned()
        name = self._to_str(self._eval('[(NSString *){} UTF8String]'.format(self._get_ivar(prop, "RLMProperty._name"))).GetValueAsUnsigned())
        type = self._get_ivar(prop, 'RLMProperty._type')
        getter = "({})[(id){} {}]".format(property_types.get(type, 'id'), self.obj.GetAddress(), name)
        return name, getter

class_name_cache = {}
def get_object_class_name(frame, obj, addr, ivar):
    class_name_ptr = get_ivar(obj, addr, ivar)
    def get_class_name(ptr):
        utf8_addr = frame.EvaluateExpression('(const char *)[(NSString *){} UTF8String]'.format(class_name_ptr)).GetValueAsUnsigned()
        return obj.GetProcess().ReadCStringFromMemory(utf8_addr, 1024, lldb.SBError())

    return cache_lookup(class_name_cache, class_name_ptr, get_class_name)

def RLMArray_SummaryProvider(obj, _):
    frame = obj.GetThread().GetSelectedFrame()
    class_name = get_object_class_name(frame, obj, obj.GetAddress(), 'RLMArray._objectClassName')
    count = frame.EvaluateExpression('(NSUInteger)[(RLMArray *){} count]'.format(obj.GetAddress())).GetValueAsUnsigned()
    return "({}[{}])".format(class_name, count)

def RLMResults_SummaryProvider(obj, _):
    frame = obj.GetThread().GetSelectedFrame()
    addr = int(str(obj.GetAddress()), 16)
    class_name = get_object_class_name(frame, obj, addr, 'RLMResults._objectClassName')

    view_created = get_ivar(obj, addr, 'RLMResults._viewCreated')
    if not view_created:
        return 'Unevaluated query on ' + class_name

    count = frame.EvaluateExpression('(NSUInteger)[(RLMResults *){} count]'.format(obj.GetAddress())).GetValueAsUnsigned()
    return "({}[{}])".format(class_name, count)

class RLMArray_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, valobj, _):
        self.obj = valobj
        self.addr = self.obj.GetAddress()

    def num_children(self):
        if not self.count:
            self.count = self._eval("(NSUInteger)[(RLMArray *){} count]".format(self.addr)).GetValueAsUnsigned()
        return self.count + 1

    def has_children(self):
        return True

    def get_child_index(self, name):
        if name == 'realm':
            return 0
        if not name.startswith('['):
            return None
        return int(name.lstrip('[').rstrip(']')) + 1

    def get_child_at_index(self, index):
        if index == 0:
            return self._value_from_ivar('realm')
        value = self._eval('(id)[(id){} objectAtIndex:{}]'.format(self.addr, index - 1))
        return self.obj.CreateValueFromData('[' + str(index - 1) + ']', value.GetData(), value.GetType())

    def update(self):
        self.count = None

def __lldb_init_module(debugger, _):
    debugger.HandleCommand('type summary add RLMArray -F rlm_lldb.RLMArray_SummaryProvider')
    debugger.HandleCommand('type summary add RLMArrayLinkView -F rlm_lldb.RLMArray_SummaryProvider')
    debugger.HandleCommand('type summary add RLMResults -F rlm_lldb.RLMResults_SummaryProvider')
    debugger.HandleCommand('type summary add -x RLMAccessor_ -F rlm_lldb.RLMObject_SummaryProvider')

    debugger.HandleCommand('type synthetic add RLMArray --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMArrayLinkView --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMResults --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add -x RLMAccessor_.* --python-class rlm_lldb.RLMObject_SyntheticChildrenProvider')
