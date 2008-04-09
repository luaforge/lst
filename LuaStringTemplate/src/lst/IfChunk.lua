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
local pairs = pairs
local error = error
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

    if chunk1.ifBody ~= chunk2.ifBody then
        return false
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

    v = v or ''

    return v
end

local function getField(self)
    local attribute = self.attribute
    local property = self.property

    if string_match(property, '%(.+%)') then
        -- indirect property lookup
        local indirect = string_gsub(property, '%((.+)%)', "%1")
        local attr, ignore, prop = string_match(indirect, '([%w_]+)[%.]?(.*)')
        property = getRawValue(self, 
                               self:getEnclosingTemplate(), 
                               attr,
                               prop)
    end

    local v = getRawValue(self,
                          self:getEnclosingTemplate(),
                          attribute,
                          property)

    return v ~= nil
end

local function eval(self)
    local foundIt = getField(self)
    local result

    if foundIt then
        if self.ifBody then
            local et = assert(self:getEnclosingTemplate(), 
            "enclosing template can't be nil")

            local template = self.ifBody

            -- Setup the template
            local tmt = getmetatable(template)
            local oldIndex = tmt.__index
            tmt.__index = et

            local etIndent = et:createIndentString()
            if etIndent ~= nil then
                template:pushIndent(etIndent)
            end

            if self.indentChunk ~= nil then
                template:pushIndent(self.indentChunk)
            end

            -- Generate the string

            result = tostring(template)

            -- Restore the template

            if self.indentChunk then
                template:popIndent()
            end

            if etIndent ~= nil then
                template:popIndent()
            end

            tmt.__index = oldIndex
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
    self.ifBody:setEnclosingTemplate(template)
end

local function getEnclosingTemplate(self)
    return self.enclosingTemplate
end

local function setIndentChunk(self, chunk)
    self.indentChunk = chunk
end

function __call(self, attribute, property, ifBody)
    local ifc = {}
    setmetatable(ifc, mt)

    ifc.attribute = attribute
    ifc.property = property
    ifc.ifBody = ifBody

    ifc.eval = eval
    ifc.setEnclosingTemplate = setEnclosingTemplate
    ifc.getEnclosingTemplate = getEnclosingTemplate
    ifc.isA = isA
    ifc.setIndentChunk = setIndentChunk

    return ifc
end

setmetatable(_M, _M)

