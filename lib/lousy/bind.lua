local assert = assert
local ipairs = ipairs
local pairs = pairs
local print = print
local setmetatable = setmetatable
local string = string
local table = table
local type = type
local unpack = unpack
local util = require("lousy.util")

module("lousy.bind")

-- Weak table of objects and their buffers
local buffers = {}
setmetatable(buffers, { __mode = "k" })

-- Modifiers to ignore
ignore_modifiers = { "Mod2", "Lock" }

-- Return cloned, sorted & filtered modifier mask table.
function filter_mods(mods, remove_shift)
    -- Clone & sort new modifiers table
    local mods = util.table.clone(mods)
    table.sort(mods)

    -- Filter out ignored modifiers
    mods = util.table.difference(mods, ignore_modifiers)

    if remove_shift then
        mods = util.table.difference(mods, { "Shift" })
    end

    return mods
end

-- Create new key binding
function key(mods, key, func, opts)
    local mods = filter_mods(mods, #key == 1)
    return { mods = mods, key = key, func = func, opts = opts}
end

-- Create new button binding
function but(mods, button, func, opts)
    local mods = filter_mods(mods, false)
    return { mods = mods, button = button, func = func, opts = opts}
end

-- Create new buffer binding
function buf(pattern, func, opts)
    return { pattern = pattern, func = func, opts = opts}
end

-- Create new command binding
function cmd(commands, func, opts)
    return { commands = commands, func = func, opts = opts}
end

-- Check if there exists a key binding in the `binds` table which matches the
-- pressed key and modifier mask then execute it
function match_key(binds, mods, key, arg)
    for _, b in ipairs(binds) do
        if b.key == key and util.table.isclone(b.mods, mods) then
            b.func(arg, b.opts)
            return true
        end
    end
end

-- Check if there exists a key binding in the `binds` table which matches the
-- pressed key and modifier mask then execute it
function match_button(binds, mods, button, arg)
    for _, b in ipairs(binds) do
        if b.button == button and util.table.isclone(b.mods, mods) then
            b.func(arg, b.opts)
            return true
        end
    end
end

-- Check if there exists a buffer binding in the `binds` table which matches
-- the given buffer then execute it.
function match_buf(binds, buffer, arg)
    for _, b in ipairs(binds) do
        if b.pattern and string.match(buffer, b.pattern) then
            b.func(arg, buffer, b.opts)
            return true
        end
    end
end

-- Check if there exists a buffer binding in the `binds` table which matches
-- the given buffer then execute it.
function match_cmd(binds, buffer, arg)
    -- The command is the first word in the buffer string
    local command  = string.match(buffer, "^([^%s]+)")
    -- And the argument is the entire string thereafter
    local argument = string.match(buffer, "^[^%s]+%s+(.+)")

    for _, b in ipairs(binds) do
        -- Command matching
        if b.commands and util.table.hasitem(b.commands, command) then
            b.func(arg, argument, b.opts)
            return true
        -- Buffer matching
        elseif b.pattern and string.match(buffer, b.pattern) then
            b.func(arg, buffer, b.opts)
            return true
        end
    end
end

-- Check if a bind exists with the given key & modifier mask then call the
-- binds function with `arg` as the first argument.
function hit(binds, mods, key, buffer, enable_buffer, arg)
    -- Filter modifers table
    local mods = filter_mods(mods, type(key) == "string" and #key == 1)

    -- Match button bindings
    if type(key) == "number" then
        return match_button(binds, mods, key, arg)

    -- Match key bindings
    elseif (not buffer or not enable_buffer) or #mods ~= 0 or #key ~= 1 then
        if match_key(binds, mods, key, arg) then
            return true
        end
    end

    -- Clear buffer
    if not enable_buffer or #mods ~= 0 then
        return false

    -- Match buffer
    elseif #key == 1 then
        buffer = (buffer or "") .. key
        if match_buf(binds, buffer, arg) then
            return true
        end
    end

    -- Return buffer if valid
    if buffer then
        return true, buffer:sub(1, 10)
    end
    return true
end

-- vim: ft=lua:et:sw=4:ts=8:sts=4:tw=80
