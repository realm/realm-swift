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
            f.write(load_line)

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
        table, _, _ = get_ivar_info(obj, 'tightdb::Row.m_table')
        ptr, _, _ = get_ivar_info(obj, 'tightdb::TableRef.m_ptr')
        object_table_ptr_offset = row + table + ptr

    ptr = obj.GetProcess().ReadUnsignedFromMemory(addr + object_table_ptr_offset,
            obj.target.addr_size, lldb.SBError())
    return ptr == 0

def unsigned(value):
    data = value.data
    if data.GetByteSize() == 4:
        return value.data.GetUnsignedInt32(lldb.SBError(), 0)
    return value.data.GetUnsignedInt64(lldb.SBError(), 0)

ivar_offset_cache = {}
def get_ivars(obj, *args):
    def get_offset(type_name):
        ivars = {}
        for ivar in args:
            ivars[ivar] = unsigned(obj.thread.GetSelectedFrame().EvaluateExpression(
                'RLMDebugGetIvarOffset({}, "_{}")'.format(obj.GetAddress(), ivar)))
        return ivars

    return cache_lookup(ivar_offset_cache, obj.type.name, get_offset)

type_cache = {}
def get_type(obj, name):
    return cache_lookup(type_cache, name, lambda name: obj.target.FindFirstType(name))

class SyntheticChildrenProvider(object):
    def __init__(self, obj, *ivars):
        self.obj = obj
        self.ivars = get_ivars(obj, *ivars)

    def _eval(self, expr):
        frame = self.obj.GetThread().GetSelectedFrame()
        return frame.EvaluateExpression(expr)

    def _get_ivar(self, addr, ivar):
        return get_ivar(self.obj, addr, ivar)

    def _to_str(self, val):
        return self.obj.GetProcess().ReadCStringFromMemory(val, 1024, lldb.SBError())

    def _value_from_ivar(self, ivar):
        return self.obj.CreateChildAtOffset(ivar, self.ivars[ivar], get_type(self.obj, 'id'))

schema_cache = {}
class RLMObject_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, obj, _):
        super(RLMObject_SyntheticChildrenProvider, self).__init__(obj,
                'objectSchema', 'realm')

        if not obj.GetAddress() or is_object_deleted(obj):
            self.props = []
            return

        object_schema = self._get_ivar(self.obj.GetAddress(), 'RLMObject._objectSchema')

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

def RLM_SummaryProvider(obj, _):
    frame = obj.GetThread().GetSelectedFrame()
    addr = unsigned(frame.EvaluateExpression('RLMDebugSummary({})'.format(obj.GetAddress())))
    if addr == 0:
        return None
    return obj.GetProcess().ReadCStringFromMemory(addr, 1024, lldb.SBError())

class RLMArray_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, valobj, _):
        super(RLMArray_SyntheticChildrenProvider, self).__init__(valobj, 'realm')
        self.addr = self.obj.GetAddress()
        self.type = get_type(self.obj, 'id')

    def num_children(self):
        if not self.count:
            self.count = unsigned(self._eval("RLMDebugArrayCount({})".format(self.addr)))
        return self.count + 1

    def has_children(self):
        return True

    def get_child_index(self, name):
        if name == 'Some' or name == 'value':
            return None
        if name == 'realm':
            return 0
        if not name.startswith('['):
            return None
        return int(name.lstrip('[').rstrip(']')) + 1

    def get_child_at_index(self, index):
        if index == 0:
            return self._value_from_ivar('realm')

        key = '[' + str(index - 1) + ']'
        value = self._eval('RLMDebugArrayChildAtIndex({}, {})'.format(self.addr, index - 1))
        return self.obj.CreateValueFromData(key, value.GetData(), self.type)

    def update(self):
        self.count = None

def __lldb_init_module(debugger, _):
    debugger.HandleCommand('type summary add RLMArray -F rlm_lldb.RLM_SummaryProvider')
    debugger.HandleCommand('type summary add RLMArrayLinkView -F rlm_lldb.RLM_SummaryProvider')
    debugger.HandleCommand('type summary add RLMResults -F rlm_lldb.RLM_SummaryProvider')
    debugger.HandleCommand('type summary add -x RLMAccessor_ -F rlm_lldb.RLM_SummaryProvider')

    debugger.HandleCommand('type synthetic add RLMArray --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMArrayLinkView --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMResults --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add -x RLMAccessor_.* --python-class rlm_lldb.RLMObject_SyntheticChildrenProvider')
