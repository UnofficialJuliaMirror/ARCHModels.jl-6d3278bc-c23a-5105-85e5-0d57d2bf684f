using Base.Test

using ARCH
T = 10^4;
spec = GARCH{1, 1}([1., .9, .05])
srand(1);
data = simulate(spec, T; meanspec=NoIntercept());
srand(1);
datat = simulate(spec, T; dist=StdTDist(4), meanspec=NoIntercept())
srand(1);
datam = simulate(spec, T; dist=StdTDist(4), meanspec=Intercept(3))
ht = zeros(data);
am = selectmodel(GARCH, data; dist=StdNormal, meanspec=NoIntercept)
am2 = ARCHModel(spec, data)
fit!(am2)
am3 = fit(am2)
am4 = selectmodel(GARCH, datat; dist=StdTDist, meanspec=NoIntercept)
am5 = selectmodel(GARCH, datam; dist=StdTDist, meanspec=Intercept)
am6 = fit(GARCH{1, 1}, data)

@test loglikelihood(ARCHModel(spec, data)) ==  ARCH.loglik!(ht,
                                                            typeof(spec),
                                                            StdNormal{Float64},
                                                            NoIntercept{Float64},
                                                            data,
                                                            spec.coefs
                                                            )

@test nobs(am) == T
@test dof(am) == 3
@test coefnames(GARCH{1, 1}) == ["ω", "β₁", "α₁"]
@test coefnames(am5) == ["ω", "β₁", "α₁", "ν", "μ"]
@test all(coeftable(am4).cols[2] .== stderror(am4))

@test all(isapprox.(coef(am), [0.9086850084210619,
                               0.9055267307122488,
                               0.050365843108442374
                               ], rtol=1e-4))

@test all(isapprox.(stderror(am), [0.14583357347889914,
                                   0.01035533071207874,
                                   0.005222909457230848], rtol=1e-4))

@test all(am2.spec.coefs .== am.spec.coefs)
@test all(am3.spec.coefs .== am2.spec.coefs)
@test all(isapprox(coef(am4), [0.8306902920885605,
                               0.9189514425541352,
                               0.04207946140844637,
                               3.8356660627658075], rtol=1e-4))

@test all(isapprox(coef(am5), [0.8306060010899426,
                               0.9189549832561451,
                               0.04208828412801287,
                               3.834870661953542,
                                2.991845199038339], rtol=1e-4))

@test all(isapprox(coef(am6), [0.910518085511129,
                               0.9054119432933296,
                               0.050389241671739915,
                               0.027704786149577398], rtol=1e-4))

@test_warn "Fisher" stderror(ARCHModel(GARCH{3, 0}([.1, .0, .0, .0]), data))
@test_warn "negative" stderror(ARCHModel(GARCH{3, 0}([1., .1, .2, .3]), data[1:10]))
e = @test_throws ARCH.NumParamError ARCH.loglik!(ht, typeof(spec), StdNormal{Float64},
                                                 NoIntercept{Float64}, data,
                                                 [0., 0., 0., 0.]
                                                 )
str = sprint(showerror, e.value)
@test startswith(str, "incorrect number of parameters")
@test_throws ARCH.NumParamError GARCH{1, 1}([.1])
e = @test_throws ARCH.LengthMismatchError ARCHModel(spec, data, ht[1:10])
str = sprint(showerror, e.value)
@test startswith(str, "length of arrays does not match")
io = IOBuffer()
str = sprint(io -> show(io, am))
@test startswith(str, "\nGARCH{1,1")
@test selectmodel(ARCH._ARCH, data).spec.coefs == fit(ARCH._ARCH{3}, data).spec.coefs
@test typeof(StdNormal())==typeof(StdNormal(Float64[]))
@test fit(StdNormal, data).coefs == Float64[]
@test coefnames(StdNormal) == String[]
@test ARCH.distname(StdNormal) == "Gaussian"
srand(1)
data = rand(StdTDist(4), 10000)
@test fit(StdTDist, data).coefs[1] ≈ 3.972437329588246 rtol=1e-4
@test coefnames(StdTDist) == ["ν"]
@test ARCH.distname(StdTDist) == "Student's t"