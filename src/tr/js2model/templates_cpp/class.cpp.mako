<%doc>
Copyright (c) 2015 Thomson Reuters

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</%doc>
<%inherit file="base.mako" />
<%namespace name="base" file="base.mako" />
<%block name="code">
#include "${classDef.header_file}"
#include <vector>
#include <fstream>
#include <sstream>

#if _DEBUG
#include "schema.h"
#endif  // _DEBUG

#define UNUSED(x) [&x]{}()

using namespace std;
using namespace rapidjson;

<%
class_name = classDef.name
%>\
namespace ${namespace} {
namespace models {


${class_name}::${class_name}() {
    % for v in classDef.variable_defs:
<%
    inst_name = base.attr.inst_name(v.name)
%>\
    %if not v.isArray:
    %if v.schema_type == 'integer':
    ${inst_name} = ${v.get_default_value()};
    %elif v.schema_type == 'number':
    ${inst_name} = ${v.get_default_value()};
    %elif v.schema_type == 'boolean':
	%if v.get_default_value(): 
	${inst_name} = true;
	%else:
	${inst_name} = false;
	%endif
	%elif v.schema_type == 'object':
	${inst_name} = ${v.type}();
    %endif
    %endif
    % endfor
}


${class_name}::${class_name}(const rapidjson::Value &json_value) {

    assert(json_value.IsObject());

    % for v in classDef.variable_defs:
<%
    var_iter = v.name + '_iter'
    inst_name = base.attr.inst_name(v.name)
%>\

    %if not v.isArray:
    %if v.schema_type == 'integer':
    ${inst_name} = ${v.get_default_value()};
    %elif v.schema_type == 'number':
    ${inst_name} = ${v.get_default_value()};
    %elif v.schema_type == 'boolean':
	%if v.get_default_value(): 
	${inst_name} = true;
	%else:
	${inst_name} = false;
	%endif
    %endif
    %endif

    auto ${var_iter} = json_value.FindMember("${v.json_name}");
    if ( ${var_iter} != json_value.MemberEnd() ) {

        %if v.isArray:
        for( auto array_item = ${var_iter}->value.Begin(); array_item != ${var_iter}->value.End(); array_item++  ) {

            % if v.schema_type == 'string':
            if (!array_item->IsNull()) {
                assert(array_item->IsString());
                ${inst_name}.push_back(array_item->GetString());
            }
            %elif v.schema_type == 'integer':
            assert(array_item->IsInt());
            ${inst_name}.push_back(array_item->GetInt());
            %elif v.schema_type == 'number':
            assert(array_item->IsNumber());
            ${inst_name}.push_back(array_item->GetFloat());
            %elif v.schema_type == 'boolean':
            assert(array_item->IsBool());
            ${inst_name}.push_back(array_item->GetBool());
            %elif v.schema_type == 'object':
            assert(array_item->IsObject());
            ${inst_name}.push_back(${v.type}(*array_item));
            %elif v.schema_type == 'array':
            ## handle arrays of arrays
            assert(array_item->IsArray());
            % if v.type == 'string':
            std::vector<string> item_array;
            %elif v.type == 'integer':
            std::vector<int> item_array;
            %elif v.type == 'number':
            std::vector<float> item_array;
            %elif v.type == 'boolean':
            std::vector<bool> item_array;
            %endif
            for( auto item = array_item->Begin(); item != array_item->End(); item++  ) {

                % if v.type == 'string':
                if (!item->IsNull()) {
                    assert(item->IsString());
                    item_array.push_back(item->GetString());
                }
                %elif v.type == 'integer':
                assert(item->IsInt());
                item_array.push_back(item->GetInt());
                %elif v.type == 'number':
                assert(item->IsNumber());
                item_array.push_back(item->GetFloat());
                %elif v.type == 'boolean':
                assert(item->IsBool());
                item_array.push_back(item->GetBool());
                %endif
            }
            ${inst_name}.push_back(item_array);
            %endif
        }
        %else:
        % if v.schema_type == 'string':
        if (${var_iter}->value.IsNull()) {
            ${inst_name}.clear();
        }
        else {
            assert(${var_iter}->value.IsString());
            ${inst_name} = ${var_iter}->value.GetString();
        }
        %elif v.schema_type == 'integer':
        if (!${var_iter}->value.IsNull()) {
            assert(${var_iter}->value.IsInt());
            ${inst_name} = ${var_iter}->value.GetInt();
        }
        %elif v.schema_type == 'number':
        if (!${var_iter}->value.IsNull()) {
            assert(${var_iter}->value.IsNumber());
            ${inst_name} = ${var_iter}->value.GetFloat();
        }
        %elif v.schema_type == 'boolean':
        if (!${var_iter}->value.IsNull()) {
            assert(${var_iter}->value.IsBool());
            ${inst_name} = ${var_iter}->value.GetBool();
        }
        %elif v.schema_type == 'object':
        if (!${var_iter}->value.IsNull()) {
            assert(${var_iter}->value.IsObject());
            ${inst_name} = ${v.type}(${var_iter}->value);
        }
        else {
            ${inst_name} = ${v.type}();
        }
        %elif v.schema_type == 'dict':
        if (!${var_iter}->value.IsNull()) {
            assert(${var_iter}->value.IsObject());
            for ( auto it = ${var_iter}->value.Begin(); it != ${var_iter}->value.End(); ++it )
            {
                // TBD - fix values
                assert( false );
            }
        }
        %endif
        %endif
    }

    % endfor
}

string to_string(const ${class_name} &val, std::string indent/* = "" */, std::string pretty_print/* = "" */) {

    ostringstream os;

    os << "{" << endl;
    <%
        bFirst = True
    %>
	bool	bFirstElement = true;
	UNUSED(bFirstElement);
    % for v in classDef.variable_defs:
	<%
    inst_name = base.attr.inst_name(v.name)
	%>\
	% if bFirst == True:
    <%
        bFirst = False
    %>
	% else:
		os << "," << endl;
    % endif
    %if v.isArray:
	bFirstElement = true;
    os << indent << pretty_print << "\"${v.name}\": [";
    % if v.schema_type == 'boolean':
    for( const bool &array_item : val.${inst_name} ) {
    %else:
    for( auto &array_item : val.${inst_name} ) {
    %endif
		if ( bFirstElement ) bFirstElement = false; else os << ", ";
        % if v.schema_type == 'string':
        os << "\"" << array_item << "\"";
        %elif v.schema_type == 'integer':
        os << array_item;
        %elif v.schema_type == 'number':
        os << array_item;
        %elif v.schema_type == 'boolean':
        os << (array_item ? "true" : "false");
        %elif v.schema_type == 'object':
        os << endl << to_string(array_item, indent + pretty_print + pretty_print, pretty_print);
        %elif v.schema_type == 'array':
        ## handle arrays of arrays
        for (auto item = array_item.begin(); item != array_item.end(); item++) {
            % if v.type == 'string':
            os << "\"" << *item << "\"";
            %elif v.type == 'integer':
            os << *item;
            %elif v.type == 'number':
            os << *item;
            %elif v.type == 'boolean':
            os << (*item ? "true" : "false");
            %elif v.type == 'object':
            os << endl << to_string(*item, indent + pretty_print + pretty_print, pretty_print);
            %endif
        }
        %endif
    }
    os << indent << pretty_print << "]";
    %else:
    % if v.schema_type == 'string':
    os << indent << pretty_print << "\"${v.name}\": \"" << val.${inst_name} << "\"";
    %elif v.schema_type == 'number':
    os << indent << pretty_print << "\"${v.name}\": " << val.${inst_name};
    %elif v.schema_type == 'integer':
    os << indent << pretty_print << "\"${v.name}\": " << val.${inst_name};
    %elif v.schema_type == 'boolean':
    os << indent << pretty_print << "\"${v.name}\": " << (val.${inst_name} ? "true" : "false");
    %elif v.schema_type == 'object':
    os << indent << pretty_print << "\"${v.name}\": " << to_string(val.${inst_name}, indent + pretty_print, pretty_print);
    %endif
    %endif
    % endfor
    os << indent << endl << "}" << endl;

    return os.str();
}


<%
staticInitName = classDef.plain_name
%>\
${class_name} ${staticInitName}FromJsonData(const char *data, size_t len) {

    std::vector<char> buffer(len + 1);

    std::memcpy(&buffer[0], data, len);

    Document doc;

    doc.ParseInsitu(&buffer[0]);

#if _DEBUG
    assert( !doc.HasParseError() );

    SchemaDocument schema( doc );

    SchemaValidator validator(schema);
    assert( doc.Accept(validator) );
#endif  // _DEBUG

    return ${class_name}(doc);
}

${class_name} ${staticInitName}FromFile(string filename) {

    ifstream is;

    stringstream buffer;

    is.open(filename);
    buffer << is.rdbuf();

    ${class_name} instance = ${staticInitName}FromJsonData(buffer.str().c_str(), buffer.str().length());

    return instance;
}

<%
array_var_name = staticInitName + 'Array'
%>\
std::vector<${class_name}> ${staticInitName}ArrayFromData(const char *jsonData, size_t len) {

    std::vector<char> buffer(len + 1);

    std::memcpy(&buffer[0], jsonData, len);

    Document doc;

    doc.ParseInsitu(&buffer[0]);

    assert(doc.IsArray());

    std::vector<${class_name}> ${array_var_name};
    ${array_var_name}.reserve(doc.Size());

    for( auto array_item = doc.Begin(); array_item != doc.End(); array_item++  ) {

        ${class_name} instance = ${class_name}(*array_item);
        ${array_var_name}.push_back(instance);
    }

    return ${array_var_name};
}

} // namespace models
} // namespace ${namespace}

</%block>
