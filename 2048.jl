@everywhere typealias Board Array{Int8, 2}

function create_board()
    return zeros(Int8, 4, 4)
end

@everywhere function insert_board_rand(board::Board, rng)
    idxs = findin(board, 0)
    if length(idxs) == 0
        return false
    end
    idx = rand(rng, idxs)

    # I read this off a spec for the game, I haven't checked if it's correct
    board[idx] = rand() < 0.9 ? 1 : 2
    return true
end

@everywhere function score_board(board::Board)
    return length(findin(board, 0))
end

@everywhere function shift_row{X,Y}(row::SubArray{Int8, 1, Board, X, Y})
    a, b, c, d = row

    # This may appear naive. However, it's the simplest possible implementation
    # that executes with the minimal number of operations per shift.

    if a == 0 # 0 ? ? ?
        if b == 0 # 0 0 ? ?
            if c == 0 # 0 0 0 ?
                if d == 0 # 0 0 0 0
                    return false
                else
                    a = d
                    d = 0
                end
            else # 0 0 c ?
                if c == d # 0 0 c c
                    a = c + 1
                    c = 0
                    d = 0
                else # 0 0 c d
                    a = c
                    b = d
                    c = 0
                    d = 0
                end
            end
        else # 0 b ? ?
            if c == 0 # 0 b 0 ?
                if b == d # 0 b 0 b
                    a = b + 1
                    b = 0
                    d = 0
                else # 0 b 0 d
                    a = b
                    b = d
                    d = 0
                end
            elseif b == c  # 0 b b ?
                a = b + 1
                b = d
                c = 0
                d = 0
            else # 0 b c ?
                if c == d # 0 b c c
                    a = b
                    b = c + 1
                    c = 0
                    d = 0
                else # 0 b c d
                    a = b
                    b = c
                    c = d
                    d = 0
                end
            end
        end
    else # a ? ? ?
        if b == 0 # a 0 ? ?
            if c == 0 # a 0 0 ?
                if d == 0 # a 0 0 0
                    return false
                elseif d == a # a 0 0 a
                    a += 1
                    d = 0
                else  # a 0 0 d
                    b = d
                    d = 0
                end
            elseif c == a # a 0 a ?
                a += 1
                b = d
                c = 0
                d = 0
            else # a 0 c ?
                if c == d # a 0 c c
                    b = c + 1
                    c = 0
                    d = 0
                else # a 0 c d
                    b = c
                    c = d
                    d = 0
                end
            end
        elseif a == b # a a ? ?
            if c == 0 # a a 0 ?
                a += 1
                b = d
                d = 0
            else # a a b ?
                if c == d # a a c c
                    a += 1
                    b = c + 1
                    c = 0
                    d = 0
                else # a a c d
                    a += 1
                    b = c
                    c = d
                    d = 0
                end
            end
        else # a b ? ?
            if c == 0 # a b 0 ?
                if d == 0 # a b 0 0
                    return false
                elseif d == b # a b 0 b
                    b += 1
                    d = 0
                else # a b 0 d
                    c = d
                    d = 0
                end
            elseif c == b # a b b ?
                b += 1
                c = d
                d = 0
            else # a b c ?
                if d == c # a b c c
                    c += 1
                    d = 0
                else # a b c d
                    return false
                end
            end
        end
    end

    @inbounds row[1], row[2], row[3], row[4] = a, b, c, d
    return true
end

@everywhere function shift_board_up(board::Board)
    return (shift_row(slice(board, :, 1)) |
            shift_row(slice(board, :, 2)) |
            shift_row(slice(board, :, 3)) |
            shift_row(slice(board, :, 4)))
end

@everywhere function shift_board_down(board::Board)
    return (shift_row(slice(board, 4:-1:1, 1)) |
            shift_row(slice(board, 4:-1:1, 2)) |
            shift_row(slice(board, 4:-1:1, 3)) |
            shift_row(slice(board, 4:-1:1, 4)))
end

@everywhere function shift_board_left(board::Board)
    return (shift_row(slice(board, 1, :)) |
            shift_row(slice(board, 2, :)) |
            shift_row(slice(board, 3, :)) |
            shift_row(slice(board, 4, :)))
end

@everywhere function shift_board_right(board::Board)
    return (shift_row(slice(board, 1, 4:-1:1)) |
            shift_row(slice(board, 2, 4:-1:1)) |
            shift_row(slice(board, 3, 4:-1:1)) |
            shift_row(slice(board, 4, 4:-1:1)))
end

@everywhere function display_board(board::Board)
    print("\n")
    for j = 1:size(board,2)
        print("  ")
        for i = 1:size(board,1)
            print(rpad(string(board[i,j]),3," "))
        end
        print("\n")
    end
    print("\n")
end

@everywhere function play_rand(board_copy, n, rng)
    board = deepcopy(board_copy)
    changed = true
    for _ in 1:n
        if changed
            if !insert_board_rand(board, rng)
                return 0
            end
        end
        changed = false
        ipt = rand(rng, 1:4)

        if ipt == 1
            changed = shift_board_down(board)
        elseif ipt == 2
            changed = shift_board_up(board)
        elseif ipt == 3
            changed = shift_board_left(board)
        elseif ipt== 4
            changed = shift_board_right(board)
        end
    end
    return score_board(board)
end

@everywhere function appraise_move(board_copy, move, rng)
    board = deepcopy(board_copy)
    legal = move(board)
    if !legal
        return 0
    end
    n_iters = 100000
    total_score = @parallel (+) for _ in 1:n_iters
        play_rand(board, 50, rng)
    end
    return total_score/n_iters
end

function main()
    board = create_board()
    changed = true
    n = 0
    total_time = 0
    rng = MersenneTwister()
    while true
        if changed
            if !insert_board_rand(board, rng)
                println("Game end!")
                break
            end
        end
        tic()
        u = appraise_move(board, shift_board_up, rng)
        d = appraise_move(board, shift_board_down, rng)
        l = appraise_move(board, shift_board_left, rng)
        r = appraise_move(board, shift_board_right, rng)
        n += 1

        run(@unix ? `clear` : `cmd /c cls`)

        display_board(board)
        @printf("n:%d ", n)
        @printf("s:%f ", max(u, d, l, r))
        time = toq()
        total_time += time
        @printf("Δt:%f ", time)
        @printf("μₜ:%f\n", total_time/n)

        changed = false
        if max(u, d, l, r) == 0
            println("Game over!")
            return
        end

        if d == max(u, d, l, r)
            changed = shift_board_down(board)
        elseif u == max(u, d, l, r)
            changed = shift_board_up(board)
        elseif l == max(u, d, l, r)
            changed = shift_board_left(board)
        elseif r == max(u, d, l, r)
            changed = shift_board_right(board)
        # elseif ipt == "p\n"
        #     println(appraise_move(board, identity))
        else
            println("invalid move!")
        end
    end
end

function main_interactive()
    board = create_board()
    changed = true
    n = 1
    rng = MersenneTwister()
    while true
        if changed
            if !insert_board_rand(board, rng)
                println("Game end!")
                break
            end
            n += 1
        end

        changed = false
        display_board(board)
        write(STDIN, "> ")
        ipt = strip(readline(STDIN))
        if ipt == "d"
            changed = shift_board_down(board)
        elseif ipt == "u"
            changed = shift_board_up(board)
        elseif ipt == "l"
            changed = shift_board_left(board)
        elseif ipt == "r"
            changed = shift_board_right(board)
            # elseif ipt == "p\n"
            #     println(appraise_move(board, identity))
        else
            println("invalid move!")
        end

        if !changed
            println("NOP!")
        end
    end
end

main()
