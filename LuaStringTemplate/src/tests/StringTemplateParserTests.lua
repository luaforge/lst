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

    This module tests the low level parsing of a template string into text
    and expression chunks.

--]]

local require = require
local pcall = pcall
local print = print
local ipairs = ipairs

require( 'lunit' )

module( 'StringTemplateParserTests', lunit.testcase )

local STParser = require( 'lst.StringTemplateParser' )
local parser

function setup()
    parser = STParser()
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

function testParseJustTextNoNewline()
    local result = parser:parse('plain text')

    -- print(result)

    assert_table(result)
    assert_equal(1, #result)
    assert_equal('plain text', result[1])
end

function testParseJustTextWithNewline()
    local expected = { 'text1', '\n', 'text2', '\n', 'text3' }
    local result = parser:parse('text1\ntext2\ntext3')

    assert_table(result)
    assert_equal(5, #result)
    for i,v in ipairs(result) do
        assert_equal(expected[i], result[i])
    end
end

function testParseTextWithAction()
    local expected = { 'text1 ', 'action1', ' text2' }
    local result = parser:parse('text1 $action1$ text2')

    assert_table(result)
    assert_equal(3, #result)
    for i,v in ipairs(result) do
        assert_equal(expected[i], result[i])
    end
end

function testParseTextWithActionNoSpaces()
    local expected = { 'text1', 'action1', 'text2' }
    local result = parser:parse('text1$action1$text2')

    assert_table(result)
    assert_equal(3, #result)
    for i,v in ipairs(result) do
        assert_equal(expected[i], result[i])
    end
end

function testParseEscapedDollarSign()
    local expected = { 'text1', '\n', 'te$xt2' }
    local result = parser:parse('text1\nte\\$xt2')

    assert_table(result)
    assert_equal(3, #result)
    for i,v in ipairs(result) do
        assert_equal(expected[i], result[i])
    end
end


