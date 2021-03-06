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

    A GroupTemplate object holds a named instance of a StringTemplate object,
    including its name and a list of formal arguments.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local ipairs = ipairs
local print = print

module( 'lst.GroupTemplate' )

local function eq(gt1, gt2)
    if gt1.name ~= gt2.name then
        return false
    end

    if gt1.arguments and gt2.argements then
        for i,v1 in ipairs(gt1.arguments) do
            local v2 = gt2.arguments[i]
            if v1 ~= v2 then
                return false
            end
        end
    end

    if gt1.st ~= gt2.st then
        return false 
    end

    return true
end

local mt = {
    __eq = eq
}

local function setEnclosingGroup(self, group)
    self.st:_setEnclosingGroup(group)
end

local function getEnclosingGroup(self)
    return self.st:_getEnclosingGroup()
end

local function isA(self, class)
    return _M == class
end

function __call(self, name, arguments, st)
    local gt = setmetatable({}, mt)

    gt.name = name
    gt.arguments = arguments
    gt.st = st

    gt.getEnclosingGroup = getEnclosingGroup
    gt.setEnclosingGroup = setEnclosingGroup
    gt._isA = isA

    return gt
end

setmetatable(_M, _M)

