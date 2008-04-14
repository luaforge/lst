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

    A NewlineChunk represents a \n character in a template.  Since this is 
    such a common element there isn't any point in creating a new one every
    time we encounter a newline.  The constructor object will return the same
    NewlineChunk object every time.

--]]

local module = module
local require = require
local setmetatable = setmetatable

module( 'lst.NewlineChunk' )

local nl = {}

local function tostring(chunk)
    return '\n'
end

local function eq(chunk1, chunk2)
    return true
end

local mt = {
    __tostring = tostring,
    __eq = eq
}

local function setEnclosingTemplate(self, template)
    self.enclosingTemplate = template
end

local function isA(self, class)
    return _M == class
end

local function setIndentChunk(self, chunk)
    -- ignored
end

-- This is effectively a Singleton Flyweight
nl.text = '\n'
nl.setEnclosingTemplate = setEnclosingTemplate
nl._isA = isA
nl.setIndentChunk = setIndentChunk
setmetatable(nl, mt)

function __call(self)
    return nl
end

setmetatable(_M, _M)
