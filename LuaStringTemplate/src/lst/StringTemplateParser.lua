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
local pairs = pairs
local ipairs = ipairs
local type = type
local table_concat = table.concat

module( 'lst.StringTemplateParser' )

local lpeg = require( 'lpeg' ) 
local LiteralChunk = require( 'lst.LiteralChunk' )
local NewlineChunk = require( 'lst.NewlineChunk' )
local AttrRefChunk = require( 'lst.AttrRefChunk' )
local EscapeChunk = require( 'lst.EscapeChunk' )
local TemplateRefChunk = require( 'lst.TemplateRefChunk' )
local StringTemplate = require( 'lst.StringTemplate' )
local IfChunk = require( 'lst.IfChunk' )

local P, S, R, V, C, Cs, Ct, Carg = lpeg.P, lpeg.S, lpeg.R, lpeg.V, lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Carg

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

local function newAttrRefExpr(attribute, property, options)
    local opts = {}
    if type(options) == "table" then
        for i,v in ipairs(options) do
            opts[v[1]] = v[2]
        end
    end

    return AttrRefChunk(attribute, property, opts)
end

local function newEscapeExpr(escapes)
    local escStr = table_concat(escapes)
    return EscapeChunk(escStr)
end

local function newTemplateRef(template, params)
    --print('template:', template, 'params:', params)
    local actual_params = {}

    if type(params) == 'table' then
        for i=1, #params, 2 do
            --print('param', 'name:', params[i], 'value:', params[i+1])
            actual_params[params[i]] = params[i+1]
        end
    end

    return TemplateRefChunk(template, actual_params)
end

local function newIf(attribute, property, templateText, scanner, auto_indent)
    --print('creating new ifChunk')
    local opts = { scanner = scanner, auto_indent = auto_indent }
    local ifBody = StringTemplate(templateText, opts)

    return IfChunk(attribute, property, ifBody)
end

-- Grammar terminals
local s = {
    N = R'09',
    AZ = R('__','az','AZ','\127\255'),
    NEWLINE = S'\n\r',
    SPACE = S' \t',
    WS = S' \t\n\r',
    SEMI = S';',
    COMMA = S',',
    PERIOD = S'.',
    SEPARATOR = P'separator',
    EQUALS = P'=',
    DQUOTE = S'"',
    NULL = P'null',
    EPSILON = P(true),
    ESCAPE = S'\\',
    BANG = P'!',
    EXPR_START_DOLLAR = P'$' - S'\\',
    EXPR_END_DOLLAR = P'$',
    EXPR_START_BRACKET = P'<' - S'\\',
    EXPR_END_BRACKET = P'>',
    LBRACE = P'(',
    RBRACE = P')',
    IF = P'if',
    ENDIF = P'endif'
}

local literalEscapes = {
    ['\\$'] = '$',
    ['\\<'] = '<',
}

local exprEscapes = {
    ['\\n'] = '\n',
    ['\\r'] = '\r',
    ['\\ '] = ' ',
    ['\\t'] = '\t'
}

-- Predeclare the non-terminals
local Template,
      Chunk, 
      Newline, 
      Literal, 
      Expr, 
      ExprStart, 
      ExprEnd, 
      LiteralEscape,
      AttrRef,
      AttrProp,
      AttrOpts,
      AttrOpt,
      AttrRefExpr,
      CommentExpr,
      EscapeExpr,
      TemplateRef,
      TemplateParamList,
      TemplateParam,
      Name,
      TemplateRefExpr,
      IfExpr
      = 
      V'Template',
      V'Chunk', 
      V'Newline', 
      V'Literal', 
      V'Expr', 
      V'ExprStart', 
      V'ExprEnd', 
      V'LiteralEscape',
      V'AttrRef',
      V'AttrProp',
      V'AttrOpts',
      V'AttrOpt',
      V'AttrRefExpr',
      V'CommentExpr',
      V'EscapeExpr',
      V'TemplateRef',
      V'TemplateParamList',
      V'TemplateParam',
      V'Name',
      V'TemplateRefExpr',
      V'IfExpr'

