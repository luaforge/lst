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

    LPeg parser for group files. 

--]]

local module = module
local require = require
local setmetatable = setmetatable
local print = print
local type = type

module( 'lst.StringTemplateGroupParser' )

local lpeg = require( 'lpeg' )
local StringTemplateParser = require( 'lst.StringTemplateParser' )
local GroupMetaData = require( 'lst.GroupMetaData' )
local StringTemplate = require( 'lst.StringTemplate' )
local GroupTemplate = require( 'lst.GroupTemplate' )

local P, S, R, V, C, Cs, Ct = lpeg.P, lpeg.S, lpeg.R, lpeg.V, lpeg.C, lpeg.Cs, lpeg.Ct

local function newMetaData(name, parent, implements)
    -- Epsilon case
    if type(implements) == 'string' then
        implements = {}
    end

    gmd = GroupMetaData(name, parent, implements)

    return gmd
end

local STOpts = { scanner = StringTemplate.ANGLE_BRACKET_SCANNER }

local function newGroupTemplate(name, arguments, st_text)
    if type(arguments) == 'string' then
        arguments = {}
    end

    local gt = GroupTemplate(name, arguments, StringTemplate(st_text, STOpts))

    return gt
end

-- Table of terminals (scanner)
local s = {
    N = R'09',
    AZ = R('__','az','AZ','\127\255'),
    NEWLINE = S'\n\r',
    SPACE = S' \t',
    WS = S' \t\n\r',
    SEMI = S';',
    COMMA = S',',
    PERIOD = S'.',
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
    LPAREN = P'(',
    RPAREN = P')',
    TMPL_ASSIGN = P'::=',
    ML_TMPL_START = P'<<',
    ML_TMPL_END = P'>>'
}

-- Predeclare the non-terminals
local Group,
      MetaData,
      GroupName,
      GroupParent,
      GroupImplements,
      InterfaceName,
      GroupTemplates,
      GroupTemplate,
      ParamList,
      NameList,
      Name,
      SingleLineTemplate,
      MultiLineTemplate,
      Map
      =
      V'Group',
      V'MetaData',
      V'GroupName',
      V'GroupParent',
      V'GroupImplements',
      V'InterfaceName',
      V'GroupTemplates',
      V'GroupTemplate',
      V'ParamList',
      V'NameList',
      V'Name',
      V'SingleLineTemplate',
      V'MultiLineTemplate',
      V'Map'

local grammar = {
    "Group",

    Group = Ct(MetaData * GroupTemplates) * s.WS^0 * -1,

    MetaData = s.WS^0 * P'group' * s.SPACE^1 * 
                (GroupName * GroupParent * GroupImplements/ newMetaData) * 
                s.SEMI * s.WS^0,

    GroupName = C((1 - (s.WS + s.SEMI))^1),

    GroupParent = s.WS^1 * P':' * s.WS^1 * 
                    C((1 - (s.WS + s.SEMI))^1) + 
                  C(s.EPSILON),

    GroupImplements = s.WS^1 * P'implements' * s.WS^1 *
                        Ct(InterfaceName * (s.COMMA * s.WS^0 * InterfaceName)^0) *
                        s.WS^0 +
                      C(s.EPSILON),

    InterfaceName = C((1 - (s.WS + s.SEMI + s.COMMA))^1),

    GroupTemplates = Ct(GroupTemplate * (s.WS^0 * GroupTemplate)^0) + C(s.EPSILON),

    GroupTemplate = (C((1 - s.LPAREN)^1) * 
                        s.LPAREN * s.WS^0 * ParamList * s.RPAREN *
                        s.WS^0 * s.TMPL_ASSIGN * s.WS^0 *
                        (SingleLineTemplate + MultiLineTemplate)) / newGroupTemplate,

    ParamList = Ct(NameList) + C(s.EPSILON),

    NameList = Name * (s.COMMA * Name)^0,

    Name = C(s.AZ * (s.AZ + s.N)^0),

    SingleLineTemplate = s.DQUOTE * C((1 - (s.DQUOTE + s.NEWLINE))^0) * s.DQUOTE,

    MultiLineTemplate = s.ML_TMPL_START * s.NEWLINE^-1 *
                            C((1 - (s.ML_TMPL_END + (s.NEWLINE * s.ML_TMPL_END)))^0) *
                            s.NEWLINE^-1 * s.ML_TMPL_END,
}

local parse = function(self, text)
    if text == nil then
        error('group text cannot be nil')
    end

    local result
    if text ~= '' then
        if self.scanner_type == ANGLE_BRACKET_SCANNER then
            grammar.ExprStart = s.EXPR_START_BRACKET
            grammar.ExprEnd = s.EXPR_END_BRACKET
        else 
            grammar.ExprStart = s.EXPR_START_DOLLAR
            grammar.ExprEnd = s.EXPR_END_DOLLAR
        end

        local p = P(grammar)
        result = lpeg.match(p, text)
    else
        result = {}
    end

    return result
end

function __call(self, scanner_type)
    local parser = {}

    parser.parse = parse
    parser.scanner_type = scanner_type or DOLLAR_SCANNER

    if not (parser.scanner_type == DOLLAR_SCANNER or 
            parser.scanner_type == ANGLE_BRACKET_SCANNER) then
        error('Unknown scanner type ' .. scanner_type)
    end

    return parser;
end

_M['ANGLE_BRACKET_SCANNER'] = StringTemplateParser.ANGLE_BRACKET_SCANNER
_M['DOLLAR_SCANNER'] = StringTemplateParser.DOLLAR_SCANNER

setmetatable(_M, _M)

