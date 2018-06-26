using Test
using UArrayInts

@testset "array funs" begin

    tmp1 = [0xff, 0xfe]
    tmp2 = UArrayInt(tmp1)
    @test tmp1[1] == tmp2[1]
    @test tmp1[end] == tmp2[end]
    @test length(tmp1) == length(tmp2)

    tmp2[1] = 0x00
    @test tmp2[1] == 0x00

end

@testset "add_carry" begin
    function test_add_carry(x::T, y::T) where T
        tmp = add_carry(x, y)
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
end


@testset "add" begin
    function inner_test_add(x, y)
        x2 = deepcopy(x)
        add!(x, y)
        tmp1 = to_unsigned(x)
        tmp2 = (to_unsigned(x2) + to_unsigned(y)) % typeof(tmp1)
        tmp1 == tmp2
    end
    function test_add(::Type{T}) where T
        a = UArrayInt
        z = zero(T)
        o = one(T)
        m = typemax(T)

        @test inner_test_add([m], [m])
        sizeof(T) < 16 && @test inner_test_add([m, m], [m])
        sizeof(T) < 8  && @test inner_test_add([m, m], [m, m, m])
        @test inner_test_add([o], [o])
        sizeof(T) < 16 && @test inner_test_add([z, o], [o])
        sizeof(T) < 8  && @test inner_test_add([z, o], [z, z, o])

        @test inner_test_add(a([m]), a([m]))
        sizeof(T) < 16 && @test inner_test_add(a([m, m]), a([m]))
        sizeof(T) < 8  && @test inner_test_add(a([m, m]), a([m, m, m]))
        @test inner_test_add(a([o]), a([o]))
        sizeof(T) < 16 && @test inner_test_add(a([z, o]), a([o]))
        sizeof(T) < 8  && @test inner_test_add(a([z, o]), a([z, z, o]))

        return nothing
    end

    test_add(UInt8)
    test_add(UInt16)
    test_add(UInt32)
    test_add(UInt64)

end

@testset "mul_carry" begin function test_mul_carry(x::T, y::T) where T
        tmp = mul_carry(x, y)
        tmp[1] + (T(1) << (sizeof(T) * 8)) * tmp[2] == x * y
    end
    @test test_mul_carry(0xff, 0xff)
    @test test_mul_carry(0xffff, 0xffff)
    @test test_mul_carry(0xffffffff, 0xffffffff)
    @test test_mul_carry(0xffffffffffffffff, 0xffffffffffffffff)
    @test_throws ErrorException test_mul_carry(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff)
    @test test_mul_carry(0x0f, 0x0f)
    @test test_mul_carry(0x000f, 0x000f)
    @test test_mul_carry(0x0000000f, 0x0000000f)
    @test test_mul_carry(0x000000000000000f, 0x000000000000000f)
    @test_throws ErrorException test_mul_carry(0x0000000000000000000000000000000f, 0x0000000000000000000000000000000f)
end


@testset "mul" begin
    function inner_test_mul(x, y)
        x2 = deepcopy(x)
        mul!(x2, x, y)
        tmp1 = to_unsigned(x2)
        tmp2 = (to_unsigned(x) * to_unsigned(y)) % typeof(tmp1)
        tmp1 == tmp2
    end
    function test_mul(::Type{T}) where T
        a = UArrayInt
        z = zero(T)
        o = one(T)
        m = typemax(T)

        @test inner_test_mul([m], [m])
        sizeof(T) < 16 && @test inner_test_mul([m, m], [m])
        sizeof(T) < 8  && @test inner_test_mul([m, m], [m, m, m])
        @test inner_test_mul([o], [o])
        sizeof(T) < 16 && @test inner_test_mul([z, o], [o])
        sizeof(T) < 8  && @test inner_test_mul([z, o], [z, z, o])

        @test inner_test_mul(a([m]), a([m]))
        sizeof(T) < 16 && @test inner_test_mul(a([m, m]), a([m]))
        sizeof(T) < 8  && @test inner_test_mul(a([m, m]), a([m, m, m]))
        @test inner_test_mul(a([o]), a([o]))
        sizeof(T) < 16 && @test inner_test_mul(a([z, o]), a([o]))
        sizeof(T) < 8  && @test inner_test_mul(a([z, o]), a([z, z, o]))

        return nothing
    end

    test_mul(UInt8)
    test_mul(UInt16)
    test_mul(UInt32)
    test_mul(UInt64)

end

@testset "to_unsigned" begin
    @test to_unsigned([0x04, 0x03, 0x02, 0x01], Val(4)) == 0x04030201
    @test to_unsigned([0x0004, 0x0003, 0x0002, 0x0001], Val(4)) == 0x0004000300020001
    tmp1 = to_unsigned([0x00000004, 0x00000003, 0x00000002, 0x00000001], Val(4))
    tmp2 = 0x00000004000000030000000200000001
    @test tmp1 == tmp2
    @test to_unsigned([0x03, 0x02, 0x01], Val(3)) == 0x00030201
end
