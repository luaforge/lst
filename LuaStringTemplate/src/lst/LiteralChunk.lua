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

    A LiteralChunk is exactly that: a block of literal text (a string) to 
    be returned via tostring() or written to a stream via a call to write(stream).

--]]

local module = module
local require = require
local setmetatable = setmetatable
local string_match = string.match

module( 'lst.LiteralChunk' )

local function tostring(chunk)
    return chunk.text
end

local function eq(chunk1, chunk2)
    return chunk1.text == chunk2.text
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
    self.indentChunk = chunk
end

function __call(self, text)
    local lc = {}
    setmetatable(lc, mt)
    
    lc.text = text
    if string_match(text, '^[%s]+$') then
        lc.isAllWs = true
    else
        lc.isAllWs = false
    end

    lc.setEnclosingTemplate = setEnclosingTemplate
    lc.isA = isA
    lc.setIndentChunk = setIndentChunk

    return lc
end

setmetatable(_M, _M)

