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

local StringTemplateGroup = require( 'lst.StringTemplateGroup' )
local tmpDir = os_getenv('TEMP') or '/tmp'
local tmpFiles = {}

local function writeGroupFile(fname, text)
    local f = lassert(io_open(tmpDir .. '/' .. fname, "w+"))
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
    writeGroupFile("g1.stg", [=[
group g1;

t1() ::= "some text"

]=])

    local stg = StringTemplateGroup('g1.stg', tmpDir)

    assert_not_nil(stg)
end

function testGetInstanceOf()
    writeGroupFile("g2.stg", [=[
group g2;

t2( a, b, c ) ::= <<

Some <a>, a <b>, and <c> <\n>

>>

]=])

    local stg = StringTemplateGroup('g2.stg', tmpDir)
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
    writeGroupFile('g3.stg', [=[
group g3;

t1() ::= "blah"

]=])

    local stg = StringTemplateGroup('g3.stg', tmpDir)
    local t2 = stg:getInstanceOf('t2')

    assert_not_nil(stg)
    assert_nil(t2)
end

