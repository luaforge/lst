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

    The implementation of the StringTemplateGroup class.

--]]

local module = module
local require = require
local setmetatable = setmetatable
local ipairs = ipairs
local table_concat = table.concat
local tostring = tostring
local error = error
local print = print
local io_open = io.open
local assert = assert
local select = select
local type = type

module( 'lst.StringTemplateGroup' )

local STGParser = require( 'lst.StringTemplateGroupParser' )
local StringTemplate = require( 'lst.StringTemplate' )

local function eq(stg1, stg2)
    return true
end

local mt = { 
    __eq = eq
}

local function processParts(self, parts)
    self.templates = {}

    for _,v in ipairs(parts[2]) do
        self.templates[v.name] = v
    end
end

local function loadGroupFile(self)
    local name, dir, scanner = self.group_name, self.dir, self.scanner
    local fname = dir .. '/' .. name

    local f = assert(io_open(fname, "r"))
    local grpText = f:read('*a')
    f:close()

    if grpText then
        local parser = STGParser(scanner)
        local parts = parser:parse(grpText)
        if parts == nil then
            error('Failed to parse group file', 3)
        end

        processParts(self, parts)
    end
end

local function getInstanceOf(self, templateName)
    local gt = self.templates[templateName]
    local st = nil

    if gt then st = gt.st end
    
    return st
end

--[[
--  Supported constructor calls:
--
--      StringTemplateGroup('templateName', 'dirName')
--
--      StringTemplateGroup({ name = 'templateName', 
--                            dir = 'dirName',
--                            scanner = StringTemplate.DOLLAR_SCANNER })
--
--]]
function __call(self, ...)
    local stg = {}
    setmetatable(stg, mt)

    if select('#', ...) == 0 then
        error('Zero-arg constructor not supported', 2)
    elseif select('#',...) == 2 then
        local name, dir = ...
        if type(name) ~= 'string' or type(dir) ~= 'string' then
            error('Bad arguments to constructor', 2)
        end

        stg.group_name = name
        stg.dir = dir
    elseif select('#', ...) == 1 and type(select(1, ...)) == 'table' then
        local args = select(1,...)

        stg.group_name = args.name
        stg.dir = args.dir
        stg.scanner = args.scanner
    else
        error('Bad arguments to constructor', 2)
    end

    if not stg.group_name or not stg.dir then
        error('Need group name and root directory', 2)
    end

    stg.scanner = stg.scanner or StringTemplate.ANGLE_BRACKET_SCANNER

    loadGroupFile(stg)

    stg.getInstanceOf = getInstanceOf

    return stg
end

setmetatable(_M, _M)
