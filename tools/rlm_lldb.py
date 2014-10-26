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

import lldb

# command script import /src/rlm_lldb.py --allow-reload

property_types = {
    0: 'int64_t',
    10: 'double',
    1: 'bool',
    9: 'float',
}

def to_str(val):
    return val.GetProcess().ReadCStringFromMemory(val.GetValueAsUnsigned(), 1024, lldb.SBError())

cached_schemas = {}

class SyntheticChildrenProvider(object):
    def _eval(self, expr):
        frame = self.obj.GetThread().GetSelectedFrame()
        return frame.EvaluateExpression(expr)

class RLMObject_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, obj, _):
        self.obj = obj
        objectSchema = self._eval("((RLMObject *){})->_objectSchema".format(self.obj.GetAddress())).GetValueAsUnsigned()

        self.props = cached_schemas.get(objectSchema, None)
        if not self.props:
            properties = self._eval("((RLMObjectSchema *){})->_properties".format(objectSchema)).GetValueAsUnsigned()
            count = self._eval("(NSUInteger)[((NSArray *){}) count]".format(properties)).GetValueAsUnsigned()
            self.props = [self._get_prop(properties, i) for i in range(count)]
            cached_schemas[objectSchema] = self.props

    def num_children(self):
        return len(self.props)

    def has_children(self):
        return True

    def get_child_index(self, name):
        return next(i for i, (prop_name, _) in enumerate(self.props) if prop_name == name)

    def get_child_at_index(self, index):
        name, getter = self.props[index]
        value = self._eval(getter)
        return self.obj.CreateValueFromData(name, value.GetData(), value.GetType())

    def update(self):
        pass

    def _get_prop(self, props, i):
        prop = self._eval("(NSUInteger)[((NSArray *){}) objectAtIndex:{}]".format(props, i)).GetValueAsUnsigned()
        name = to_str(self._eval("[((RLMProperty *){})->_name UTF8String]".format(prop)))
        type = self._eval("((RLMProperty *){})->_type".format(prop)).GetValueAsUnsigned()
        getter = "({})[(id){} {}]".format(property_types.get(type, 'id'), self.obj.GetAddress(), name)
        return name, getter

def RLMArray_SummaryProvider(obj, _):
    className = to_str(eval_objc(obj, "(const char *)[(NSString *)[(RLMArray *){} objectClassName] UTF8String]"))
    count = eval_objc(obj, "(NSUInteger)[(RLMArray *){} count]").GetValueAsUnsigned()
    return "({}[{}])".format(className, count)

class RLMArray_SyntheticChildrenProvider(SyntheticChildrenProvider):
    def __init__(self, valobj, _):
        self.obj = valobj
        self.addr = self.obj.GetAddress()

    def num_children(self):
        return self.count

    def has_children(self):
        return True

    def get_child_index(self, name):
        return int(name.lstrip('[').rstrip(']'))

    def get_child_at_index(self, index):
        value = self._eval('(id)[(id){} objectAtIndex:{}]'.format(self.addr, index))
        return self.obj.CreateValueFromData('[' + str(index) + ']', value.GetData(), value.GetType())

    def update(self):
        self.count = self._eval("(NSUInteger)[(RLMArray *){} count]".format(self.addr)).GetValueAsUnsigned()

def __lldb_init_module(debugger, _):
    debugger.HandleCommand('type summary add RLMArray -F rlm_lldb.RLMArray_SummaryProvider')
    debugger.HandleCommand('type summary add RLMArrayLinkView -F rlm_lldb.RLMArray_SummaryProvider')
    debugger.HandleCommand('type summary add RLMArrayTableView -F rlm_lldb.RLMArray_SummaryProvider')

    debugger.HandleCommand('type synthetic add RLMArray --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMArrayLinkView --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add RLMArrayTableView --python-class rlm_lldb.RLMArray_SyntheticChildrenProvider')
    debugger.HandleCommand('type synthetic add -x RLMAccessor_.* --python-class rlm_lldb.RLMObject_SyntheticChildrenProvider')
