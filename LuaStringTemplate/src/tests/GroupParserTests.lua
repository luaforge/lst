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

require( 'lunit' )

module( 'GroupParserTests', lunit.testcase )

local assert_table_equal = function(expected, actual)
    assert_table(actual)
    assert_equal(#expected, #actual)

    for i = 1, #expected do
        -- print(expected[i], actual[i])
        assert_equal(expected[i], actual[i])
    end
end

local STGParser = require( 'lst.StringTemplateGroupParser' )
local GroupMetaData = require( 'lst.GroupMetaData' )

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
    local expected = { gmd }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testInheritsFrom()
    local result = parser:parse('group test : yadda;')
    local gmd = GroupMetaData('test', 'yadda', {})
    local expected = { gmd }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testImplements()
    local result = parser:parse('group test implements a;')
    local gmd = GroupMetaData('test', '', { 'a' })
    local expected = { gmd }

    assert_table(result)
    assert_table_equal(expected, result)
end

function testImplementsMany()
    local result = parser:parse('group foo implements a, b ; ')
    local gmd = GroupMetaData('foo', '', { 'a', 'b' })
    local expected = { gmd }

    assert_table(result)
    assert_table_equal(expected, result)
end


