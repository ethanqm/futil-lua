require("math")

function inverse_table(t)
    local out = {}
    for key, value in pairs(t) do
        out[value] = key
    end
    return out
end

function keys_of(t)
    local out = {}
    for k,_ in pairs(t) do
        out[#out+1] = k
    end
    return out
end
function vals_of(t)
    local out = {}
    for _,v in pairs(t) do
        out[#out+1] = v
    end
    return out
end
function kvs_of(t)
    local out = {}
    for k,v in pairs(t) do
        out[#out+1] = {k,v}
    end
    return out
end
function from_kvs(l)
    local out = {}
    for _,v in ipairs(l) do
        out[v[1]] = v[2]
    end
    return out
end

function shadow_union(sup, sub)
    local out = {}
    for k,v in pairs(sub) do
        out[k] = v
    end
    for k,v in pairs(sup) do
        out[k] = v
    end
    return out
end

function hash_true(t)
    local out = {}
    for k,_ in pairs(t) do
        if k == "true" then goto cont end
        out[k] = true
        ::cont::
    end
    return out
end

function show_t(t, indents)
    local visited_tables = hash_true(map(tostring,{t, _G, _ENV}))
    local indents = indents or 0
    local iden = "  "
    local out = {string.rep(iden,indents).."{"}

    for i,v in pairs(t) do
        out[#out+1] = "\n"..string.rep(iden,indents+1)
        if type(v) == "table" then
            if visited_tables[tostring(v)] then
                print("recursive def:"..tostring(i).." "..tostring(v))
                out[#out+1] = i..": rec{ ... },"
            else
                out[#out+1] = i..": ".."table:\n"..show_t(v, indents+2)..","
            end
            visited_tables = hash_true(shadow_union({tostring(v)}, visited_tables))
        else
            --@todo! refactor
            local fixbool = function(b)
                if type(b) ~= "bool" then return b end
                return tostring(b)
            end
            local v = fixbool(v)
            --local fixfunc = function(k,f)
            --    if type(f) ~= "function" then
            --        return f
            --    end
            --    return tostring(f).."(fn)" --key-name
            --end
            --local v = fixfunc(i,v)

            function show(out, i,v)
                out[#out+1] = i..": "..v..","
                return true
            end
            local res, _  = pcall(show, out,i,v)
            if not res then
                --if fail to print value, print key again
                show(out,tostring(i),tostring(v).."(np)"..type(v))
            end

        end
    end


    if #out > 1 then
        out[#out+1] = "\n"..string.rep(iden,indents)
    end
    out[#out+1] = ("}")

    return table.concat(out)
end

function pt(t) print(show_t(t)) end

function map(f, t)
    local out = {}
    for i,v in ipairs(t) do
        out[i] = f(v)
    end
    return out
end

function forEach(f, t)
    for i,v in ipairs(t) do
        t[i] = f(v)
    end
    return t
end

--aka reduce
function fold(f, init, t)
    for _,v in ipairs(t) do
        init = f(init, v)
    end
    return init
end

function zip(t1,t2)
    local out = {}
    local longest = math.max(#t1,#t2)

    for i=1, longest do
        out[i] = {t1[i], t2[i]}
    end
    return out
end

function zip3(t1,t2,t3)
    local out = {}
    local longest = math.max(#t3,math.max(#t1,#t2))

    for i=1, longest do
        out[i] = {t1[i], t2[i], t3[i]}
    end
    return out
end

function zip_with(f,t1,t2)
    local out = {}
    local longest = math.max(#t1,#t2)

    for i=1, longest do
        out[i] = f(t1[i], t2[i])
    end
    return out
end

function gen_iiter(t)
    return coroutine.create(function()
        for _,v in ipairs(t) do
            coroutine.yield(v)
        end
    end)
end
function gen_iter(t)
    return coroutine.create(function()
        for k,v in pairs(t) do
            coroutine.yield(v,k)
        end
    end)
end

function iiter_take(it, n)
    local out = {}
    for _=1, n do
        out[#out+1] = coroutine.resume(it)
    end
    return out
end
function kiter_take(it, n)
    local out = {}
    for _=1, n do
        v,k  = coroutine.resume(it)
        out[k] = v
    end
    return out
end

function iflatten(t)
    local out = {}
    local function rec(out, e)
        for _,v in ipairs(e) do
            if type(v) == "table" then
                rec(out, v)
            else
                out[#out+1] = v
            end
        end
    end
    for _,v in ipairs(t) do
        if type(v) == "table" then
            rec(out, v)
        else
            out[#out+1] = v
        end
    end
    return out
end

function after(a,b)
    return function(x)
        a(b(x))
    end
end

function ps(x) return after(print, tostring)(x) end
