module InferenceUtilities
using Base.Test

export @isinferred_noneval, @isinferred, @return_types

"""
    @isinferred_noneval f(x)

Checks whether the call expression `f(x)` is type stable without evaluating `f`
(but it does evaluate the argument(s) x) and returns a boolean value.
`@isinferred` is similar to `@inferred`, but does not evaluate `f` and returns
a boolean rather than throwing an exception. It also does not capture some
corner cases that `@inferred` (and hence `@isinferred`, which is built on
`@inferred`, captures).
This macro is useful for unit tests (`@test @isinferred_noneval f(x)`).

`f(x)` can be any call expression.

```jldoctest
julia> using Base.Test

julia> f(a,b,c) = b > 1 ? 1 : 1.0
f (generic function with 1 method)

julia> @code_warntype f(1,2,3)
Variables:
  #self#::#f
  a::Int64
  b::Int64
  c::Int64

Body:
  begin
      unless (Base.slt_int)(1, b::Int64)::Bool goto 3
      return 1
      3:
      return 1.0
  end::UNION{FLOAT64, INT64}

julia> @isinferred_noneval f(1,2,3)
false

julia> @isinferred_noneval max(1,2)
false
```
"""
macro isinferred_noneval(ex)
    if Meta.isexpr(ex, :ref)
        ex = Expr(:call, :getindex, ex.args...)
    end
    Meta.isexpr(ex, :call)|| error("@inferred requires a call expression")

    quote
        let
            args = ($([esc(ex.args[i]) for i = 2:length(ex.args)]...),)
            inftypes = Base.return_types($(esc(ex.args[1])), Base.typesof(args...))
            length(inftypes) == 1 && isleaftype(first(inftypes))
        end
    end
end

"""
    @isinferred f(x)
Checks whether the call expression `f(x)` is type stable and returns a
boolean value. `@isinferred` is similar to `@inferred`,
but returns a boolean rather than throwing an exception.
This macro is useful for unit tests (`@test @isinferred f(x)`).
`f(x)` can be any call expression.
```jldoctest
julia> using Base.Test
julia> f(a,b,c) = b > 1 ? 1 : 1.0
f (generic function with 1 method)
julia> @code_warntype f(1,2,3)
Variables:
  #self#::#f
  a::Int64
  b::Int64
  c::Int64
Body:
  begin
      unless (Base.slt_int)(1, b::Int64)::Bool goto 3
      return 1
      3:
      return 1.0
  end::UNION{FLOAT64, INT64}
julia> @isinferred f(1,2,3)
false
julia> @isinferred max(1,2)
false
```
"""
macro isinferred(ex)
    quote
        try
            @inferred $(esc(ex))
            true
        catch err
            isa(err, ErrorException) ? false : rethrow(err)
            false
        end
    end
end

"""
  @return_types f(x)

  Evaluates arguments `x` and returns the inferred return type of `f(x)` without
  evaluating `f(x)`

```jldoctests
julia> f(a,b,c) = b > 1 ? 1 : 1.0
f (generic function with 1 method)

julia> @return_types f(1,2,3)
1-element Array{Any,1}:
 Union{Float64, Int64}
```
"""
macro return_types(ex)
    f = ex.args[1]
    f_args = [:(typeof($i)) for i in ex.args[2:end]]
    :(Base.return_types($(esc(f)), Base.typesof($(f_args...))))
end
end # module
