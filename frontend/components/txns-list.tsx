"use client";

import {
  fetchAddressTransactions,
  type FetchAddressTransactionsResponse,
} from "@/lib/fetch-address-transactions";
import { TransactionDetail } from "./txn-details";
import { useState } from "react";

interface TransactionsListProps {
  address: string;
  transactions: FetchAddressTransactionsResponse;
}

export const TransactionsList = ({
  address,
  transactions,
}: TransactionsListProps) => {
  const [allTxns, setAllTxns] = useState(transactions);

  //load another 20 txns
  const loadMoreTxns = async () => {
    const newTxns = await fetchAddressTransactions({
      address,
      offset: allTxns.offset + allTxns.limit,
    });

    setAllTxns({
      ...newTxns,
      results: [...allTxns.results, ...newTxns.results],
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col border rounded-md divide-y border-gray-800 divide-gray-800">
        {allTxns.results.map((tx) => (
          <div key={tx.tx.tx_id}>
            <TransactionDetail result={tx} />
          </div>
        ))}
      </div>
      <button
        type="button"
        className="px-4 py-2 rounded-lg w-fit border border-gray-800 mx-auto text-center hover:bg-gray-900 transition-all"
        onClick={loadMoreTxns}
      >
        Load More
      </button>
    </div>
  );
};
