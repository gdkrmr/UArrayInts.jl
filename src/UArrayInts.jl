module UArrayInts

"""
Must be indexable and each element should be an unsigned type.
"""
abstract type UArrayInt end

"""
multiply x and y, return the result and carry.
"""
function add_carry(x::T, y::T) where T <: Unsigned
    lower = x + y
    upper = lower < x ? T(1) : T(0)
    return lower, upper
end

"""
calculate x + y and save the result in x, x and y must be a vectors of
unsigned types, they are little endian, i.e. the least significant entry
is the last.
"""
function add!(x::Vector{T}, y::Vector{T}, yexp = 0) where T <: Unsigned
    l = length(x) - 1

    carry = T(0)
    i = 0
    @inbounds while i < length(x)
        ix = length(x) - i
        iy = length(y) + yexp - i

        x[ix], carry = add_carry(x[ix], carry)

        if iy > 0 && iy < length(y) + 1
            x[ix], carry1 = add_carry(x[ix], y[iy])
            # this should be impossible to overflow e.g. 9999 + 9999 carry never overflows
            carry += carry1
        end

        i += 1
    end

    return x
end

# I am unhappy about casting this to a larger type, but I see no way around this
# apart from doing repeated additions which would be awfully slow.
function mul_carry(x::T, y::T) where T
    T2 = tp(sizeof(T) * 2)
    res = T2(x) * y # TODO: check if this uses the UInt64 * UInt64 -> UInt128 instructions
    lower = res % T
    upper = (res >> (sizeof(T) * 8)) % T
    return lower, upper
end

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

to_unsigned(x) = to_unsigned(x, Val(length(x)))

#=
function Base.bswap(x::UInt256)
    reinterpret(UInt256, reinterpret(UInt8, UInt256[x])[end:-1:1])[1]
end

function Base.zero(x::UInt256)
    reinterpret(UInt256, zeros(UInt8, 32))[1]
end

function Base.zero(::Type{UInt256})
    reinterpret(UInt256, zeros(UInt8, 32))[1]
end


# this one takes ~ 2x as long
# function Base.bswap(x::UInt256)
#     convert(UInt256, convert(NTuple{32, UInt8}, x)[end:-1:1])
# end

# TODO: this is probably not good:
Base.hash(x::UInt256, h::UInt) = Base.hash(x % UInt64, h)
Base.hash(x::UInt256) = Base.hash(x, zero(UInt))

# Base.rem(x::UInt256, ::Type{T}) where T = reinterpret(T,  Int256[x])[1]
function Base.rem(x::UInt256, ::Type{T}) where T
    Ref(x) |>
        pointer_from_objref |>
        x -> convert(Ptr{T}, x) |>
        unsafe_load
end

function UInt256(x::AbstractString)
    n = length(x)
    @assert n <= 64
    if n <= 32
        to_unsigned(UInt256, (Base.parse(UInt128, x, 16), zero(UInt128)))
    else
        to_unsigned(UInt256,
                    (Base.parse(UInt128, String(x[end - 31:end]),      16),
                     Base.parse(UInt128, String(x[       1:end - 32]), 16)) )
    end
end
=#
end # module
