using Revise
using Test
using UArrayInts
using BenchmarkTools


@btime UArrayInts.add_carry($(0xff), $(0xff))
@btime 0x00ff + 0x00ff

@btime UArrayInts.add!($([0xff, 0xff]), $([0xff, 0xff]))
@btime $(0xffff) + $(0xffff)
@btime UArrayInts.add!($([0xff, 0xff]), $([0xff, 0xff]), 1)
@btime UArrayInts.add!($([0xffff, 0xffff]), $([0xffff, 0xffff]))
@btime $(0xffffffff) + $(0xffffffff)
@btime UArrayInts.add!($([0xffff]), $([0xffff, 0xffff]))
@btime (0x00000000000ffff + 0x0000000ffffffff) % UInt16


UArrayInts.mul!([0xffff, 0xffff], 0xffff)

@btime UArrayInts.mul!($([0xffff, 0xffff]), $(0xffff))
@code_warntype UArrayInts.mul!(Array{UInt8}(undef, 2), [0xff, 0xff], [0xff, 0xff])
@code_llvm UArrayInts.mul!(Array{UInt8}(undef, 2), [0xff, 0xff], [0xff, 0xff])
0xffffffff * 0xffff
@btime UArrayInts.mul!($(Array{UInt8}(undef, 2)), $([0xff, 0xff]), $([0xff, 0xff]))
0xffff * 0xffff
@btime $(0xffff) * $(0xffff)
@btime UArrayInts.mul!($([0xffff, 0xffff]), $([0xffff, 0xffff]))
@btime $(0xffffffff) * $(0xffffffff)
@btime UArrayInts.mul!($([0xffff]), $([0xffff, 0xffff]))
@btime (0x00000000000ffff * 0x0000000ffffffff) % UInt16

function test_add_carry(x::T, y::T) where T
    tmp = UArrayInts.add_carry(x, y)
    tmp[1] + (T(1) << (sizeof(T) * 8)) * tmp[2] == x + y
end
@test test_add_carry(0xff, 0xff)
@test test_add_carry(0xffff, 0xffff)
@test test_add_carry(0xffffffff, 0xffffffff)
@test test_add_carry(0xffffffffffffffff, 0xffffffffffffffff)
@test test_add_carry(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff)
@test test_add_carry(0x0f, 0x0f)
@test test_add_carry(0x000f, 0x000f)
@test test_add_carry(0x0000000f, 0x0000000f)
@test test_add_carry(0x000000000000000f, 0x000000000000000f)
@test test_add_carry(0x0000000000000000000000000000000f, 0x0000000000000000000000000000000f)
@test UArrayInts.to_unsigned(UArrayInts.add!(([0xff, 0xff]), ([0xff, 0xff]), 1)) == 0xffff + 0xff00

function test_add(x::Vector{T}, y::Vector{T}) where T
    x2 = deepcopy(x)
    UArrayInts.add!(x, y)
    tmp1 = UArrayInts.to_unsigned(x)
    tmp2 = (UArrayInts.to_unsigned(x2) + UArrayInts.to_unsigned(y)) % typeof(tmp1)
    @show tmp1
    @show tmp2
    tmp1 == tmp2
end

@test test_add([0xff], [0xff])
@test test_add([0xff, 0xff], [0xff])
@test test_add([0xff, 0xff], [0xff, 0xff, 0xff])


@test UArrayInts.to_unsigned([0x04, 0x03, 0x02, 0x01], Val(4)) == 0x04030201
@test UArrayInts.to_unsigned([0x0004, 0x0003, 0x0002, 0x0001], Val(4)) == 0x0004000300020001
tmp1 = UArrayInts.to_unsigned([0x00000004, 0x00000003, 0x00000002, 0x00000001], Val(4))
tmp2 = 0x00000004000000030000000200000001
@test tmp1 == tmp2
@test UArrayInts.to_unsigned([0x03, 0x02, 0x01], Val(3)) == 0x00030201
