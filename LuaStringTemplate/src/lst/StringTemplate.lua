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

    The implementation of the StringTemplate class.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local ipairs = ipairs
local table_concat = table.concat
local tostring = tostring
local error = error
local print = print

module( 'lst.StringTemplate' )

local STParser = require( 'lst.StringTemplateParser' )
local LiteralChunk = require( 'lst.LiteralChunk' )
local AttrRefChunk = require( 'lst.AttrRefChunk' )

local function eval(self)
    local result = {}

    for i,chunk in ipairs(self.__chunks) do
        result[i] = tostring(chunk)
    end

    return table_concat(result)
end

local function st_tostring(self)
    return eval(self)
end

local function eq(st1, st2)
    if st1.__auto_indent ~= st2.__auto_indent then
        return false
    end

    if st1.__scanner ~= st2.__scanner then
        return false
    end

    for i,v in ipairs(st1.__chunks) do
        if v ~= st2.__chunks[i] then
            return false
        end
    end

    return true
end

local mt = {
    __tostring = st_tostring,
    __eq = eq,
}

local function isA(self, class)
    return _M == class
end

local function processChunks(chunks, st)
    for i,chunk in ipairs(chunks) do
        chunk:setEnclosingTemplate(st)

        --[[
        --  This really should be part of the parser, but I can't
        --  think of an elegant way to do it.  Any AttrRefChunk that 
        --  is preceeded by a LiteralChunk which is all whitespace, should
        --  have that LiteralChunk passed as its indent.
        --]]
        if chunk:isA(AttrRefChunk) and i > 1 then
            local pc = chunks[i-1]
            if pc:isA(LiteralChunk) and pc.isAllWs then
                chunk:setIndentChunk(pc)
            end
        end
    end
end

local function setEnclosingGroup(self, group)
    self.__enclosing_group = group
end

local function getEnclosingGroup(self)
    return self.__enclosing_group
end

function __call(self, templateText, options)
    local chunks, scanner_type, auto_indent
    local st = {}
    setmetatable(st, mt)

    if options then
        scanner_type = options.scanner
        auto_indent = options.auto_indent 
    else
        auto_indent = true
    end

    if templateText then
        local parser = STParser(scanner_type)
        chunks = parser:parse(templateText)
        if chunks == nil then
            error('Failed to parse template', 2)
        end

        processChunks(chunks, st)
    else
        chunks = nil
    end

    st.__chunks = chunks
    st.__auto_indent = auto_indent
    st.__scanner = scanner_type

    st.tostring = st_tostring
    st.getEnclosingGroup = getEnclosingGroup
    st.setEnclosingGroup = setEnclosingGroup
    st.isA = isA

    return st;
end

_M['ANGLE_BRACKET_SCANNER'] = STParser.ANGLE_BRACKET_SCANNER
_M['DOLLAR_SCANNER'] = STParser.DOLLAR_SCANNER

setmetatable(_M, _M)

