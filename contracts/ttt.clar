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
(define-constant THIS_CONTRACT (as-contract tx-sender))
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
;;define the create-game function
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
      (try! (stx-transfer? bet-amount contract-caller THIS_CONTRACT))

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

;;define the join-game function
(define-public (join-game (game-id uint) (move-index uint) (move uint))
    (let (
            ;;load game data for the game being joined. throw an error if game id is invalid
            (original-game-data (unwrap! (map-get? games game-id) (err ERR_GAME_NOT_FOUND)))

            ;;get original board from the game data
            (original-board (get board original-game-data))

            ;;update the game board by placing the player's move at the specified index
            (game-board (unwrap! (replace-at? original-board move-index move) (err ERR_INVALID_MOVE)))

            ;;update the copy of the game data with the updated board and marking the next turn to be player two's turn
            (game-data (merge original-game-data {
                board: game-board,
                player-two: (some contract-caller),
                is-player-one-turn: true
            }))
        )

            ;;ensure the game being joined is able to be joined i.e player two is currently empty
            (asserts! (is-none (get player-two original-game-data)) (err ERR_GAME_CANNOT_BE_JOINED))

            ;;ensure the move being played is an 'O' not an 'x'
            (asserts! (is-eq move u2) (err ERR_INVALID_MOVE))

            ;;ensure the move meets validity requirement
            (asserts! (validate-move original-board move-index move) (err ERR_INVALID_MOVE))

            ;;transfer the bet amount from user to this contract
            (try! (stx-transfer? (get bet-amount original-game-data) contract-caller THIS_CONTRACT))

            ;; Update the games map with the new game data
            (map-set games game-id game-data)

            ;; Log the joining of the game
            (print { action: "join-game", data: game-data})
            
            ;; Return the Game ID of the game
            (ok game-id)
    )
)

;;define the play function
(define-public (play (game-id uint) (move-index uint) (move uint))

    (let (

        ;;load the game data for the game being played, return an error if game-id is invalid
        (original-game-data (unwrap! (map-get? games game-id) (err ERR_GAME_NOT_FOUND)))

        ;;get the original board from the game data
        (original-board (get board original-game-data))

        ;;is it player one's turn
        (is-player-one-turn (get is-player-one-turn original-game-data))

        ;;get the player whose turn it currently is based on the is-player-one flag
        (player-turn (if is-player-one-turn (get player-one original-game-data) (unwrap! (get player-two original-game-data) (err ERR_GAME_NOT_FOUND))))

        ;;get the expected move based on whose turn it is
        (expected-move (if is-player-one-turn u1 u2))

        ;;update the game-board by placing the player's move at the specified index
        (game-board (unwrap! (replace-at? original-board move-index move) (err ERR_INVALID_MOVE)))

        ;;check if the game has been won with this modified board
        (is-now-winner (has-won game-board))

        ;;merge the game data with the updated board and marking the next turn to be player two's turn, mark the winner if the game has been won
        (game-data (merge original-game-data {
            board: game-board,
            is-player-one-turn: (not is-player-one-turn),
            winner: (if is-now-winner (some player-turn) none)
        })) 
      )

        ;;ensure the function is being called by the right player's turn
       (asserts! (is-eq player-turn contract-caller) (err ERR_NOT_YOUR_TURN))

       ;;ensure the move being played is the correct move based on the current turn (x or o)
       (asserts! (is-eq move expected-move) (err ERR_INVALID_MOVE))

       ;;ensure that the move meets validity requirements
       (asserts! (validate-move original-board move-index move) (err ERR_INVALID_MOVE))

       ;;if the game has been won, transfer the bet amount of the two players to the winner
       (if is-now-winner (try! (as-contract (stx-transfer? (* u2 (get bet-amount game-data)) tx-sender player-turn))) false)

       ;;update the games map with new game data
       (map-set games game-id game-data)

       ;;log the action of a move being made
       (print {action: "play", data: game-data})

       ;;return the game id of the game
       (ok game-id)
    )
)
;;

;; read only functions

;;the get-game rof will return the game-id if valid for the frontend of things
(define-read-only (get-game (game-id uint))
    (map-get? games game-id)
)

;;get-latest-game-id will return the latest-game-id ...fot
(define-read-only (get-latest-game-id)
    (var-get latest-game-id)
)
;;

;; private functions
;;helper function to validate a move
(define-private (validate-move (board (list 9 uint)) (move-index uint) (move uint))
    (let (
        ;; Validate that the move is being played within range of the board
        (index-in-range (and (>= move-index u0) (< move-index u9)))

        ;; Validate that the move is either an X or an O
        (x-or-o (or (is-eq move u1) (is-eq move u2)))

        ;; Validate that the cell the move is being played on is currently empty
        (empty-spot (is-eq (unwrap! (element-at? board move-index) false) u0))
    )

    ;; All three conditions must be true for the move to be valid
    (and (is-eq index-in-range true) (is-eq x-or-o true) empty-spot)
))

;;return true if all three cells are not empty and have the same value (all X or all O)
;;return false if any of the three is empty or a different value
(define-private (is-line (board (list 9 uint)) (a uint) (b uint) (c uint)) 
    (let (
        ;;value of a cell at index a
        (a-val (unwrap! (element-at? board a) false))

        ;;value of a cell at index b
        (b-val (unwrap! (element-at? board b) false))

        ;;value of a cell at index c
        (c-val (unwrap! (element-at? board c)  false))
     )

     ;;a-val must equal b-val and must also equal c-val while not being empty (non-zero)
     (and (is-eq a-val b-val) (is-eq a-val c-val) (not (is-eq a-val u0)))
    )
)

;; Given a board, return true if any possible three-in-a-row line has been completed
(define-private (has-won (board (list 9 uint))) 
    (or
        (is-line board u0 u1 u2) ;; Row 1
        (is-line board u3 u4 u5) ;; Row 2
        (is-line board u6 u7 u8) ;; Row 3
        (is-line board u0 u3 u6) ;; Column 1
        (is-line board u1 u4 u7) ;; Column 2
        (is-line board u2 u5 u8) ;; Column 3
        (is-line board u0 u4 u8) ;; Left to Right Diagonal
        (is-line board u2 u4 u6) ;; Right to Left Diagonal
    )
)
;;

