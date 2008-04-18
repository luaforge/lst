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

    An IfChunk implements the <if(a)> ... <endif> expression.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local getmetatable = getmetatable
local tostring = tostring
local string_gmatch = string.gmatch
local string_match = string.match
local string_gsub = string.gsub
local print = print
local ipairs = ipairs
local table_concat = table.concat
local assert = assert

module( 'lst.IfChunk' )

local function ifc_tostring(chunk)
    return chunk:eval()
end

local function eq(chunk1, chunk2)
    if chunk1.attribute ~= chunk2.attribute then
        return false
    end

    if chunk1.property ~= chunk2.property then
        return false
    end

    for i,c1 in ipairs(chunk1.ifBodyChunks) do
        c2 = chunk2.ifBodyChunks[i]
        if c1 ~= c2 then
            return false
        end
    end

    for i,e1 in ipairs(chunk1.elseBodyChunks) do
        e2 = chunk2.elseBodyChunks[i]
        if e1 ~= e2 then
            return false
        end
    end

    return true
end

local mt = {
    __tostring = ifc_tostring,
    __eq = eq
}

local function getRawValue(self, context, attribute, property)
    local v = context[attribute]

    if v ~= nil and property then
        for w in string_gmatch(property, "[%w_]+") do
            v = v[w]
            if not v then break end
        end
    end

    return v
end

local function getField(self)
    local attribute = self.attribute
    local property = self.property
    local et = self:getEnclosingTemplate()

    if string_match(property, '%(.+%)') then
        -- indirect property lookup
        local indirect = string_gsub(property, '%((.+)%)', "%1")
        local attr, ignore, prop = string_match(indirect, '([%w_]+)[%.]?(.*)')
        property = getRawValue(self, 
                               self:getEnclosingTemplate(), 
                               attr,
                               prop)

        if property == nil then
            -- indirect property lookup failed, fails the expression
            return self.negate
        end
    end

    local v = getRawValue(self,
                          self:getEnclosingTemplate(),
                          attribute,
                          property)

    local result = (v ~= nil)
    if self.negate then
        result = not result
    end 

    return result
end

local function evalChunks(self, chunks)
    local strings = {}
    local indent

    if self.indentChunk then
        indent = tostring(self.indentChunk)
    end

    for _,chunk in ipairs(chunks) do
        strings[#strings + 1] = tostring(chunk)
        if chunk:_isA(NewlineChunk) and indent ~= nil then
            strings[#strings + 1] = indent
        end
    end

    return table_concat(strings)
end

local function eval(self)
    local foundIt = getField(self)
    local result

    if foundIt then
        if self.ifBodyChunks then
            result = evalChunks(self, self.ifBodyChunks)
        else
            result = ''
        end
    else
        if self.elseBodyChunks then
            result = evalChunks(self, self.elseBodyChunks)
        else
            result = ''
        end
    end

    return result
end

local function isA(self, class)
    return _M == class
end

local function setEnclosingTemplate(self, template)
    self.enclosingTemplate = template

    if self.ifBodyChunks then
        for _,c in ipairs(self.ifBodyChunks) do
            c:setEnclosingTemplate(template)
        end
    end

    if self.elseBodyChunks then
        for _,c in ipairs(self.elseBodyChunks) do
            c:setEnclosingTemplate(template)
        end
    end
end

local function getEnclosingTemplate(self)
    return self.enclosingTemplate
end

local function setIndentChunk(self, chunk)
    self.indentChunk = chunk
end

function __call(self, attribute, property, ifBodyChunks, elseBodyChunks)
    local ifc = setmetatable({}, { __tostring = ifc_tostring, __eq = eq})

    if string_match(attribute, '!.+') then
        ifc.attribute = string_gsub(attribute, '!(.+)', '%1')
        ifc.negate = true
    else
        ifc.attribute = attribute
        ifc.negate = false
    end

    elseBodyChunks = elseBodyChunks or {}

    ifc.property = property
    ifc.ifBodyChunks = ifBodyChunks
    ifc.elseBodyChunks = elseBodyChunks

    ifc.eval = eval
    ifc.setEnclosingTemplate = setEnclosingTemplate
    ifc.getEnclosingTemplate = getEnclosingTemplate
    ifc._isA = isA
    ifc.setIndentChunk = setIndentChunk

    return ifc
end

setmetatable(_M, _M)

