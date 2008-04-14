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

    A GroupMap object holds named instances of StringTemplate objects in a table.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local ipairs = ipairs
local print = print
local pairs = pairs

module( 'lst.GroupMap' )

local function eq(gm1, gm2)
    if gm1.name ~= gm2.name then
        return false
    end

    for k,v1 in pairs(gm1) do
        if k ~= 'name' then
            v2 = gm2[k]
            if v1 ~= v2 then
                return false
            end
        end
    end

    return true
end

local mt = {
    __eq = eq
}

local function isA(self, class)
    return _M == class
end

local function setEnclosingGroup(self, group)
    self.enclosing_group = group
end

local function getEnclosingGroup(self)
    return self.enclosing_group
end

function __call(self, name, mapping)
    gm = {}
    setmetatable(gm, mt)

    gm.name = name
    for _,m in ipairs(mapping) do
        gm[m[1]] = m[2]
    end

    gm._isA = isA
    gm.setEnclosingGroup = setEnclosingGroup
    gm.getEnclosingGroup = getEnclosingGroup

    return gm
end

setmetatable(_M, _M)

