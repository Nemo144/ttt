import { createNewGame, joinGame, Move, playGame } from "@/lib/contract";
import { getStxBalance } from "@/lib/stx-utils";
import {
  AppConfig,
  openContractCall,
  showConnect,
  type UserData,
  UserSession,
} from "@stacks/connect";
import { PostConditionMode } from "@stacks/transactions";
import { useEffect, useState } from "react";

const appDetails = {
  name: "ttt",
  icon: "https://cryptologos.cc/logos/stacks-stx-logo.png",
};

const appConfig = new AppConfig(["store_write"]);
const userSession = new UserSession({ appConfig });

export const useStacks = () => {
  //state for the userdata
  const [userdata, setUserData] = useState<UserData | null>(null);

  //state to monitor the change in stx balance
  const [stxBalance, setStxBalance] = useState(0);

  const connectWallet = () => {
    showConnect({
      appDetails,
      onFinish: () => {
        window.location.reload();
      },
      userSession,
    });
  };

  const disconnectWallet = () => {
    userSession.signUserOut;
    setUserData(null);
  };

  const handleCreateGame = async (
    betAmount: number,
    moveIndex: number,
    move: Move,
  ) => {
    //if window is undefined, the functions returns early and doesn't execute rest of the code
    if (typeof window === undefined) return;

    //checks if the move is valid. if invalid runs an alert
    if (moveIndex < 0 || moveIndex > 8) {
      window.alert("Invalid move. Please make a valid move");
      return;
    }

    try {
      if (!userdata) throw new Error("user not connected");
      const txOptions = createNewGame(betAmount, moveIndex, move);
      openContractCall(
        await {
          ...txOptions,
          appDetails,
          onFinish: (data: unknown) => {
            console.log(data);
            window.alert("sent create game transaction");
          },
          postConditionMode: PostConditionMode.Allow,
        },
      );
    } catch (_err) {
      const err = _err as Error;
      console.error(err);
      window.alert(err.message);
    }
  };

  const handleJoinGame = async (
    gameId: number,
    moveIndex: number,
    move: Move,
  ) => {
    if (typeof window === undefined) return;

    //check if move is valid
    if (moveIndex < 0 || moveIndex > 8) {
      window.alert("Invalid move. Please make a valid move");
      return;
    }

    try {
      if (!userdata) throw new Error("user not connected");
      const txOptions = createNewGame(gameId, moveIndex, move);
      openContractCall(
        await {
          ...txOptions,
          appDetails,
          onFinish: (data: unknown) => {
            console.log(data);
            window.alert("sent join game transaction");
          },
          postConditionMode: PostConditionMode.Allow,
        },
      );
    } catch (_err) {
      const err = _err as Error;
      console.error(err);
      window.alert(err.message);
    }
  };

  const handlePlayGame = async (
    gameId: number,
    moveIndex: number,
    move: Move,
  ) => {
    if (typeof window === undefined) return;

    //check if move is valid
    if (moveIndex < 0 || moveIndex > 8) {
      window.alert("Invalid move. Please make a valid move");
      return;
    }

    try {
      if (!userdata) throw new Error("user not connected");
      const txOptions = createNewGame(gameId, moveIndex, move);
      openContractCall(
        await {
          ...txOptions,
          appDetails,
          onFinish: (data: unknown) => {
            console.log(data);
            window.alert("sent play game transaction");
          },
          postConditionMode: PostConditionMode.Allow,
        },
      );
    } catch (_err) {
      const err = _err as Error;
      console.error(err);
      window.alert(err.message);
    }
  };

  //effect changes for the sessions
  useEffect(() => {
    if (userSession.isSignInPending()) {
      userSession.handlePendingSignIn().then((userdata) => {
        setUserData(userdata);
      });
    } else if (userSession.isUserSignedIn()) {
      setUserData(userSession.loadUserData());
    }
  }, []);

  useEffect(() => {
    if (userdata) {
      const address = userdata.profile.stxAddress.testnet;
      getStxBalance(address).then((balance) => {
        setStxBalance(balance);
      });
    }
  }, [userdata]);

  return {
    userdata,
    stxBalance,
    connectWallet,
    disconnectWallet,
    handleCreateGame,
    handleJoinGame,
    handlePlayGame,
  };
};
