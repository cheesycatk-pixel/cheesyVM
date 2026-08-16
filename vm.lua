local data = {
    stack = {},
    vars = {
        r1 = 0,
        r2 = 0,
        r3 = 0,
        r4 = 0,
        r5 = 0,
        r6 = 0,
        r7 = 0,
        r8 = 0
    },

    cvars = {},
    ip = 1,
    labels = {},
    return_ips = {},
    callstacks = {},
    callcvars = {},
    arrays = {},
    into = ""
}



local function split(str, sep)
    local result = {}
    local start = 1

    while true do
        local i, j = string.find(str, sep, start, true)

        if not i then
            table.insert(result, string.sub(str, start))
            break
        end

        table.insert(result, string.sub(str, start, i - 1))
        start = j + 1
    end

    return result
end

local function stringToBoolean(v)
    if v == "true" then
        return true
    elseif v == "false" then
        return false
    end
end

local function stackunderflow()
    error("stack underflow " .. data.ip)
end

local function resolve(arg)
    local value = data.vars[arg]

    if value ~= nil then
        return value
    end

    value = data.cvars[arg]

    if value ~= nil then
        return value
    end

    return arg
end

local function parseLiteral(v)
    if v == "true" then
        return true
    elseif v == "false" then
        return false
    elseif tonumber(v) then
        return tonumber(v)
    elseif (v:sub(1,1) == '"' and v:sub(-1) == '"')
        or (v:sub(1,1) == "'" and v:sub(-1) == "'") then
        return v:sub(2, -2)
    elseif v == "nil" then
        return nil
    else
        return v
    end
end

local handlers = {}

-- debug instructions
handlers["print"] = function(v)
    if data.vars[v] ~= nil then
        print(data.vars[v])
    elseif data.cvars[v] ~= nil then
        print(data.cvars[v])
    elseif not v then
        print(data.stack[#data.stack])
    end
end

handlers["strprint"] = function(v)
    print(tostring(v))
end

handlers["litprint"] = function(v)
    v = parseLiteral(v)
    print(v)
end

-- callstack instructions
-- i was lazy and tired and sleepy while making this so i decided to have different insturctions for callstacks
-- ugly but idk

handlers["lprint"] = function(v)
    if data.callcvars[#data.callcvars][v] ~= nil then
        print(data.callcvars[#data.callcvars][v])
        return
    end
    print(data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]])
end

handlers["lpush"] = function(v)
    v = resolve(v)

    table.insert(data.callstacks[#data.callstacks], v)
end

handlers["lpop"] = function(v)
    if #data.callstacks[#data.callstacks] <= 0 then stackunderflow() end

    if data.vars[v] ~= nil then
        data.vars[v] = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
        table.remove(data.callstacks[#data.callstacks], #data.callstacks[#data.callstacks])
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
        table.remove(data.callstacks[#data.callstacks], #data.callstacks[#data.callstacks])
        return
    end
    table.remove(data.callstacks[#data.callstacks], #data.callstacks[#data.callstacks])
end

handlers["ldup"] = function()
    handlers["lpush"](data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]])
end

handlers["lswap"] = function(v)
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a)
    handlers["lpush"](b)
end

handlers["ldup2"] = function()
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpush"](b)
    handlers["lpush"](a)
end

handlers["lrot"] = function()
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]
    local c = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 2]

    handlers["lpop"]()
    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](b)
    handlers["lpush"](c)
    handlers["lpush"](a)
end

handlers["lover"] = function()
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpush"](a)
end

handlers["ladd"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] + data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] + resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a + b)
end

handlers["lsub"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] - data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] - resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end
    
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a - b)
end

handlers["lmul"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] * data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] * resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end
    
    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a * b)
end

handlers["ldiv"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] / data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] / resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a / b)
end

handlers["lmod"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] % data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] % resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a % b)
end

handlers["land"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] and data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] and resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a and b)
end

