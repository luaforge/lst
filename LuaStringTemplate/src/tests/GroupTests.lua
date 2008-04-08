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

    This module tests the StringTemplateGroup class.

--]]

local require = require
local tostring = tostring
local print = print
local pcall = pcall
local ipairs = ipairs
local os_getenv = os.getenv
local os_remove = os.remove
local lassert = assert
local io_open = io.open

require( 'lunit' )

module( 'GroupTests', lunit.testcase )

local utils = require( 'utils' )

local StringTemplateGroup = require( 'lst.StringTemplateGroup' )
local tmpDir = os_getenv('TEMP') or '/tmp'
local tmpFiles = {}

local function writeGroupFile(fname, text)
    local f = lassert(io_open(tmpDir .. '/' .. fname .. '.stg', "w+"))
    tmpFiles[#tmpFiles + 1] = fname
    f:write(text)
    f:close()
end

local function deleteGroupFile(fname)
    os_remove(tmpDir .. '/' .. fname)
end

function teardown()
    for i,fname in ipairs(tmpFiles) do
        deleteGroupFile(fname)
        tmpFiles[i] = nil
    end

    assert_true(#tmpFiles == 0)
end

function testNoArgConstructor()
    local ok, errmsg = pcall(StringTemplateGroup.__call, StringTemplateGroup)
    assert_false(ok)
    assert_not_nil(errmsg)
end

function testBadTwoArgConstructor()
    local ok, errmsg = pcall(StringTemplateGroup.__call,
                             StringTemplateGroup,
                             {},
                             {})
    assert_false(ok)
    assert_not_nil(errmsg)
end

function testBadSingleArgConstructor()
    local ok, errmsg = pcall(StringTemplateGroup.__call,
                             StringTemplateGroup,
                             'bad')
    assert_false(ok)
    assert_not_nil(errmsg)
end

function testMissingArgConstructor()
    local ok, errmsg = pcall(StringTemplateGroup.__call,
                             StringTemplateGroup,
                             { dir = '/tmp' })
    assert_false(ok)
    assert_not_nil(errmsg)

    local ok, errmsg = pcall(StringTemplateGroup.__call,
                             StringTemplateGroup,
                             { name = 'foo' })
    assert_false(ok)
    assert_not_nil(errmsg)
end

function testLoadBasicGroupFile()
    writeGroupFile("g1", [=[
group g1;

t1() ::= "some text"

]=])

    local stg = StringTemplateGroup('g1', tmpDir)

    assert_not_nil(stg)
end

function testGetInstanceOf()
    writeGroupFile("g2", [=[
group g2;

t2( a, b, c ) ::= <<

Some <a>, a <b>, and <c> <\n>

>>

]=])

    local stg = StringTemplateGroup('g2', tmpDir)
    local t2 = stg:getInstanceOf('t2')

    t2.a = 'foo'
    t2.b = 'bar'
    t2.c = 'baz'

    local expected = '\nSome foo, a bar, and baz \n\n'
    local result = tostring(t2)

    assert_not_nil(stg)
    assert_not_nil(t2)
    assert_not_nil(result)
    assert_equal(expected, result)
end

function testGetInstanceOfMissingTemplate()
    writeGroupFile('g3', [=[
group g3;

t1() ::= "blah"

]=])

    local stg = StringTemplateGroup('g3', tmpDir)
    local t2 = stg:getInstanceOf('t2')

    assert_not_nil(stg)
    assert_nil(t2)
end

--[[
--  This test really just checks that the map is correctly 
--  parsed.  We can't check that it works until we have map
--  references implemented in a template.
--]]
function testBasicMap()
    writeGroupFile('g4', [=[
group g4;

initTypeMap ::= [
    "int" : "0",
    "long" : "0",
    "float" : "0.0",
    "double" : "0.0",
    "boolean" : "false"
]

]=])

    local stg = StringTemplateGroup('g4', tmpDir)

    assert_not_nil(stg)
end

function testTrivialTemplateRef()
    writeGroupFile('g5', [=[
group g5;

t1() ::= <<
a <t2()> d
>>

t2() ::= <<
b c
>>

]=])
    
    local stg = StringTemplateGroup('g5', tmpDir)
    local st = stg:getInstanceOf('t1')

    local expected = "a b c d"
    local result = tostring(st)

    assert_not_nil(stg)
    assert_equal(expected, result)
end

function testTemplateRefWithAttrRef()
    writeGroupFile('g6', [=[
group g6;

t1() ::= <<
a <t2()> d
>>

t2() ::= <<
b c <foo>
>>

]=])

    local stg = StringTemplateGroup('g6', tmpDir)
    local st = stg:getInstanceOf('t1')
    st.foo = 'z y x'

    local expected = "a b c z y x d"
    local result = tostring(st)

    assert_not_nil(stg)
    assert_equal(expected, result)
end

function testTemplateRefWithAttrRefOptions()
    writeGroupFile('g6', [=[
group g6;

t1() ::= <<
a <t2()> d
>>

t2() ::= <<
b c <foo; separator="\n">
>>

]=])

    local stg = StringTemplateGroup('g6', tmpDir)
    local st = stg:getInstanceOf('t1')
    st.foo = { 'z', 'y', 'x' }

    local expected = "a b c z\ny\nx d"
    local result = tostring(st)

    -- utils.dump_table('stg', stg)

    assert_not_nil(stg)
    assert_equal(expected, result)
end

function testTemplateRefWithParams()
    writeGroupFile('g6', [=[
group g6;

t1() ::= <<
a <t2(foo=bar)> d
>>

t2(foo) ::= <<
b c <foo; separator="\t">
>>

]=])

    local stg = StringTemplateGroup('g6', tmpDir)
    local st = stg:getInstanceOf('t1')
    st.bar = { 'z', 'y', 'x' }

    local expected = "a b c z\ty\tx d"
    local result = tostring(st)

    -- utils.dump_table('stg', stg)

    assert_not_nil(result)
    assert_equal(expected, result)
end

function testTemplateRefIndent()
    writeGroupFile('g7', [=[
group g7;

t1() ::= <<
    <t2()> z y x
>>

t2() ::= <<
  a
b
  c
>>

]=])

    local stg = StringTemplateGroup('g7', tmpDir)
    local st = stg:getInstanceOf('t1')

    local expected = "      a\n    b\n      c z y x"
    local result = tostring(st)

    --utils.dump_table('st', st)

    assert_not_nil(result)
    assert_equal(expected, result)
end

function testTemplateRefMultiIndent()
    writeGroupFile('g8', [=[
group g8;

t1() ::= <<
  <t2()>
>>

t2() ::= <<
  <t3()>
baz
>>

t3() ::= <<
foo
bar
>>

]=])

    local stg = StringTemplateGroup('g8', tmpDir)
    local st = stg:getInstanceOf('t1')

    local expected = "    foo\n    bar\n  baz"
    local result = tostring(st)

    --utils.dump_table('st', st)

    assert_not_nil(result)
    assert_equal(expected, result)
end

