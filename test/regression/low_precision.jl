@testset "low_precision.jl" begin
    Random.seed!(5)

    n, m = 10^3, 5
    features = Array{Any}(undef, n, m)
    features[:, :] = randn(StableRNG(1), n, m)
    features[:, 1] = round.(Int32, features[:, 1])
    weights = rand(StableRNG(1), -2:2, m)
    labels = float.(features * weights)

    min_samples_leaf = Int32(1)
    n_subfeatures = Int32(0)
    max_depth = Int32(-1)
    min_samples_split = Int32(2)
    min_purity_increase = 0.5
    model = build_tree(
        labels,
        round.(Int32, features),
        n_subfeatures,
        max_depth,
        min_samples_leaf,
        min_samples_split,
        min_purity_increase;
        rng=StableRNG(1),
    )
    preds = apply_tree(model, round.(Int32, features))
    @test R2(labels, preds) < 0.95
    @test typeof(preds) <: Vector{Float64}

    n_subfeatures = Int32(3)
    n_trees = Int32(10)
    partial_sampling = 0.7
    max_depth = Int32(-1)
    min_samples_leaf = Int32(5)
    min_samples_split = Int32(2)
    min_purity_increase = 0.0
    model = build_forest(
        labels,
        features,
        n_subfeatures,
        n_trees,
        partial_sampling,
        max_depth,
        min_samples_leaf,
        min_samples_split,
        min_purity_increase;
        rng=StableRNG(1),
    )
    preds = apply_forest(model, features)
    @test R2(labels, preds) > 0.9
    @test typeof(preds) <: Vector{Float64}

    preds_MT = apply_forest(model, features; use_multithreading=true)
    @test R2(labels, preds_MT) > 0.9
    @test typeof(preds_MT) <: Vector{Float64}
    @test sum(abs.(preds .- preds_MT)) < 1.0e-8

    println("\n##### nfoldCV Regression Tree #####")
    n_folds = Int32(3)
    pruning_purity = 1.0
    max_depth = Int32(-1)
    min_samples_leaf = Int32(5)
    min_samples_split = Int32(2)
    min_purity_increase = 0.0
    r2 = nfoldCV_tree(
        labels,
        features,
        n_folds,
        pruning_purity,
        max_depth,
        min_samples_leaf,
        min_samples_split,
        min_purity_increase;
        rng=StableRNG(1),
    )
    @test mean(r2) > 0.6

    println("\n##### nfoldCV Regression Forest #####")
    n_trees = Int32(10)
    n_subfeatures = Int32(2)
    n_folds = Int32(3)
    max_depth = Int32(-1)
    min_samples_leaf = Int32(5)
    min_samples_split = Int32(2)
    min_purity_increase = 0.0
    r2 = nfoldCV_forest(
        labels,
        features,
        n_folds,
        n_subfeatures,
        n_trees,
        partial_sampling,
        max_depth,
        min_samples_leaf,
        min_samples_split,
        min_purity_increase;
        rng=StableRNG(1),
    )
    @test mean(r2) > 0.8

    # Test Float16 labels, and Float16 features
    features = Float16.(features)
    labels = Float16.(labels)

    model = build_stump(labels, features)
    preds = apply_tree(model, features)
    @test typeof(preds) == Vector{Float16}

    model = build_tree(labels, features)
    preds = apply_tree(model, features)
    @test typeof(preds) == Vector{Float16}

    model = build_forest(labels, features)
    preds = apply_forest(model, features)
    @test typeof(preds) == Vector{Float16}

    preds_MT = apply_forest(model, features; use_multithreading=true)
    @test typeof(preds_MT) == Vector{Float16}
    @test sum(abs.(preds .- preds_MT)) < 1.0e-8

    model = build_tree(labels, features)
    preds = apply_tree(model, features)
    @test typeof(preds) == Vector{Float16}
end # @testset
