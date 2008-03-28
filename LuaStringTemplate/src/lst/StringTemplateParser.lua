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

    LPeg parser for a string template.  Returns an array of text, expression,
    and embedded template chunks.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local error = error

module( 'lst.StringTemplateParser' )

local lpeg = require('lpeg') 

local scanner = {
    N = lpeg.R'09',
    AZ = lpeg.R('__','az','AZ','\127\255'),
    NEWLINE = lpeg.S'\n\r',
    SPACE = lpeg.S' \t',
}

local escapes = {
    ['\\$'] = '$'
}

--[[
--  Simplistic PEG that partially describes a StringTemplate
--
--  Template    <- Chunk+ End
--  End         <- !. 
--  Chunk       <- Literal / Action / Newline
--  Newline     <- '\n' / '\r'
--  Action      <- ActionStart (!ActionEnd .)+ ActionEnd
--  ActionStart <- !'\\' '$'
--  ActionEnd   <- '$'
--  Literal     <- ((!Action / !Newline) .)+
--]]
local Chunk, Newline, Literal, Action, ActionStart, ActionEnd, Escape = 
    lpeg.V'Chunk', lpeg.V'Newline', lpeg.V'Literal', lpeg.V'Action', lpeg.V'ActionStart', 
    lpeg.V'ActionEnd', lpeg.V'Escape'

local grammar = {
    "Template",
    Template = lpeg.Ct(Chunk^1) * -1,
    Chunk = Literal + Action + Newline,
    Newline = lpeg.C(scanner.NEWLINE),
    Escape = (lpeg.P'\\' * lpeg.S[[$]]) / escapes,
    ActionStart = lpeg.P'$' - lpeg.P'\\',
    ActionEnd = lpeg.P'$',
    Action = ActionStart * lpeg.C((1 - ActionEnd)^1) * ActionEnd,
    Literal = lpeg.Cs(((Escape + 1) - (ActionStart + Newline))^1)
}

--[[
--  Parses text into an array of text, expression, and embedded template 
--  chunks
--]]
local parse = function(self, text)
    if text == nil then
        error('text cannot be nil')
    end

    local chunks
    if text ~= '' then
        -- local p = lpeg.P(grammar) * -1
        local p = lpeg.P(grammar)
        chunks = lpeg.match(p, text)
    else
        chunks = {}
    end

    return chunks
end

function __call(self, ...)
    local parser = {}

    parser.parse = parse

    return parser;
end

setmetatable(_M, _M)

