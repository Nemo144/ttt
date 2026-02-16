;; title: ttt
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;defining error codes
;;(define-constant THIS_CONTRACT (as-contract tx-sender))
(define-constant ERR_MIN_BET_AMOUNT u100)
(define-constant ERR_INVALID_MOVE u101)
(define-constant ERR_GAME_NOT_FOUND u102)
(define-constant ERR_GAME_CANNOT_BE_JOINED u103)
(define-constant ERR_NOT_YOUR_TURN u104)
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
(define-public (create-game (bet-amount uint) (move-index uint) (move uint))
    (let (
        ;;get the game id to use for the creation of this new game
        (game-id (var-get latest-game-id))

        ;;initial starting board for the game with the cells all empty
        (starting-board (list u0 u0 u0 u0 u0 u0 u0 u0 u0))

        ;;updated board with the starting move played by the game creator(x)
        (game-board (unwrap! (replace-at? starting-board move-index move) (err ERR_INVALID_MOVE)))

        ;;game data tuple
        (game-data {
            player-one: contract-caller,
            player-two: none,
            is-player-one-turn: false,
            bet-amount: bet-amount,
            board: game-board,
            winner: none,
        })
      )
      
      ;;ensure that the user has placed a bet amount greater than the minimum
      (asserts! (> bet-amount u0) (err ERR_MIN_BET_AMOUNT))

      ;;ensure that the move being played is an 'X' not an '0'
      (asserts! (is-eq move u1) (err ERR_INVALID_MOVE))

      ;;ensure that the move meets validity requirements
      (asserts! (validate-move starting-board move-index move) (err ERR_INVALID_MOVE))

      ;;transfer the bet amount stx from user to this contract
      (try! (stx-transfer? bet-amount contract-caller (as-contract tx-sender)))

      ;;update the game map with the new game data
      (map-set games game-id game-data)

      ;;increment the game-id counter
      (var-set latest-game-id (+ game-id u1))

      ;;log the creation of the new game
      (print {action: "create-game", data: game-data})

      ;;return the game id of the new game
      (ok game-id)
    )
)
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

