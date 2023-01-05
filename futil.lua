require("math")

op = {
    add = function(a,b) return a+b end,
    sub = function(a,b) return a-b end,
    mul = function(a,b) return a*b end,
    div = function(a,b) return a/b end,
    neg = function(a) return -a end,

    eq = function(a,b) return a==b end,
    geq = function(a,b) return a>=b end,
    leq = function(a,b) return a<=b end,
    neq = function(a,b) return a~=b end,
    lt = function(a,b) return a>b end,
    gt = function(a,b) return a<b end,

    lnot = function(a) return not a end,
    land = function(a,b) return a and b end,
    lor = function(a,b) return a or b end,
    lxor = function(a,b) return (a or b) and not (a and b) end,

    index = function(t,k) return t[k] end,
    concat = function(a,b) return a..b end,
    pair = function(a,b) return {a,b} end,
    count = function(x) return #x end,
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
        out[k] = true
        ::cont::
    end
    return out
end

function show_t(t, indents,vts)
    local vts = vts or {}
    local visited_tables = shadow_union(hash_true({t, _G, _ENV}), vts)
    local indents = indents or 0
    local iden = "  "
    local out = {string.rep(iden,indents).."{"}

    for i,v in pairs(t) do
        out[#out+1] = "\n"..string.rep(iden,indents+1)
        if v == t then goto cont end
        if type(v) == "table" then
            if visited_tables[v] then
                print("recursive def:"..tostring(i).." "..tostring(v))
                out[#out+1] = i..": rec{ ... },"
            else
                out[#out+1] = i..": ".."table:\n"..show_t(v, indents+2, visited_tables)..","
            end
            visited_tables = shadow_union(hash_true({v}), visited_tables)
        else
            --@todo! refactor
            --local fixbool = function(b)
            --    if type(b) ~= "bool" then return b end
            --    return tostring(b)
            --end
            --local v = fixbool(v)

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
        ::cont::
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

function zip_with(f,...)
    local out = {}
    local ts = {...}
    local longest = math.max(table.unpack(map(op.count,ts)))

    for i=1, longest do
        --might be useful elsewhere
        --!difficult to curry op.index,.. w flip, very hard
        local nths = map(function(t) return op.index(t,i) end, ts)
        out[i] = f(table.unpack(nths))
    end
    return out
end

function zip(...)
    return zip_with(collect,...)
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
function id(x) return x end --I combinator
function var_id(...) return ... end
function first(x,...) return x end --K combinator
function flip(a,b) return b,a end
function rep(a) return table.unpack({a,a}) end --M combinator
function comp(...) --function composition/B combinator
    local fs = {...}
    --extracting first two funcs to 
    --properly handle vargs/table.unpack
    local f = fs[#fs] --first to run
    fs[#fs] = nil --clear
    local g = fs[#fs] --second to run
    fs[#fs] = nil --clear
    return function(...)
        return foldr(apply, g(f(...)), fs)
    end
end
function dotwice(f, args)
    return f(f(table.unpack(args)))
end
function fork(f,g,x) --S combinator
    return f(x)(g(x))
end
function fork_train(m,b,n) --S' combinator
    return function(...)
        return b(m(...), n(...))
    end
end
function fix(f,x) --Y combinator
    local first = f(x)
    if first == x then return first end
    return fix(f, first)
end

function decl(name,value) _ENV[name] = value end
function undecl(name) _ENV[name] = nil end
function use(t) -- unpack table into calling scope
    forEachK(comp(decl, table.unpack), kvs_of(t))
end
function unuse(t) -- set keys to nil
    forEachK(undecl, keys_of(t))
end
function unuse_list(t) -- undeclare list of strings
    forEach(function(s)
        if type(s) == "string" then
            undecl(s)
        end
    end,
        vals_of(t))
end

function flatmap(f,t) return flatten(map(f,t)) end

function outer_product(a,b,f)
    local out = {}
    for i,x in ipairs(b) do
        out[#out+1] = {}
        for j,y in ipairs(a) do
            if f == nil then
                out[i][j] = {y,x}--cartesian product
            else
                out[i][j] = f(y,x)
            end
        end
    end
    return out
end

function range(start, notinc, step)
    local step = step or 1
    local out = {}
    for i=start,notinc-1,step do
        out[#out+1] = i
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
         comp(print,show_t)(args)
        return "bad args"
    end
end

function make_vararg(f)
    local consumer = function(x, ...)
        return fold(f, x, {...})
    end
    return consumer
end

varg = {
    sum = make_vararg(op.add),
    product = make_vararg(op.mul),
    any = make_vararg(op.lor),
    all = make_vararg(op.land),
    none = make_vararg(comp(op.lnot,op.land)),
    one = make_vararg(op.lxor),
}


function cons(a,rest)
    return {a,rest}
end
function car(t)
    return t[1]
end
function cdr(t)
    return t[2]
end

-- repl stuff (which barely prints btw)
ps = comp(print, tostring) -- ooh~ point free~
pt = comp(print, show_t)
su = make_vararg(shadow_union)

ez = su({
    double = curry(op.mul, {2}),
    inc = curry(op.add, {1}),
    dec = curry(op.sub, {1}),
    time = function(f,args, n)
        local start = os.time()
        for _=1,n do
            f(table.unpack(args))
        end
        local en = os.time()
        print(os.difftime(en,start))
    end,
    -- +/ % #
    avg = fork_train(varg.sum, op.div, comp(op.count,collect)),

},op,varg)