handlers["lor"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a

        if data.callcvars[#data.callcvars][src] ~= nil then
            a = data.callcvars[#data.callcvars][dest] or data.callcvars[#data.callcvars][src]
        else
            a = data.callcvars[#data.callcvars][dest] or resolve(src)
        end

        data.callcvars[#data.callcvars][dest] = a
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a or b)
end

handlers["lnot"] = function(dest)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        data.callcvars[#data.callcvars][dest] = not data.callcvars[#data.callcvars][dest]
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]

    handlers["lpop"]()

    handlers["lpush"](not a)
end

handlers["lxor"] = function(dest, src)
    if data.callcvars[#data.callcvars][dest] ~= nil then
        local a = data.callcvars[#data.callcvars][dest]
        local b

        if data.callcvars[#data.callcvars][src] ~= nil then
            src = data.callcvars[#data.callcvars][src]
            b = src
        else
            src = resolve(src)
            b = src
        end

        local o1 = not a and b
        local o2 = not b and a

        data.callcvars[#data.callcvars][dest] = o1 or o2
        return
    elseif data.vars[dest] ~= nil then
        local a = data.vars[dest]
        local b

        if data.vars[src] ~= nil then
            src = data.vars[src]
            b = src
        else
            src = resolve(src)
            b = src
        end

        data.vars[dest] = a ~= b
        return
    elseif data.cvars[dest] ~= nil then
        local a = data.cvars[dest]
        local b

        if data.cvars[src] ~= nil then
            src = data.cvars[src]
            b = src
        else
            src = resolve(src)
            b = src
        end

        local o1 = not a and b
        local o2 = not b and a

        data.cvars[dest] = o1 or o2
        return
    end

    local a = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    local b = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks] - 1]

    handlers["lpop"]()
    handlers["lpop"]()

    handlers["lpush"](a ~= b)
end

handlers["lcrt"] = function(name)
    if data.callcvars[#data.callcvars][name] == nil then
        data.callcvars[#data.callcvars][name] = 0
    end
end

handlers["lmov"] = function(var, src)
    if data.callcvars[#data.callcvars][var] ~= nil then
        if data.callcvars[#data.callcvars][src] ~= nil then
            data.callcvars[#data.callcvars][var] = data.callcvars[#data.callcvars][src]
        else
            src = resolve(src)
            data.callcvars[#data.callcvars][var] = src
        end
    else
        var = resolve(var)
        handlers["lmov"](var, src)
    end
end

handlers["lrem"] = function(var)
    data.callcvars[#data.callcvars][var] = nil
end

handlers["linc"] = function(v)
    if data.callcvars[#data.callcvars][v] ~= nil then
        data.callcvars[#data.callcvars][v] = data.callcvars[#data.callcvars][v] + 1
        return
    end

    v = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]] = v + 1
end

handlers["ldec"] = function(v)
    if data.callcvars[#data.callcvars][v] ~= nil then
        data.callcvars[#data.callcvars][v] = data.callcvars[#data.callcvars][v] - 1
        return
    end

    v = data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]] = v - 1
end

handlers["lneg"] = function(v)
    if data.callcvars[#data.callcvars][v] ~= nil then
        data.callcvars[#data.callcvars][v] = -data.callcvars[#data.callcvars][v]
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = -data.cvars[v]
        return
    end

    v = -data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]]
    data.callstacks[#data.callstacks][#data.callstacks[#data.callstacks]] = v
end

-- stack instructions
handlers["push"] = function(v)
    v = resolve(v)

    table.insert(data.stack, v)
end


handlers["pop"] = function(v)
    if #data.stack <= 0 then stackunderflow() end

    if data.vars[v] ~= nil then
        data.vars[v] = data.stack[#data.stack]
        table.remove(data.stack, #data.stack)
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = data.stack[#data.stack]
        table.remove(data.stack, #data.stack)
        return
    end
    table.remove(data.stack, #data.stack)
end

handlers["dup"] = function()
    handlers["push"](data.stack[#data.stack])
end

handlers["swap"] = function()
    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]

    handlers["pop"]()
    handlers["pop"]()

    handlers["push"](a)
    handlers["push"](b)
end

handlers["dup2"] = function()
    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]

    handlers["push"](b)
    handlers["push"](a)
end

handlers["rot"] = function()
    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]
    local c = data.stack[#data.stack - 2]

    handlers["pop"]()
    handlers["pop"]()
    handlers["pop"]()

    handlers["push"](b)
    handlers["push"](c)
    handlers["push"](a)
end

handlers["over"] = function()
    local a = data.stack[#data.stack - 1]

    handlers["push"](a)
end

handlers["add"] = function(a, b)
    if data.vars[a] ~= nil then
        data.vars[a] = data.vars[a] + (data.vars[b] ~= nil and data.vars[b] or tonumber(b))
    elseif data.cvars[a] ~= nil then
        data.cvars[a] = data.cvars[a] + (data.cvars[b] ~= nil and data.cvars[b] or tonumber(b))
    else
        local a = data.stack[#data.stack]
        local b = data.stack[#data.stack - 1]

        handlers["pop"]()
        handlers["pop"]()

        handlers["push"](a + b)
    end
end

handlers["sub"] = function(a, b)
    if data.vars[a] and b then
        data.vars[a] = data.vars[a] - (data.vars[b] or tonumber(b))
    else
        local a = data.stack[#data.stack]
        local b = data.stack[#data.stack - 1]

        handlers["pop"]()
        handlers["pop"]()

        handlers["push"](a - b)
    end
end

handlers["mul"] = function(a, b)
    if data.vars[a] and b then
        data.vars[a] = data.vars[a] * (data.vars[b] or tonumber(b))
    else
        local a = data.stack[#data.stack]
        local b = data.stack[#data.stack - 1]

        handlers["pop"]()
        handlers["pop"]()

        handlers["push"](a * b)
    end
end

handlers["div"] = function(a, b)
    if data.vars[a] and b then
        data.vars[a] = data.vars[a] / (data.vars[b] or tonumber(b))
    else
        local a = data.stack[#data.stack]
        local b = data.stack[#data.stack - 1]

        handlers["pop"]()
        handlers["pop"]()

        handlers["push"](a / b)
    end
end

handlers["mod"] = function(a, b)
    if data.vars[a] and b then
        data.vars[a] = data.vars[a] % (data.vars[b] or tonumber(b))
    else
        local a = data.stack[#data.stack]
        local b = data.stack[#data.stack - 1]

        handlers["pop"]()
        handlers["pop"]()

        handlers["push"](a % b)
    end
end

handlers["and"] = function(a, b)
    if a and b then
        data.vars[a] = data.vars[a] and (data.vars[b] or b)
        data.cvars[a] = data.cvars[a] and (data.cvars[b] or b)
        return
    end

    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]

    handlers["pop"]()
    handlers["pop"]()

    handlers["push"](a and b)
end

handlers["or"] = function(a, b)
    if a and b then
        data.vars[a] = data.vars[a] or (data.vars[b] or b)
        data.cvars[a] = data.cvars[a] or (data.cvars[b] or b)
        return
    end

    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]

    handlers["pop"]()
    handlers["pop"]()

    handlers["push"](a or b)
end

handlers["not"] = function(a)
    if a then
        data.vars[a] = not data.vars[a]
        data.cvars[a] = not data.cvars[a]
        return
    end

    local a = data.stack[#data.stack]

    handlers["pop"]()

    handlers["push"](not a)
end

handlers["xor"] = function(a, b)
    if a and b then
        local inp1 = data.vars[a] or data.cvars[a]
        local inp2 = data.vars[b] or data.cvars[b] or b

        if inp1 == nil then
            inp1 = false
        end

        if inp2 == nil then
            inp2 = false
        end

        local out3 = inp1 ~= inp2

        if data.vars[a] then
            data.vars[a] = out3
        elseif data.cvars[a] then
            data.cvars[a] = out3
        end

        return
    end
    local a = data.stack[#data.stack]
    local b = data.stack[#data.stack - 1]

    handlers["pop"]()
    handlers["pop"]()

    handlers["push"](a ~= b)
end

-- register instructions

handlers["mov"] = function(dest, src)
    src = resolve(src)

    if data.vars[dest] ~= nil then
        data.vars[dest] = data.vars[src] or data.cvars[src] or src
    elseif data.cvars[dest] ~= nil then
        data.cvars[dest] = data.vars[src] or data.cvars[src] or src
    end
end

handlers["crt"] = function(name)
    data.cvars[name] = 0
end

handlers["rem"] = function(var)
    data.cvars[var] = nil
end

handlers["inc"] = function(v)
    if data.vars[v] ~= nil then
        data.vars[v] = data.vars[v] + 1
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = data.cvars[v] + 1
        return
    end

    data.stack[#data.stack] = data.stack[#data.stack] + 1
end

handlers["dec"] = function(v)
    if data.vars[v] ~= nil then
        data.vars[v] = data.vars[v] - 1
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = data.cvars[v] - 1
        return
    end

    data.stack[#data.stack] = data.stack[#data.stack] - 1
end

handlers["neg"] = function(v)
    if data.vars[v] ~= nil then
        data.vars[v] = -data.vars[v]
        return
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = -data.cvars[v]
        return
    end

    data.stack[#data.stack] = -data.stack[#data.stack]
end

-- function instructions

handlers["call"] = function(name)
    if data.labels[name] then
        table.insert(data.callstacks, {})
        table.insert(data.return_ips, data.ip + 1)
        table.insert(data.callcvars, {})
        handlers["jmp"](data.labels[name])
    end
end

handlers["ret"] = function()
    if #data.return_ips <= 0 then return end
    local ret_ip = data.return_ips[#data.return_ips]

    table.remove(data.return_ips, #data.return_ips)
    table.remove(data.callstacks, #data.callstacks)
    table.remove(data.callcvars, #data.callcvars)

    handlers["jmp"](ret_ip - 1)
end

-- array instructions

handlers["crtarr"] = function(name)
    data.arrays[name] = {}
end

handlers["pushval"] = function(name, i)
    if data.arrays[name] then
        handlers["push"](data.arrays[name][i + 1])
    end
end

handlers["movarr"] = function(name, i, val)
    val = resolve(val)

    data.arrays[name][i + 1] = val
end

handlers["remarr"] = function(name)
    data.arrays[name] = nil
end

-- other instructions

handlers["jmp"] = function(addr)
    data.ip = addr
end

handlers["je"] = function(a, b, addr)
    if resolve(a) == resolve(b) then
        handlers["jmp"](addr)
    end
end

handlers["jne"] = function(a, b, addr)
    if resolve(a) ~= resolve(b) then
        handlers["jmp"](addr)
    end
end

handlers["jl"] = function(a, b, addr)
    a = tonumber(resolve(a))
    b = tonumber(resolve(b))
    if a < b then
        handlers["jmp"](addr)
    end
end

handlers["jle"] = function(a, b, addr)
    a = tonumber(resolve(a))
    b = tonumber(resolve(b))
    if a <= b then
        handlers["jmp"](addr)
    end
end

handlers["jg"] = function(a, b, addr)
    a = tonumber(resolve(a))
    b = tonumber(resolve(b))
    if a > b then
        handlers["jmp"](addr)
    end
end

handlers["jge"] = function(a, b, addr)
    a = tonumber(resolve(a))
    b = tonumber(resolve(b))
    if a >= b then
        handlers["jmp"](addr)
    end
end

handlers["conv"] = function(v, t)
    if data.vars[v] ~= nil then
        if t == "string" then
            data.vars[v] = tostring(data.vars[v])
        elseif t == "number" then
            data.vars[v] = tonumber(data.vars[v])
        elseif t == "boolean" then
            if data.vars[v] == "true" or data.vars[v] == "1" or data.vars[v] == 1 then
                data.vars[v] = true
            elseif data.vars[v] == "false" or data.vars[v] == "0" or data.vars[v] == 0 then
                data.vars[v] = false
            end
        end
    elseif data.cvars[v] ~= nil then
        if t == "string" then
            data.cvars[v] = tostring(data.cvars[v])
        elseif t == "number" then
            data.cvars[v] = tonumber(data.cvars[v])
        elseif t == "boolean" then
            if data.cvars[v] == "true" or data.cvars[v] == "1" or data.cvars[v] == 1 then
                data.cvars[v] = true
            elseif data.cvars[v] == "false" or data.cvars[v] == "0" or data.cvars[v] == 0 then
                data.cvars[v] = false
            end
        end
    else
        v = data.stack[#data.stack]
        if t == "string" then
            v = tostring(v)
        elseif t == "number" then
            v = tonumber(v)
        elseif v == "true" or data.cvars[v] == "1" or data.cvars[v] == 1 then
            v = true
        elseif v == "false" or data.cvars[v] == "0" or data.cvars[v] == 0 then
            v = false
        end
        handlers["pop"]()
        handlers["push"](v)
    end
end

handlers["type"] = function(dest, src)
    dest = resolve(dest)
    src = resolve(src)

    if src ~= nil then
        src = parseLiteral(src)
    end

    if dest then
        dest = type(src)
    else
        local a = parseLiteral(data.stack[#data.stack])
        a = type(a)
        handlers["pop"]()
        handlers["push"](a)
    end
end

handlers["hlt"] = function()
    handlers["jmp"](math.huge)
end

handlers["into"] = function(dir)
    dir = resolve(dir)
    if data.into == "" then
        data.into = dir
    else
        data.into = data.into .. "." .. dir
    end
end

handlers["out"] = function()
    if data.into ~= "" and #split(data.into, ".") ~= 1 then
        local a = split(data.into, ".")
        local b = ""
        for i = 1, #a-1 do
            b = b .. a[i] .. "."
        end
        if b:sub(#b, #b) == "." then
            b = b:sub(1, #b-1)
        end
    else
        data.into = ""
    end
end

handlers["icall"] = function(func, amount)
    local vals = {}
    for i = 0, amount - 1 do
        table.insert(vals, data.stack[#data.stack - i])
    end

    for i = amount, 1, -1 do
        vals[i] = data.stack[#data.stack]
        handlers["pop"]()
    end

    local v

    local func = loadstring("return " .. data.into .. "." .. func .. "(...)")

    v = func(unpack(vals))
    
    --print(v)

    if v ~= nil then
        handlers["push"](v)
    end
end

handlers["clinto"] = function()
    data.into = ""
end

-- basically pop that instead of giving stack overflow it just returns a boolean if it succeeded
-- it uses the r8 register as then value to put the boolean into
handlers["tpop"] = function(v)
    if #data.stack <= 0 then
        data.vars.r8 = false
        return
    end

    if data.vars[v] ~= nil then
        data.vars[v] = data.stack[#data.stack]
    elseif data.cvars[v] ~= nil then
        data.cvars[v] = data.stack[#data.stack]
    end

    table.remove(data.stack, #data.stack)
    data.vars.r8 = true
end

local function createRegisters(amount)
    for i = 1, amount do
        data.vars["r" .. i] = 0
    end
end

local vm = {}

function vm.splitcode(code)
    if code:sub(1, 1) == "\n" then
        code = code:sub(2)
    end

    if code:sub(#code, #code) == "\n" then
        code = code:sub(1, #code - 1)
    end

    local splitcode = split(code, "\n")
    for i = 1, #splitcode do
        for j = 1, #splitcode[i] do
            if splitcode[i]:sub(j, j) == ";" then
                splitcode[i] = splitcode[i]:sub(1, j - 1)
            end
        end
        splitcode[i] = splitcode[i]:gsub("^%s+", "")
    end

    local new = {}

    for i = 1, #splitcode do
        local splitline = split(splitcode[i], " ")

        table.insert(new, splitline)
    end
    
    for i = 1, #new do
    	if new[i][1]:lower() ~= "icall" then
    		for j = 1, #new[i] do
    			new[i][j] = new[i][j]:lower()
    		end
    	else
    		new[i][1] = new[i][1]:lower()
    	end
   	end

    for i = 1, #new do
        if new[i][1]:sub(#new[i][1], #new[i][1]) == ":" then
            data.labels[new[i][1]:sub(1, #new[i][1] - 1)] = i
        end
    end

    for i = 1, #new do
        -- ugly but it works
        if new[i][1] == "jmp" and data.labels[new[i][2]] then
            new[i][2] = data.labels[new[i][2]]
        elseif new[i][1] == "je" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        elseif new[i][1] == "jne" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        elseif new[i][1] == "jl" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        elseif new[i][1] == "jg" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        elseif new[i][1] == "jle" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        elseif new[i][1] == "jge" and data.labels[new[i][4]] then
            new[i][4] = data.labels[new[i][4]]
        end

        for j = 1, #new[i] do
            --io.write(new[i][j] .. "\t") -- debug (print processed code)
        end
        --print() -- new line for the io.write once it ends using the line
    end

    for i, v in pairs(data.labels) do
        --print(i, v) -- debug (print all labels)
    end

    return new
end

function vm.exec(code)
    local cont = false
    while data.ip <= #code do
        local i = data.ip
        local op = code[i][1]
        local arg1 = code[i][2]
        local arg2 = code[i][3]
        local arg3 = code[i][4]

        if not handlers[op] then cont = true end

        if not cont then
            handlers[op](arg1, arg2, arg3)
        else
            cont = false
        end
        data.ip = data.ip + 1
    end
    data.ip = 1
end

local function stackview()
    for i = 1, #data.stack do
        print(data.stack[i])
    end
end

local current = 1
local function registerview()
    for i, v in data.vars do
        if tonumber(i:sub(2, #i)) == current then
            print(i, v)
            current = current + 1
            registerview()
        end
    end
end

local function customvarview()
    for i, v in data.cvars do
        print(i, v)
    end
end

return vm

-- stackview() -- debug (prints all contents in the stack)
-- registerview() -- debug (prints all registers/variables)
-- customview() -- debug (prints all custom variables)