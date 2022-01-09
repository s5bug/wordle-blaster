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
  possibles |> map (\possibility -> count (is_possible (guess_against possibility guess)) possibles) |> reduce_comm (+) 0

entry next_guess [w] [d] [p] (dictionary: [d][w]u8) (possibles: [p][w]u8): [w]u8 =
  min_by (score_of_guess possibles) (replicate w 0) dictionary
