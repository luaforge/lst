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

    A TemplateRefChunk calls a template in an enclosing template group.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local tostring = tostring
local print = print
local assert = assert
local type = type
local table_concat = table.concat
local ipairs = ipairs
local error = error
local select = select

module( 'lst.TemplateRefChunk' )

local AttrProp = require( 'lst.AttrProp' )

local function trc_tostring(chunk)
    return chunk:eval()
end

local function eq(chunk1, chunk2)
    if chunk1.template ~= chunk2.template then
        return false
    end

    for i,kvp in ipairs(chunk1.params) do
        kvp2 = chunk2.params[i]

        if kvp.key ~= kvp2.key then
            return false
        end

        if kvp.valueKey ~= kvp2.valueKey then
            return false
        end
    end

    return true
end

local mt = {
    __tostring = trc_tostring,
    __eq = eq
}

local function genCrossProduct(template, results, multiVals, valStack, mvIndex)
    local valStack = valStack or {}
    local mvIndex = mvIndex or 1

    if multiVals[mvIndex] == nil then
        -- We have all of the values in the stack necessary to execute the
        -- template
        for _,kvp in ipairs(valStack) do
            template[kvp.key] = kvp.value
        end

        results[#results + 1] = tostring(template)

        return
    end

    local mv = multiVals[mvIndex]
    for _,v in ipairs(mv.values) do
        valStack[#valStack + 1] = { key = mv.key, value = v }
        genCrossProduct(template, results, multiVals, valStack, mvIndex + 1)
        valStack[#valStack] = nil
    end
end


local function eval(self)
    local et = assert(self:getEnclosingTemplate(), 
                        "enclosing template can't be nil")

    local stg = et:_getEnclosingGroup()
    if stg == nil then
        -- This is effectively an error, but not enough to kill the process
        return ''
    end

    --print('trc: get instance of ' .. self.templateName)
    local template = stg:getInstanceOf(self.templateName)
    local result

    if template then
        --print('trc: - found instance, getting result(s)')
        local results = {}
        -- Setup the template
        
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

        -- This gets complicated, because multi-valued attributes should 
        -- result in calling the referenced template for each value.  If
        -- there are multiple multi-valued attributes, we get the cross-product.
        local oldParams = {}
        local multiValCount = 0
        local multiVals = {}
        local atLeastOne = false
        for _,kvp in ipairs(self.params) do
            oldParams[kvp.key] = template[kvp.key]

            local val = AttrProp.getValue(et, kvp.valueKey)

            if (type(val) == 'table') then
                atLeastOne = true
                if #val > 0 then
                    -- its an array, so this is a multi-valued attribute
                    multiValCount = multiValCount + 1
                    multiVals[#multiVals + 1] = {
                        key = kvp.key,
                        values = val,
                        index = 1
                    }
                else
                    -- This is really just another attribute
                    template[kvp.key] = val
                end
            elseif val ~= nil then
                atLeastOne = true
                template[kvp.key] = val
            end
        end

        if atLeastOne or #(self.params) == 0 then 
            -- Generate the string
            if multiValCount == 0 then
                results[#results + 1] = tostring(template)
            elseif multiValCount == 1 then
                mv = multiVals[1]
                for _,v in ipairs(mv.values) do
                    template[mv.key] = v
                    results[#results + 1] = tostring(template)
                end
            else
                genCrossProduct(template, results, multiVals)
                --error('multiple multi-valued attributes not yet supported')
            end
        end

        -- Restore the template

        for k,v in pairs(oldParams) do
            template[k] = v
        end

        if self.indentChunk then
            template:_popIndent()
        end

        if etIndent ~= nil then
            template:_popIndent()
        end

        tmt.__index = oldIndex

        result = table_concat(results)
    else
        result = ''
    end

    return result
end

local function isA(self, class)
    return _M == class
end

local function setEnclosingTemplate(self, template)
    self.enclosingTemplate = template
end

local function getEnclosingTemplate(self)
    return self.enclosingTemplate
end

local function setIndentChunk(self, chunk)
    self.indentChunk = chunk
end

local function clone(self)
    local c = __call(_M, self.templateName, self.params)
    if self.indentChunk then
        c.indentChunk = self.indentChunk:clone()
    end

    return c
end

function __call(self, templateName, params)
    local trc = setmetatable(
        {
            templateName = templateName,
            params = params or {},
            eval = eval,
            setEnclosingTemplate = setEnclosingTemplate,
            getEnclosingTemplate = getEnclosingTemplate,
            _isA = isA,
            setIndentChunk = setIndentChunk,
            clone = clone
        }, 
        {
            __tostring = trc_tostring, 
            __eq = eq 
        }
    )

    return trc
end

setmetatable(_M, _M)

