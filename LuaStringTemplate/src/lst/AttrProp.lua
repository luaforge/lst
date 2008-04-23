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
    
    This module is responsible for getting an attribute value, including the
    (possibly indirect) property from a given context.  This isn't a class, its
    a set of helper functions used by other classes.

--]]

local module = module
local require = require
local string_match = string.match
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local getmetatable = getmetatable
local assert = assert
local print = print
local tostring = tostring

module( 'lst.AttrProp' )

local function getRawValue(context, attribute, property)
    local v = context[attribute]

    if v ~= nil and property then
        for w in string_gmatch(property, "[%w_]+") do
            v = v[w]
            if not v then break end
        end
    end

    --v = v or ''

    return v
end

function getValue(context, attribute, property)
    assert(context)
    assert(attribute)
    property = property or ''

    -- If attribute has a period (.), split it up into its consituent 
    -- attribute and property parts as a convenience for the caller
    if property == '' and string_match(attribute, '([%w_]+)[%.](.*)') then
        local ignore
        attribute, property = string_match(attribute, '([%w_]+)[%.](.*)')
    end

    if string_match(property, '%(.+%)') then
        -- indirect property lookup
        local indirect = string_gsub(property, '%((.+)%)', "%1")
        local attr, ignore, prop = string_match(indirect, '([%w_]+)[%.]?(.*)')
        property = getRawValue(context, attr, prop)
    end

    local v = getRawValue(context, attribute, property)

    if v == nil then
        -- is there a map that we can use?
        -- print('looking for map ' .. attribute .. ' in enclosing group')

        if context._getEnclosingGroup then
            local stg = context:_getEnclosingGroup()
            if stg then
                local map = stg.maps[attribute]

                if map then
                    -- print('found map, looking for key ' .. property)
                    local template = map[property]
                    if template then
                        -- print('found template, render it')
                        template:_setEnclosingTemplate(et)

                        local tmt = getmetatable(template)
                        local oldIndex = tmt.__index
                        tmt.__index = et

                        local etIndent = et:_createIndentString()
                        if etIndent ~= nil then
                            template:_pushIndent(etIndent)
                        end

                        if self.indentChunk ~= nil then
                            template:_pushIndent(self.indentChunk)
                        end

                        v = tostring(template)
                        --print('v = \'' .. v .. '\'')

                        if self.indentChunk then
                            template:_popIndent()
                        end

                        if etIndent then
                            template:_popIndent()
                        end

                        tmt.__indent = oldIndex
                        template:_setEnclosingTemplate(nil)
                    end
                end
            end
        end
    end

    v = v or ''

    return v
end


