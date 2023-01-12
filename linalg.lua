require("futil")

function as_vector(t)
    local meta = {
        __unm = function(self) return as_vector(map(op.min, self)) end,
        __add = function(self, other)
            return as_vector(zip_with(op.add,self,other))
        end,
        __sub = function(self,other)
            return (-self) + other
        end,
        __mul = function(self,other)
            local switch = {
                number = function()
                    return map(curry(op.mul,{other}),self)
                end,
                table = function()
                    return fold(op.add, (self - self),
                    zip_with(op.mul, self,other))
                end
            }
            return as_vector(switch[type(other)]())
        end,
        __eq = function(self,other)
            return varg.all(table.unpack(
            zip_with(op.eq, self,other)))
        end,
        __index = function(self, idx)
            if type(idx) == "number" then
                return rawget(self,idx)
            end
            local aliases = {
                x=1,i=1,r=1,
                y=2,j=2,g=2,
                z=3,k=3,b=3,
                w=4,l=4,a=4,
            }
            if type(idx) =="string" and #idx < 2 then
                return self[aliases[idx]]
            end
        end,
    }
    return setmetatable(t,meta)
end
