module UArrayInts
export UArrayInt, add_carry, mul_carry, add!, mul!, to_unsigned

"""
Must be indexable and each element should be an unsigned type.
"""
struct UArrayInt{T}
    data::Array{T}
end

Base.getindex(x::UArrayInt{T}, i) where T = getindex(x.data, i)
Base.setindex!(x::UArrayInt{T}, i, y) where T = setindex!(x.data, i, y)
Base.lastindex(x::UArrayInt{T}) where T = lastindex(x.data)
Base.length(x::UArrayInt{T}) where T = length(x.data)

"""
multiply x and y, return the result and carry.
"""
function add_carry(x::T, y::T) where T
    lower = x + y
    upper = lower < x ? T(1) : T(0)
    return lower, upper
end
add_carry(x::UArrayInt{T}, y::UArrayInt{T}) where T = add_carry(x.data, y.data)

"""
calculate x + y and save the result in x, x and y must be a vectors of
unsigned types, they are little endian, i.e. the least significant entry
is the last.
"""
function add!(x::Vector{T}, y::Vector{T}, yexp = 0) where T
    l = length(x) - 1

    carry = T(0)
    i = 0
    @inbounds while i < length(x)
        ix = length(x) - i
        iy = length(y) + yexp - i

        x[ix], carry = add_carry(x[ix], carry)

        if iy > 0 && iy < length(y) + 1
            x[ix], carry1 = add_carry(x[ix], y[iy])
            # this should be impossible to overflow
            # e.g. 9999 + 9999 carry never overflows
            carry += carry1
        end

        i += 1
    end

    return x
end
add!(x::UArrayInt{T}, y::UArrayInt{T}) where T = add!(x.data, y.data)

# I am unhappy about casting this to a larger type, but I see no way around this
# apart from doing repeated additions which would be awfully slow.
function mul_carry(x::T, y::T) where T
    T2 = tp(sizeof(T) * 2)
    res = T2(x) * y # TODO: check if this uses the UInt64 * UInt64 -> UInt128
                    # instructions
    lower = res % T
    upper = (res >> (sizeof(T) * 8)) % T
    return lower, upper
end
mul_carry(x::UArrayInt{T}, y::UArrayInt{T}) where T = mul_carry(x.data, y.data)

function mul!(x::Vector{T}, y::T) where T <: Unsigned
    l = length(x) - 1

    carry = T(0)
    i = 0
    @inbounds while i < length(x)
        ix = length(x) - i

        x[ix], carry1 = mul_carry(x[ix], y)
        x[ix], carry2 = add_carry(x[ix], carry)

        carry = carry1 + carry2

        i += 1
    end

    return x
end
mul!(x::UArrayInt{T}, y::T) where T = mul!(x.data, y)

"""
TODO:  is there a way to save the result directly in x?
"""
function mul!(z::Vector{T}, x::Vector{T}, y::Vector{T}) where T <: Unsigned
    ly = length(y)

    fill!(z, zero(T))
    x2 = Array{T}(undef, length(x))

    i = 0
    @inbounds while i < ly
        iy = ly - i

        unsafe_copyto!(x2, 1, x, 1, length(x))
        mul!(x2, y[iy])
        add!(z, x2, i)

        i += 1
    end


    return z
end
mul!(x::UArrayInt{T}, y::UArrayInt{T}, z::UArrayInt{T}) where T =
    mul!(x.data, y.data, z.data)

function tp(x)
    if     x == 1  UInt8
    elseif x == 2  UInt16
    elseif x <= 4  UInt32
    elseif x <= 8  UInt64
    elseif x <= 16 UInt128
    else   error("x must be <= 16")
    end
end

@generated function to_unsigned(x::Array{T}, ::Val{N}) where N where T

    U = tp(sizeof(T) * N)

    sb = ntuple(i -> U(1) << (8 * sizeof(T) * (N - i)), N)

    ex = :($U(0))
    for i in 1:N
        ex = :($ex + $sb[$i] * x[$i])
    end

    return ex
end

to_unsigned(x::Array{T}) where T = to_unsigned(x, Val(length(x)))
to_unsigned(x::UArrayInt{T}) where T = to_unsigned(x.data)

end # module
