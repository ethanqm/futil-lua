require("futil")

function test()
    local h <close> = get_defer_handle(print, {"deferred1"})

    local meta = {__close =
        function() print("deferred2") end
    }
    local handle <close> = setmetatable({},meta)
    print("testing...")
end

function main()
    print("start main")
    test()
    print("end main")
end
main()
