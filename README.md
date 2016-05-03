`2048.jl`
=========

This is an implementation of the popular online game [2048](https://gabrielecirulli.github.io/2048/) with an accompanying solver written in [`julia`](https://github.com/JuliaLang/julia). To my knowledge, most existing solvers for 2048 are written in JavaScript. A Julia solver should be able to solve higher efficiency with equivalent performance.

Right now, the solver implements Pure Monte Carlo Tree Search, which is capable of regularly achieving a 2048 tile, but rarely beyond that. More advanced techniques are planned.

I wrote this to re-familiarize myself with Julia and its conventions. So far, it's been very pleasant. :)
