;; title: ttt
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;game id to use for the next game
(define-data-var latest-game-id uint u0)
;;

;; data maps
;;mappings for the games id and values
(define-map games 
    uint ;;key (game id) 
    {    ;;value (game tuple) 
        player-one: principal,
        player-two: (optional principal),
        is-player-one-turn: bool,
        bet-amount: uint,
        board: (list 9 uint),
        winner: (optional principal)
    }
)
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;helper function to validate a move
(define-private (validate-move (board (list 9 uint)) (move-index uint) (move uint))
    (let (
        ;;check that move being made is within the boundaries of the board
        (index-in-range (and (>= move-index u0) (< move-index u9)))

        ;;check that the move being made is either x or o
        (x-or-0 (or (is-eq move u1) (is-eq move u2)))

        ;;check that the cell the move is being played on is currently empty
        (empty-spot (is-eq (unwrap! (element-at? board move-index) false) u0))
        )

        ;;the three conditions must be true for the move to be valid
        (and (is-eq index-in-range true) (is-eq x-or-0 true) empty-spot)
    )
)
;;

