@everywhere typealias Board Array{Int8, 2}

function create_board()
    return zeros(Int8, 4, 4)
end

@everywhere function insert_board_rand(board::Board)
    idxs = findin(board, 0)
    if length(idxs) == 0
        return false
    end
    idx = rand(idxs)

    # I read this off a spec for the game, I haven't checked if it's correct
    board[idx] = rand() < 0.9 ? 1 : 2
    return true
end

@everywhere function score_board(board::Board)
    return length(findin(board, 0))
end

@everywhere function shift_row{X,Y}(row::SubArray{Int8, 1, Board, X, Y})
    a, b, c, d = row

    if c == 0
        c = d
        d = 0
    end

    if b == 0
        b = c
        c = d
        d = 0
    end

    if a == 0
        a = b
        b = c
        c = d
        d = 0
    end

    if a == b != 0
        if c == d != 0
            a, b, c, d = a+1, c+1, 0, 0
        else
            a, b, c, d = a+1, c, d, 0
        end
    else
        if b == c != 0
            a, b, c, d = a, b+1, d, 0
        else
            if c == d != 0
                a, b, c, d = a, b, c+1, d
            end
        end
    end

    if row[1] != a
        row[1], row[2], row[3], row[4] = a, b, c, d
        return true

    elseif row[2] != b
        row[2], row[3], row[4] = b, c, d
        return true

    elseif row[3] != c
        row[3], row[4] = c, d
        return true

    elseif row[4] != d
        row[4] == d
        return true
    end

    return false
end

@everywhere function shift_board_up(board::Board)
    changed = false
    for col in 1:4
        changed |= shift_row(slice(board, :, col))
    end
    return changed
end

@everywhere function shift_board_down(board::Board)
    changed = false
    for col in 1:4
        changed |= shift_row(slice(board, 4:-1:1, col))
    end
    return changed
end

@everywhere function shift_board_left(board::Board)
    changed = false
    for row in 1:4
        changed |= shift_row(slice(board, row, :))
    end
    return changed
end

@everywhere function shift_board_right(board::Board)
    changed = false
    for row in 1:4
        changed |= shift_row(slice(board, row, 4:-1:1))
    end
    return changed
end

@everywhere function display_board(board::Board)
    println(board)
end

@everywhere function play_rand(board_copy, n)
    board = deepcopy(board_copy)
    insert_board_randboard
    changed = true
    for _ in 1:n
        if changed
            if !insert_board_rand(board)
                return score_board(board)
                break
            end
        end
        changed = false
        ipt = rand(1:4)

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

@everywhere function appraise_move(board_copy, move)
    board = deepcopy(board_copy)
    legal = move(board)
    if !legal
        return 0
    end
    n_iters = 100000
    total_score = @parallel (+) for _ in 1:n_iters
        play_rand(board, 50)
    end
    return total_score/n_iters
end

function main()
    board = create_board()
    changed = true
    n = 1
    while true
        if changed
            if !insert_board_rand(board)
                println("Game end!")
                break
            end
            n += 1
        end
        tic()
        u = appraise_move(board, shift_board_up)
        d = appraise_move(board, shift_board_down)
        l = appraise_move(board, shift_board_left)
        r = appraise_move(board, shift_board_right)

        display_board(board)
        @printf("u:%f ", u)
        @printf("d:%f ", d)
        @printf("l:%f ", l)
        @printf("r:%f\n", r)
        @printf("n:%d ", n)
        @printf("t:%f\n", toq())

        changed = false
        # ipt = readline(STDIN)
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

main()
