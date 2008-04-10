--[[
This script is the moral equivalent of the shell script lunit.  Its here to make launching the 
unit tests from Eclipse easier.

The script expects to receive the path to the project, the path to the LPEG library,
and the name of the script to run.
--]]

local projectPath = select(1, ...)
local lpegPath = select(2, ...)
local argv = { select(3, ...) }

package.path = projectPath .. '/src/?.lua;' .. projectPath .. '/src/tests/?.lua;;'
package.cpath = lpegPath .. '/?.so;;'

loadfile('lunit.lua')
loadfile('lunit-console.lua')

require( 'lunit' )

lunit.main(argv)
