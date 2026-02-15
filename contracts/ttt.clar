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
;;

