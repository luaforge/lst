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

module( 'lst.TemplateRefChunk' )

local function trc_tostring(chunk)
    return chunk:eval()
end

local function eq(chunk1, chunk2)
    if chunk1.template ~= chunk2.template then
        return false
    end

    for k,v1 in pairs(chunk1.params) do
        local v2 = chunk2.params[k]
        if v1 ~= v2 then
            return false
        end
    end

    return true
end

local mt = {
    __tostring = trc_tostring,
    __eq = eq
}

local function eval(self)
    local et = assert(self:getEnclosingTemplate(), 
                        "enclosing template can't be nil")

    local stg = et:getEnclosingGroup()
    if stg == nil then
        -- This is effectively an error, but not enough to kill the process
        return ''
    end

    local template = stg:getInstanceOf(self.template)
    local result

    if template then
        -- Setup the template
        
        local oldParams = {}
        for k,v in pairs(self.params) do
            oldParams[k] = template[k]
            template[k] = et[v]
        end

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

        for k,_ in pairs(self.params) do
            template[k] = oldParams[k]
        end

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

function __call(self, template, params)
    local trc = {}
    setmetatable(trc, mt)

    trc.template = template
    trc.params = params or {}

    trc.eval = eval
    trc.setEnclosingTemplate = setEnclosingTemplate
    trc.getEnclosingTemplate = getEnclosingTemplate
    trc.isA = isA
    trc.setIndentChunk = setIndentChunk

    return trc
end

setmetatable(_M, _M)

