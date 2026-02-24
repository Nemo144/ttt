"use client";
import { GameBoard } from "@/components/game-board";
import { useStacks } from "@/hooks/use-stacks";
import { EMPTY_BOARD, Move } from "@/lib/contract";
import { formatStx, parseStx } from "@/lib/stx-utils";
import { useState } from "react";

export const CreateGame = () => {
  const { stxBalance, userdata, connectWallet, handleCreateGame } = useStacks();

  //state to monitor change in bet amount
  const [betAmount, setBetAmount] = useState(0);

  // When creating a new game, the initial board is entirely empty
  const [board, setBoard] = useState(EMPTY_BOARD);

  const onCellClick = (index: number) => {
    // the board is updated to be the empty board + the move played by the user
    // Since this is inside 'Create Game', the user's move is the very first move and therefore always an X

    const tempBoard = [...EMPTY_BOARD];
    tempBoard[index] = Move.X;
    setBoard(tempBoard);
  };

  const onCreateGame = async () => {
    //to find the moveindex
    const moveIndex = board.findIndex((cell) => cell !== Move.EMPTY);
    const move = Move.X;
    //to trigger the onchain transaction popup
    await handleCreateGame(parseStx(betAmount), moveIndex, move);
  };

  return (
    <section className="flex flex-col items-center py-20">
      <div className="text-center mb-20">
        <h1 className="text-4xl font-bold">Create Game</h1>
        <span className="text-sm text-gray-500">
          Make a bet and play your first move
        </span>
      </div>

      <div className="flex flex-col gap-4 w-100">
        <GameBoard
          board={board}
          onCellClick={onCellClick}
          nextMove={Move.X}
          cellClassName="size-32 text-6xl"
        />

        <div className="flex items-center gap-2 w-full">
          <span className="">Bet: </span>
          <input
            type="number"
            className="w-full rounded bg-gray-800 px-1"
            placeholder="0"
            value={betAmount}
            onChange={(e) => {
              setBetAmount(parseInt(e.target.value));
            }}
          />
          <div
            className="text-xs px-1 py-0.5 cursor-pointer hover:bg-gray-700 bg-gray-600 border border-gray-600 rounded"
            onClick={() => {
              setBetAmount(formatStx(stxBalance));
            }}
          >
            Max
          </div>
        </div>

        {userdata ? (
          <button
            type="button"
            className="bg-blue-500 text-white px-4 py-2 rounded"
            onClick={onCreateGame}
          >
            Create Game
          </button>
        ) : (
          <button
            type="button"
            onClick={connectWallet}
            className="bg-blue-500 text-white px-4 py-2 rounded"
          >
            Connect Wallet
          </button>
        )}
      </div>
    </section>
  );
};