local grammar = {
    "Template",

    Template = Ct(Chunk^1) * -1,

    Chunk = Literal + Expr + Newline,

    Newline = C(s.NEWLINE) / newNewline,

    LiteralEscape = (s.ESCAPE * S'$<') / literalEscapes,

    AttrRef = -(s.BANG + s.ESCAPE) * C((1 - (ExprEnd + s.SEMI + s.PERIOD))^1),

    AttrProp = (s.PERIOD * C((1 - (ExprEnd + s.SEMI))^1)) +
               C(s.EPSILON),

    AttrOpts = (s.SEMI * s.SPACE^0 * 
                    Ct(AttrOpt * (s.COMMA * s.SPACE^0 * AttrOpt)^0)) +
               C(s.EPSILON),  -- ensures we always get something for the options

    AttrOpt = Ct(C((1 - (s.EQUALS + s.COMMA))^1) * s.EQUALS * s.DQUOTE *
                Cs(((((s.ESCAPE * S'ntr ')/exprEscapes) + 1) - s.DQUOTE)^0) 
                * s.DQUOTE) +
              Ct(C((1 - (s.COMMA + s.SPACE + ExprEnd))^1) * C(s.EPSILON)),

    AttrRefExpr = ExprStart * 
                    (AttrRef * AttrProp * AttrOpts / newAttrRefExpr) * 
                    ExprEnd,

    CommentExpr = ExprStart * s.BANG * (1 - s.BANG)^0 * s.BANG * ExprEnd,

    EscapeExpr = ExprStart * 
                    Ct(Cs(((s.ESCAPE * S'ntr ') / exprEscapes))^1) / newEscapeExpr * 
                    ExprEnd,

    TemplateRef = C((1 - s.LBRACE)^1),

    TemplateParamList = TemplateParam * (s.WS^0 * s.COMMA * s.WS^0 * TemplateParam)^0,

    TemplateParam = Name * s.WS^0 * s.EQUALS * s.WS^0 * Name,

    Name = C(s.AZ * (s.AZ + s.N)^0),

    TemplateRefExpr = ExprStart * (TemplateRef * 
                        s.LBRACE * s.WS^0 *
                        (Ct(TemplateParamList) + s.EPSILON) * s.WS^0 *
                        s.RBRACE) / newTemplateRef *
                        ExprEnd,

    Expr = IfExpr + EscapeExpr + CommentExpr + TemplateRefExpr + AttrRefExpr,

    Literal = Cs(((LiteralEscape + 1) - (ExprStart + Newline))^1) / newLiteral,

    -- Because we are creating an anonymous embedded template, we need to 
    -- pass in options (scanner and auto_indent) that the template cares about
    IfExpr = (ExprStart * s.IF * s.LBRACE * 
                C((1 - (s.PERIOD + s.RBRACE))^1) *
                ((s.PERIOD * (C((1 - s.RBRACE)^1))) + C(s.EPSILON)) *
                s.RBRACE * ExprEnd * 
                s.NEWLINE^0 * C((1 - ExprStart)^0) * s.NEWLINE^0 * 
                ExprStart * s.ENDIF * ExprEnd *
                Carg(1) * Carg(2)) / newIf,
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

        if self.scanner_type == ANGLE_BRACKET_SCANNER then
            grammar.ExprStart = s.EXPR_START_BRACKET
            grammar.ExprEnd = s.EXPR_END_BRACKET
        else 
            grammar.ExprStart = s.EXPR_START_DOLLAR
            grammar.ExprEnd = s.EXPR_END_DOLLAR
        end

        local p = P(grammar)
        chunks = lpeg.match(p, text, 1, self.scanner, self.auto_indent)
    else
        chunks = {}
    end

    return chunks
end

function __call(self, scanner_type, auto_indent) 
    local parser = {}

    parser.parse = parse
    parser.scanner_type = scanner_type or DOLLAR_SCANNER
    parser.auto_indent = auto_indent or true

    if not (parser.scanner_type == DOLLAR_SCANNER or 
            parser.scanner_type == ANGLE_BRACKET_SCANNER) then
        error('Unknown scanner type ' .. scanner_type)
    end

    return parser;
end

_M['ANGLE_BRACKET_SCANNER'] = 1
_M['DOLLAR_SCANNER'] = 2

setmetatable(_M, _M)


