# InferenceUtilities

Provides utility macros for inferences. `@isinferred f(x)` does the same as `@inferred f(x)`, but returns a boolean rather than throwing an exception. `@isinferred_noneval f(x)` checks whether `f` is type stable without evaluating it. It does evaluate the arguments though. `@return_types f(x, y)` with `x::T` and `y::S` is equivalent to `Base.return_types(f, (T,S))`.

Usage:
```julia
Pkg.clone("https://github.com/afniedermayer/InferenceUtilities.jl")
f(a,b,c) = b>0 ? 1 : 1.0
@isinferred f(1,2,3)
@isinferred_noneval f(1,2,3)
@return_types f(1,2,3)
```
