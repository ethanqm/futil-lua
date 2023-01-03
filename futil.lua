require("math")

op = {
    add = function(a,b) return a+b end,
    sub = function(a,b) return a-b end,
    mul = function(a,b) return a*b end,
    div = function(a,b) return a/b end,
    mod = function(a,b) return a%b end,
    index = function(t,k) return t[k] end,
    concat = function(a,b) return a..b end,
    pair = function(a,b) return {a,b} end,
}

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
    for k,v in pairs(t) do
        if k == "true" then goto cont end
        out[v] = true
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


function map(f, t)
    local out = {}
    for i,v in ipairs(t) do
        out[i] = f(v)
    end
    return out
end
function kmap(f, t)
    local out = {}
    for i,v in pairs(t) do
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
function forEachK(f, t)
    for i,v in pairs(t) do
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
function foldr(f, init, t)
    for i=#t,1, -1 do
        init = f(t[i], init)
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

function filter_iter(p, it)
    return coroutine.create(function(p,it)
        while true do
            local e = coroutine.resume(it)
            if e == nil then coroutine.yield(e) end
            if p(e) then coroutine.yield(e) end
        end
    end)

end

function flatten(t,n)
    local out = {}
    local function rec(out, e,n)
        if n == 0 then out[#out+1]=e; return end
        for _,v in ipairs(e) do
            if type(v) == "table" then
                if n == nil then
                    rec(out, v, nil)
                else
                    rec(out, v, n-1)
                end
            else
                out[#out+1] = v
            end
        end
    end
    for _,v in ipairs(t) do
        if type(v) == "table" then
            rec(out, v,n)
        else
            out[#out+1] = v
        end
    end
    return out
end

function iunion(a,b)
    return flatten({a,b},1)
end

function collect(...) return {...} end
function apply(f, ...) return f(...) end
function id(x) return x end
function var_id(...) return ... end
function first(x,...) return x end
function flip(a,b) return b,a end
function after(...)
    local fs = {...}
    return function(...)
        foldr(apply, var_id(...), fs)
    end
end
function dotwice(f, args)
    return f(f(table.unpack(args)))
end
function fork(f,g,x) return f(x)(g(x)) end

function decl(name,value) _ENV[name] = value end

function flatmap(f,t) return flatten(map(f,t)) end

function outer_product(a,b,f)
    local out = {}
    for i,x in ipairs(b) do
        out[#out+1] = {}
        for j,y in ipairs(a) do
            if f == nil then 
                out[i][j] = {y,x}
            else
                out[i][j] = f(y,x)
            end
        end
    end
    return out
end

function curry(f,args,n)
    local n = n or debug.getinfo(f).nparams
    local args = args or {}
    if debug.getinfo(f).isvararg and n <= #args then
        return f(table.unpack(args))
    elseif #args == n then
        return f(table.unpack(args))
    elseif #args < n then
        return function(nargs)
            local args = args or {}
            local nargs = nargs or {}
            local flargs = flatten({args,nargs},1)
            return curry(f, flargs,n)
        end
    else
        after(print,show_t)(args)
        return "bad args"
    end
end

function make_vararg(f)
    local n = debug.getinfo(f).nparams
    local consumer = function(x, ...)
        return fold(f, x, {...})
    end
    return consumer
end

varg_math = {
    sum = make_vararg(op.add),
    product = make_vararg(op.mul),
}

-- repl stuff (which barely prints btw)
ps = after(print, tostring)
pt = after(print, show_t)
su = make_vararg(shadow_union)

ez = su({
    double = function(a) return a*2 end,
    inc = curry(op.add, {1}),
    dec = curry(op.sub, {1})
},op,varg_math)

