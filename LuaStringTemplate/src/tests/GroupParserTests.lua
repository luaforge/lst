--[[

    Copyright (c) 2008, Glenn McAllister All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.

        * Neither the name of LuaStringTempalte nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.

    This module tests the StringTemplateGroupParser class.

--]]

local require = require
local pcall = pcall
local pairs = pairs
local tostring = tostring
local print = print
local type = type
local getmetatable = getmetatable
local string_rep = string.rep

require( 'lunit' )

module( 'GroupParserTests', lunit.testcase )

local utils = require( 'utils' )
local STGParser = require( 'lst.StringTemplateGroupParser' )
local StringTemplate = require( 'lst.StringTemplate' )
local GroupMetaData = require( 'lst.GroupMetaData' )
local GroupTemplate = require( 'lst.GroupTemplate' )
local GroupMap = require( 'lst.GroupMap' )

local stOpts = { scanner = StringTemplate.ANGLE_BRACKET_SCANNER }

function assert_table_equal(expected, actual, debug, depth)
    assert_table(actual)
    assert_equal(#expected, #actual)
    depth = depth or 1
    debug = debug or false

    for k,v in pairs(expected) do
        local v2 = actual[k]
        local eq = tostring(v == v2)
        local leader = string_rep('-', depth)
        local leader = leader .. '>'

        if debug then 
            print(leader .. ' k:', k, ' v:', v, 'v2:', v2, 'eq:', eq) 
        end
        if type(v) == 'table' and type(v2) == 'table' then
            --[[
            --  If the objects have the isA function, they are 
            --   LuaStringTemplate custom classes, and they have 
            --   __eq metamethods.
            --]]
            if type(v.isA) == 'function' and type(v2.isA) == 'function' then
                if debug then
                    print(leader .. ' objects are lst classes')
                end
                assert_equal(v, v2)
            else
                if debug then
                    print(leader .. ' regular tables, recurse into assert_table_equal')
                end
                assert_table_equal(v, v2, debug, depth + 1)
            end
        else
            if debug then
                print(leader .. ' regular eq comparison')
            end
            assert_equal(v, actual[k])
        end
    end
end

local parser

function setup()
    parser = STGParser()
end

function teardown()
    parser = nil
end

function testParseNil()
    local ok, errmsg = pcall(parser.parse, parser, nil)
    assert_false(ok, 'error expected but no error occured')
end

function testParseEmptyString()
    local result = parser:parse('')

    assert_table(result)
    assert_equal(0, #result)
end

function testGroupName()
    local result = parser:parse('group test;')
    local gmd = GroupMetaData('test', '', {})
    local expected = { gmd, '' }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testInheritsFrom()
    local result = parser:parse('group test : yadda;')
    local gmd = GroupMetaData('test', 'yadda', {})
    local expected = { gmd, '' }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testImplements()
    local result = parser:parse('group test implements a;')
    local gmd = GroupMetaData('test', '', { 'a' })
    local expected = { gmd, '' }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testImplementsMany()
    local result = parser:parse('group foo implements a, b ; ')
    local gmd = GroupMetaData('foo', '', { 'a', 'b' })
    local expected = { gmd, '' }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testBasicTemplateDef()
    local result = parser:parse([=[group foo;

t1(a) ::= "just text"

]=])
    local gmd = GroupMetaData('foo', '', {})
    local t1 = GroupTemplate('t1', {'a'}, 
                StringTemplate('just text', 
                               { scanner = StringTemplate.ANGLE_BRACKET_SCANNER } 
                              )
                            )
    local expected = { gmd, { t1 } }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testBasicTemplateDef2()
    local result = parser:parse([=[
group foo;

t1() ::= "just text"

t2(a,b) ::= "sub <a> and <b>"

]=])

    local gmd = GroupMetaData('foo', '', {})
    local t1 = GroupTemplate('t1', {},
                StringTemplate('just text', 
                               { scanner = StringTemplate.ANGLE_BRACKET_SCANNER } 
                              )
                            )
    local t2 = GroupTemplate('t2', {'a', 'b'},
                StringTemplate('sub <a> and <b>',
                                { scanner = StringTemplate.ANGLE_BRACKET_SCANNER }
                              )
                            )

    local expected = { gmd, { t1, t2 } }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testMultiLineTemplateDef()
    local result = parser:parse([=[
group foo;

t1() ::= "just text"

t2(a,b) ::= <<
sub <a> and <b>

>>

]=])

    local gmd = GroupMetaData('foo', '', {})
    local t1 = GroupTemplate('t1', {},
                StringTemplate('just text', 
                               { scanner = StringTemplate.ANGLE_BRACKET_SCANNER } 
                              )
                            )
    local t2 = GroupTemplate('t2', {'a', 'b'},
                StringTemplate('sub <a> and <b>\n',
                                { scanner = StringTemplate.ANGLE_BRACKET_SCANNER }
                              )
                            )

    local expected = { gmd, { t1, t2 } }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testBadSingleLineTemplate()
    local result = parser:parse([=[group foo;

t1(a) ::= "can't have a
newline in a single line template"

]=])

    assert_nil(result)  -- should fail to parse
end

local stOpts = { scanner = StringTemplate.ANGLE_BRACKET_SCANNER }

function testALoneMultilineTemplate()
    local result = parser:parse([=[
group foo;

t2(a,b) ::= <<
sub <a> and <b>

>>

]=])

    local gmd = GroupMetaData('foo', '', {})
    local t2 = GroupTemplate('t2', {'a', 'b'},
                StringTemplate('sub <a> and <b>\n', stOpts)
                            )

    local expected = { gmd, { t2 } }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testParamsWithSpaces()
    local result = parser:parse([=[
group foo;

t1(a, b, c) ::= "some text"

]=])

    local gmd = GroupMetaData('foo', '', {})
    local t1 = GroupTemplate('t1', {'a', 'b', 'c'},
                StringTemplate('some text', stOpts)
                            )

    local expected = { gmd, { t1 } }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testMap()
    local result = parser:parse([=[
group foo;

typeInitMap ::= [
        "int" : "0",
        "long" : "0",
        "float" : "0.0",
        "double" : "0.0",
        "boolean" : "false"
    ]

]=])

    local gmd = GroupMetaData('foo', '', {})
    local m1 = GroupMap('typeInitMap', 
                        { 
                            { 'int', StringTemplate('0', stOpts) },
                            { 'long', StringTemplate('0', stOpts) },
                            { 'float', StringTemplate('0.0', stOpts) },
                            { 'double', StringTemplate('0.0', stOpts) },
                            { 'boolean', StringTemplate('false', stOpts) }
                        }
                       )

   local expected = { gmd, { m1 } }

   assert_table(result)
   assert_table_equal(expected, result)
end
