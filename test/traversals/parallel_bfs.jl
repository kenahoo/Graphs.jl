import LightGraphs: LevelSynchronousBFS, bfs_tree
import Base.Threads: Atomic, @threads

@testset "Parallel_BFS" begin

    @testset "Thread Queue " begin
        next = @inferred(LightGraphs.ThreadQueue(Int, 5)) # Initialize threadqueue
        @test isempty(next) == true
        push!(next, 1)
        @test next[1][] == 1
        @threads for i = 2:5
            push!(next, i)
        end
        @test Set([i[] for i in next[1:5]]) == Set([1, 2, 3, 4, 5])
        first = shift!(next)
        @test first == 1
    end

    g5 = DiGraph(4)
    add_edge!(g5, 1, 2); add_edge!(g5, 2, 3); add_edge!(g5, 1, 3); add_edge!(g5, 3, 4)
    g6 = smallgraph(:house)

    for g in testdigraphs(g5)
      T = eltype(g)
      z = @inferred(bfs_tree(LevelSynchronousBFS(), g, T(1)))
      next = LightGraphs.ThreadQueue(T, nv(g)) # Initialize threadqueue
      parents = [Atomic{T}(0) for i = 1:nv(g)] # Create parents array
      LightGraphs.bfs_tree!(LevelSynchronousBFS(), next, g, T(1), parents)
      t = [i[] for i in parents]
      @test t == [T(1), T(1), T(1), T(3)]
      @test nv(z) == T(4) && ne(z) == T(3) && !has_edge(z, 2, 3)
    end

    function istree{T<:Integer}(parents::Vector{Atomic{T}}, maxdepth, n::T)
        flag = true
        for i in one(T):n
            s = i
            depth = 0
            while parents[s][] > 0 && parents[s][] != s
                s = parents[s][]
                depth += 1
                if depth > maxdepth
                    return false
                end
            end
        end
        return flag
    end

    for g in testgraphs(g6)
        n = nv(g)
        T = eltype(g)
        next = LightGraphs.ThreadQueue(eltype(g), nv(g)) # Initialize threadqueue
        parents = [Atomic{T}(0) for i = 1:nv(g)] # Create parents array
        @test length(next.data) == n
        @inferred(LightGraphs.bfs_tree!(LevelSynchronousBFS(), next, g, T(1), parents))
        @test istree(parents, n, n)
        p = [i[] for i in parents]
        t = tree(p)
        @test is_directed(t)
        @test typeof(t) <: AbstractGraph
        @test ne(t) < nv(t)
    end

end
