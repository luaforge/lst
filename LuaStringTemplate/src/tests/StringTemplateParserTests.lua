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

    Tests to write:

        * Just text, get a LiteralChunk object.
        * Multiple lines of test, get multiple LiteralChunk objects

--]]

local require = require
local pcall = pcall
local print = print
local ipairs = ipairs
local type = type
local tostring = tostring

require( 'lunit' )

module( 'StringTemplateParserTests', lunit.testcase )

local assert_table_equal = function(expected, actual)
    assert_table(actual)
    assert_equal(#expected, #actual)

    for i = 1, #expected do
        -- print(expected[i], actual[i])
        assert_equal(expected[i], actual[i])
    end
end

local STParser = require( 'lst.StringTemplateParser' )
local LiteralChunk = require( 'lst.LiteralChunk' )
local NewlineChunk = require( 'lst.NewlineChunk' )
local AttrRefChunk = require( 'lst.AttrRefChunk' )
local EscapeChunk = require( 'lst.EscapeChunk' )
local parser, t1, t2, t3, nl, a1, e1

function setup()
    parser = STParser()
    t1, t2, t3 = LiteralChunk('text1'), LiteralChunk('text2'), LiteralChunk('text3')
    nl = NewlineChunk()
    a1 = AttrRefChunk('action1')
    e1 = EscapeChunk('\n');
end

function teardown()
    parser = nil
    t1, t2, t3 = nil, nil, nil
    nl = nil
    a1 = nil
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
    local expected = { LiteralChunk('plain text') }
    local result = parser:parse('plain text')
    assert_table_equal(expected, result)
end

function testParseJustTextWithNewline()
    local expected = { t1, nl, t2, nl, t3 }
    local result = parser:parse('text1\ntext2\ntext3')
    assert_table_equal(expected, result)
end

function testParseTextWithAction()
    local expected = { t1, a1, t2 }
    local result = parser:parse('text1$action1$text2')
    assert_table_equal(expected, result)
end

function testParseEscapedDollarSign()
    local expected = { t1, nl, LiteralChunk('te$xt2') }
    local result = parser:parse('text1\nte\\$xt2')
    assert_table_equal(expected, result)
end

function testParseComments()
    local expected = { t1, nl, nl, t2 }
    local result = parser:parse('text1\n$! stripped out !$\ntext2')
    assert_table_equal(expected, result)
end

function testParseEscapeChunk()
    local expected = { t1, e1, t2 }
    local result = parser:parse('text1$\\n$text2')
    assert_table_equal(expected, result)
end
