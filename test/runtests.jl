using InferenceUtilities
using Base.Test

# tests copied from pull request
# https://github.com/JuliaLang/julia/pull/23426

# test @inferred and @isinferred
function uninferrable_function(i)
    q = [1, "1"]
    return q[i]
end

@test_throws ErrorException @inferred(uninferrable_function(1))
@test @inferred(identity(1)) == 1
@test !@isinferred(uninferrable_function(1))
@test @isinferred(identity(1))


# Ensure @inferred and @isinferred only evaluate the arguments once
inferred_test_global = 0
function inferred_test_function()
    global inferred_test_global
    inferred_test_global += 1
    true
end
@test @inferred inferred_test_function()
@test inferred_test_global == 1

inferred_test_global = 0
@test @isinferred inferred_test_function()
@test inferred_test_global == 1

# Test that @inferred and @isinferred work with A[i] expressions
@test @inferred((1:3)[2]) == 2
@test @isinferred((1:3)[2])
struct SillyArray <: AbstractArray{Float64,1} end
Base.getindex(a::SillyArray, i) = rand() > 0.5 ? 0 : false
test_result = @test_throws ErrorException @inferred(SillyArray()[2])
@test contains(test_result.value.msg, "Bool")
@test !@isinferred(SillyArray()[2])

# Issue #14928
# Make sure abstract error type works.
@test_throws Exception error("")

# Issue #17105
# @inferred and @isinferred with kwargs
function inferrable_kwtest(x; y=1)
    2x
end
function uninferrable_kwtest(x; y=1)
    2x+y
end
@test @inferred(inferrable_kwtest(1)) == 2
@test @inferred(inferrable_kwtest(1; y=1)) == 2
@test @inferred(uninferrable_kwtest(1)) == 3
@test_throws ErrorException @inferred(uninferrable_kwtest(1; y=2)) == 2
@test @isinferred(inferrable_kwtest(1))
@test @isinferred(inferrable_kwtest(1; y=1))
@test @isinferred(uninferrable_kwtest(1))
@test !@isinferred(uninferrable_kwtest(1; y=2))
