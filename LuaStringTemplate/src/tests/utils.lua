
module( 'utils', package.seeall )

require( 'lunit' )

function dump_obj(o)
    if type(o) == 'number' then
        io.write(o)
    elseif type(o) == 'string' then
        io.write(string.format('%q', o))
    elseif type(o) == 'boolean' then
        io.write(tostring(o))
    elseif type(o) == 'function' then
        io.write('function')
    elseif type(o) == 'table' then
        io.write('{\n')
        for k,v in pairs(o) do
            io.write('  ', k, ' = ')
            dump_obj(v)
            io.write(',\n')
        end
        io.write('}\n')
    else
        error('cannot serialize a ' .. type(o))
    end
end

local function basic_serialize(o)
    if type(o) == 'number' then
        return tostring(o)
    elseif type(o) == 'string' then
        return string.format('%q', o)
    elseif type(o) == 'boolean' then
        return tostring(o)
    elseif type(o) == 'function' then
        return 'function'
    elseif type(o) == 'nil' then
        return 'nil'
    else
        error('cannot serialize a ' .. type(o))
    end
end

function dump_table(name, value, saved)
    saved = saved or {}
    io.write(name, ' = ')
    if type(value) == 'table' then
        if saved[value] then                -- value already saved?
            io.write(saved[value], '\n')    -- use its previous name
        else
            saved[value] = name             -- save name for next time
            io.write("{}\n")                -- create a new table
            for k,v in pairs(value) do      -- save its fields
                k = basic_serialize(k)
                local fname = string.format("%s[%s]", name, k)
                dump_table(fname, v, saved)
            end
        end
    else
        io.write(basic_serialize(value), '\n')
    end
end

function assert_table_equal(expected, actual, debug, depth)
    lunit.assert_table(actual)
    lunit.assert_equal(#expected, #actual)
    depth = depth or 1
    debug = debug or false

    for k,v in pairs(expected) do
        local v2 = actual[k]
        local eq = tostring(v == v2)
        local leader = string.rep('-', depth)
        local leader = leader .. '>'

        if debug then 
            print(leader .. ' k:', k, ' v:', v, 'v2:', v2, 'eq:', eq) 
        end
        if type(v) == 'table' and type(v2) == 'table' then
            --[[
            --  If the objects have the isA function, they are 
            --   LuaStringTemplate custom classes, and they have 
            --   __eq metamethods.
            --]]
            if type(v.isA) == 'function' and type(v2.isA) == 'function' then
                if debug then
                    print(leader .. ' objects are lst classes')
                end
                lunit.assert_equal(v, v2)
            else
                if debug then
                    print(leader .. ' regular tables, recurse into assert_table_equal')
                end
                assert_table_equal(v, v2, debug, depth + 1)
            end
        else
            if debug then
                print(leader .. ' regular eq comparison')
            end
            lunit.assert_equal(v, actual[k])
        end
    end
end

