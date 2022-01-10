def min_by [n] 'a (f: a -> u64) (default: a) (as: [n]a): a =
  let reduce_second (x: (a, u64)) (y: (a, u64)) =
    let (xe, xs) = x
    let (ye, ys) = y
    in if xs < ys then x else y
  let (elem, score) = as |> map (\x -> (x, f x)) |> reduce reduce_second (default, u64.highest)
  in elem

def count p xs =
  u64.sum (map (p >-> u64.bool) xs)

type color = #green | #yellow | #grey

type guess_result [w] = {
  guess: [w]u8,
  colors: [w]color
}

let guess_against [w] (target: [w]u8) (guess: [w]u8): guess_result [w] =
  let green_grey_initial: [w]color = map2 (\x -> \y -> if x == y then #green else #grey) target guess
  in {guess = guess, colors = green_grey_initial}

let is_possible [w] (res: guess_result [w]) (check: [w]u8): bool =
  let all_greens: bool = map3 (\rg -> \rc -> \ch -> if rc == #green then ch == rg else true) res.guess res.colors check |> all id
  let no_greys: bool = map2 (\rg -> \rc -> if rc == #grey then all (\ch -> ch != rg) check else true) res.guess res.colors |> all id
  in all_greens && no_greys

let score_of_guess [w] [p] (possibles: [p][w]u8) (guess: [w]u8): u64 =
  possibles |> map (\possibility -> count (is_possible (guess_against possibility guess)) possibles) |> u64.sum

entry next_guess [w] [d] [p] (dictionary: [d][w]u8) (possibles: [p][w]u8): [w]u8 =
  let chunk_size = 64
  let num_chunks = (d+chunk_size-1)/chunk_size
  let get_chunk i arr =
    take (i64.min (d-i*chunk_size) chunk_size) (drop (i*chunk_size) arr)
  let (best, _) =
    loop (cur_best : ([w]u8, u64)) = (replicate w 0,u64.highest) for i < num_chunks do
     let dictionary_chunk = get_chunk i dictionary
     let scores_chunk = map (score_of_guess possibles) dictionary_chunk
     let (best_in_chunk_i, best_in_chunk_score) =
       min_by (.1) (0,u64.highest)
              (zip (indices dictionary_chunk) scores_chunk)
     in if cur_best.1 < best_in_chunk_score
        then cur_best
        else (dictionary_chunk[best_in_chunk_i], best_in_chunk_score)
  in best
