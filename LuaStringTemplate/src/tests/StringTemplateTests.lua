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
local print = print

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

function testEvalUsingSTToString()
    local st = StringTemplate('just text')
    local expected = 'just text'
    local actual = st:tostring()

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

function testEvalAttrWithPropertyAndSep()
    local st = StringTemplate('one $foo.bar; separator="\\n"$ three')
    local expected = 'one two\ntwo.five three'

    st['foo'] = { bar = { 'two', 'two.five' } }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalAttrWithNestedProperty()
    local st = StringTemplate('one $foo.bar.baz$ three')
    local expected = 'one two three'

    st['foo'] = { bar = { baz = 'two' } }

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

--[=[
--  This test requires a bit of explanation.  In the original StringTemplate
--  language, you can have null values in the list.  They are ignored by default
--  and produce no output.  You can do $attr; null="-1", separator=","$ to say
--  "use the string '-1' when you encounter a null."
--
--  The thing is, in Lua we use an array to represent multi-valued attributes.
--  You can't embed a null into the middle of the list, as it is immediately
--  garbage collected, so suddenly your index numbers skip a value, and ipairs
--  no longer works past the break.  Also, table.concat is used to concatenate
--  the values in the array, and it can't handle nulls in the middle of the 
--  array either.
--
--  The upshot is that the null="..." part of an attribute reference will never
--  be implemented as it is in the original StringTemplate.  However, it should
--  be parsed and quietly ignored.
--]=]
function testEvalIgnoreNull()
    local st = StringTemplate('one $foo; null="a", separator="?"$ five')
    local expected = 'one two?three five'

    st['foo'] = { 
        [1] = 'two', 
        [2] = 'three', 
    }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

--[=[
--   The following checks for options that StringTemplate supports,
--   although LuaStringTemplate doesn't currently.
--]=]

function testEvalFormatOption()
    local st = StringTemplate('one $foo; format="f"$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalWrapOption()
    local st = StringTemplate('one $foo; wrap="\\n"$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalWrapOptionWithDefault()
    local st = StringTemplate('one $foo; wrap$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalAnchor()
    local st = StringTemplate('one $foo; anchor="true"$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalAnchorWithDefault()
    local st = StringTemplate('one $foo; anchor$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalMultipleOptions()
    local st = StringTemplate('one $foo; null="yadda", wrap, separator="|", anchor, format="f"$ three')
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalIndirectProperty()
    local st = StringTemplate('one $foo.(bar)$ three')
    local expected = 'one two three'

    st.foo = { yadda = 'two' }
    st.bar = 'yadda'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testEvalDoubleIndirectProperty()
    local st = StringTemplate('one $foo.(bar)$ three')
    local expected = 'one two three'

    st.foo = { yadda = { blah = 'two' } }
    st.bar = 'yadda.blah'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testABScanner()
    local st = StringTemplate('one <foo> three', 
                                {
                                    scanner = StringTemplate.ANGLE_BRACKET_SCANNER
                                }
                             )
    local expected = 'one two three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testABScannerWithProperty()
    local st = StringTemplate('one <foo.bar> three', 
                                {
                                    scanner = StringTemplate.ANGLE_BRACKET_SCANNER
                                }
                             )
    local expected = 'one two three'

    st.foo = { bar = 'two' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testDSComment()
    local st = StringTemplate('one $! some long \n winded comment !$ two $! another comment !$ three')
    local expected = 'one  two  three'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

--[=[
--  Its worth noting that the comment marker depends on which
--  scanner/expression delimiter is being used, LuaStringTemplate
--  doesn't automatically strip out both.
--]=]
function testABComment()
    local st = StringTemplate('one <! to strip !> two', 
                                {
                                    scanner = StringTemplate.ANGLE_BRACKET_SCANNER
                                }
                             )
    local expected = 'one  two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testCommentAndAttrRef()
    local st = StringTemplate('one $! to strip !$ two $foo$')
    local expected = 'one  two three'

    st.foo = 'three'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testNewlineEscapeExpr()
    local st = StringTemplate('one$\\n$two')
    local expected = 'one\ntwo'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testCREscapeExpr()
    local st = StringTemplate('one$\\r$two')
    local expected = 'one\rtwo'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testTabEscapeExpr()
    local st = StringTemplate('one$\\t$two')
    local expected = 'one\ttwo'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testSpaceEscapeExpr()
    local st = StringTemplate('one$\\ $two')
    local expected = 'one two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testMultipleEsacpeExpr()
    local st = StringTemplate('one$\\n\\r\\t\\ $two')
    local expected = 'one\n\r\t two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testAutoIndent()
    local st = StringTemplate('one\n\n\t$foo; separator="\\n"$\nfive')
    local expected = 'one\n\n\ttwo\n\tthree\n\tfour\nfive'

    st.foo = { 'two', 'three', 'four' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testNoAutoIndent()
    local st = StringTemplate('one\n\n\t$foo; separator="\\n"$\nfive',
                                { auto_indent = false }
                             )
    local expected = 'one\n\n\ttwo\nthree\nfour\nfive'

    st.foo = { 'two', 'three', 'four' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testIfExpr()
    local st = StringTemplate('one $if(foo)$ two $endif$ three')
    local expected = 'one  two  three'

    st.foo = 'I exist!'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testIfExprWithAttrRef()
    local st = StringTemplate('one $if(foo)$ $foo$ $endif$ three')
    local expected = 'one  two  three'

    st.foo = 'two'
    
    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testIfExprWithProperty()
    local st = StringTemplate('one $if(foo.bar)$ $foo.bar$ $endif$ three')
    local expected = 'one  two  three'

    st.foo = { bar = 'two' }
    
    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testIfExprWithIndirectProperty()
    local st = StringTemplate('one $if(foo.(bar))$ $foo.fred$ $endif$ three')
    local expected = 'one  yadda  three'

    st.bar = 'fred'
    st.foo = { fred = 'yadda' }

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

--[[
function testIfExprNegated()
    local st = StringTemplate('one $if(!foo)$ $bar$ $endif$ three')
    local expected = 'one  two  three'

    st.bar = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end

function testIfExprNegatedFailure()
    local st = StringTemplate('one $if(!foo)$ $foo$ $endif$ three')
    local expected = 'one  three'

    st.foo = 'two'

    local actual = tostring(st)

    assert_not_nil(actual)
    assert_equal(expected, actual)
end
--]]
