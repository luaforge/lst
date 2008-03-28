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

    This module tests the StringTemplate class.

--]]

local require = require
local tostring = tostring
local pcall = pcall

require( 'lunit' )

module( 'StringTemplateTests', lunit.testcase )

local StringTemplate = require( 'lst.StringTemplate' )

function testNoArgCnstr()
    local st,err = StringTemplate()
    assert_not_equal(st, nil)
    assert_equal(err, nil)
end

function testEvalSimpleText()
    local st = StringTemplate('just text')
    local expected = 'just text'
    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMultiLineText()
    local st = StringTemplate('text1\ntext2\ntext3')
    local expected = 'text1\ntext2\ntext3'
    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalAttribute()
    local st = StringTemplate('one $yadda$ three')
    local expected = 'one two three'

    st['yadda'] = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalAttrWithProperty()
    local st = StringTemplate('one $foo.bar$ three')
    local expected = 'one two three'

    st['foo'] = { bar = 'two' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMissingAttribute()
    local st = StringTemplate('one $yadda$ three')
    local expected = 'one  three'
    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMissingProperty()
    local st = StringTemplate('one $foo.bar$ three')
    local expected = 'one  three'

    st['foo'] = {}

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMissingAttrWithProperty()
    local st = StringTemplate('one $foo.bar$ three')
    local expected = 'one  three'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMultiValAttribute()
    local st = StringTemplate('one $foo$ five')
    local expected = 'one twothreefour five'

    st['foo'] = { 'two', 'three', 'four' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMultiValAttrWithSep()
    local st = StringTemplate('one $foo; separator=","$ five')
    local expected = 'one two,three,four five'

    st['foo'] = { 'two', 'three', 'four' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMultiValAttrWithEmptySep()
    local st = StringTemplate('one $foo; separator=""$ five')
    local expected = 'one twothreefour five'

    st['foo'] = { 'two', 'three', 'four' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalSepWithoutAttr()
    local ok, errmsg = pcall(StringTemplate, StringTemplate, 'one $;separator=","$ three')
    assert_false(ok)
end

