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

    An AttrRefChunk does a lookup in the enclosing StringTemplate context
    for a named attribute and returns that value.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local tostring = tostring
local string_gmatch = string.gmatch
local string_match = string.match
local string_gsub = string.gsub
local string_sub = string.sub
local string_find = string.find
local type = type
local table_concat = table.concat
local print = print
local pairs = pairs
local error = error

module( 'lst.AttrRefChunk' )

local function arc_tostring(chunk)
    return chunk:eval()
end

local function eq(chunk1, chunk2)
    return chunk1.attribute == chunk2.attribute
end

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
                               self.enclosingTemplate, 
                               attr,
                               prop)
    end

    local v = getRawValue(self,
                          self.enclosingTemplate,
                          attribute,
                          property)

    v = v or ''
    local sep = self.options['separator']

    if type(v) == "table" then
        return table_concat(v, sep)
    else
        return tostring(v)
    end
end

local mt = {
    __tostring = arc_tostring,
    __eq = eq
}

local function eval(self)
    local attr = self.attribute

    if self.enclosingTemplate then
        return getField(self)
    else
        return ''
    end
end

local function setEnclosingTemplate(self, template)
    self.enclosingTemplate = template
end

function __call(self, attribute, property, options)
    local ac = {}
    setmetatable(ac, mt)
    
    ac.attribute = attribute
    ac.property = property
    ac.options = options or {}
    ac.eval = eval
    ac.setEnclosingTemplate = setEnclosingTemplate

    if type(ac.options) ~= 'table' then
        error('attribute ref options must be a table, no a ' .. type(options))
    end

    return ac
end

setmetatable(_M, _M)

