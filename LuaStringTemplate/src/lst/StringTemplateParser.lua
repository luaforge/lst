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
local tostring = tostring
local print = print

module( 'lst.StringTemplateParser' )

local lpeg = require( 'lpeg' ) 
local LiteralChunk = require( 'lst.LiteralChunk' )
local NewlineChunk = require( 'lst.NewlineChunk' )
local AttrRefChunk = require( 'lst.AttrRefChunk' )

--
-- The following functions are used in the grammar, and hence need
-- to be defined before the grammar
--
local function newLiteral(text)
    return LiteralChunk(text)
end

local function newNewline()
    return NewlineChunk()
end

local function newAttrRefAction(attribute, separator)
    -- print('attr: ' .. tostring(attribute), 'sep: ' .. tostring(separator))
    return AttrRefChunk(attribute, separator)
end

local scanner = {
    N = lpeg.R'09',
    AZ = lpeg.R('__','az','AZ','\127\255'),
    NEWLINE = lpeg.S'\n\r',
    SPACE = lpeg.S' \t',
    SEMI = lpeg.S';',
    COMMA = lpeg.S',',
    SEPARATOR = lpeg.P'separator',
    EQUALS = lpeg.P'=',
    DQUOTE = lpeg.S'"',
    NULL = lpeg.P'null'
}

local escapes = {
    ['\\$'] = '$'
}

-- Predeclare the non-terminals
local Chunk, 
      Newline, 
      Literal, 
      Action, 
      ActionStart, 
      ActionEnd, 
      Escape,
      AttrRef,
      AttrSep,
      AttrRefAction
      = 
      lpeg.V'Chunk', 
      lpeg.V'Newline', 
      lpeg.V'Literal', 
      lpeg.V'Action', 
      lpeg.V'ActionStart', 
      lpeg.V'ActionEnd', 
      lpeg.V'Escape',
      lpeg.V'AttrRef',
      lpeg.V'AttrSep',
      lpeg.V'AttrRefAction'

local grammar = {
    "Template",
    Template = lpeg.Ct(Chunk^1) * -1,
    Chunk = Literal + Action + Newline,
    Newline = lpeg.C(scanner.NEWLINE) / newNewline,
    Escape = (lpeg.P'\\' * lpeg.S[[$]]) / escapes,
    ActionStart = lpeg.P'$' - lpeg.P'\\',
    ActionEnd = lpeg.P'$',
    AttrRef = lpeg.C((1 - (ActionEnd + scanner.SEMI))^1),
    AttrSep = scanner.SEMI * 
                scanner.SPACE *
                ((scanner.NULL *
                 scanner.EQUALS *
                 scanner.DQUOTE *
                 (1 - scanner.DQUOTE)^0 *
                 scanner.DQUOTE *
                 scanner.COMMA *
                 scanner.SPACE^0)^-1) *
                scanner.SEPARATOR * 
                scanner.EQUALS *
                scanner.DQUOTE *
                lpeg.C((1 - scanner.DQUOTE)^0) *
                scanner.DQUOTE,
    AttrRefAction = ActionStart * 
                        (AttrRef * AttrSep^-1 / newAttrRefAction) * 
                        ActionEnd,
    Action = AttrRefAction,
    Literal = lpeg.Cs(((Escape + 1) - (ActionStart + Newline))^1) / newLiteral
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

