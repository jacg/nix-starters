using Test
@testset "trivial stuff" begin
    @test 2 + 2 == 4
    @test π ≈ 3.15 atol = 0.01
end
