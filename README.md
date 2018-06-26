# Ripemd

[![Build Status](https://travis-ci.org/gdkrmr/UArrayInts.jl.svg?branch=master)](https://travis-ci.org/gdkrmr/UArrayInts.jl)
[![codecov.io](http://codecov.io/github/gdkrmr/UArrayInts.jl/coverage.svg?branch=master)](http://codecov.io/github/gdkrmr/UArrayInts.jl?branch=master)

```julia
julia> using UArrayInts

julia> add!(UArrayInt([0x00, 0xff]), UArrayInt([0x01]))

julia> mul!(UArrayInt(Array{UInt8}(undef, 2)), UArrayInt([0xff, 0xff]), UArrayInt([0xff]))
```

Currently only addition and multiplication is implemented, but the plan is to
implement all the stuff for unsigned types.
