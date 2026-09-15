# OOP Bank Account with Transaction History + Pandas CSV Analysis

import csv
import os
from datetime import datetime

CSV_FILE = "transactions.csv"


class BankAccount:
    """A simple bank account with deposit, withdraw, and transaction history."""

    def __init__(self, owner, balance=0):
        self.owner = owner
        self.balance = balance
        self.history = []  # each entry: dict with type, amount, balance, timestamp

    def deposit(self, amount):
        if amount <= 0:
            print("Deposit amount must be positive.")
            return
        self.balance += amount
        self._log_transaction("Deposit", amount)
        print(f"Deposited {amount}. New balance: {self.balance}")

    def withdraw(self, amount):
        if amount <= 0:
            print("Withdrawal amount must be positive.")
            return
        if amount > self.balance:
            print("Insufficient balance.")
            return
        self.balance -= amount
        self._log_transaction("Withdraw", amount)
        print(f"Withdrew {amount}. New balance: {self.balance}")

    def _log_transaction(self, txn_type, amount):
        entry = {
            "owner": self.owner,
            "type": txn_type,
            "amount": amount,
            "balance": self.balance,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }
        self.history.append(entry)

    def show_history(self):
        print(f"\n----- Transaction History: {self.owner} -----")
        if not self.history:
            print("No transactions yet.")
        for entry in self.history:
            print(f"{entry['timestamp']} | {entry['type']:<8} | "
                  f"Amount: {entry['amount']:<8} | Balance: {entry['balance']}")
        print("-" * 45)

    def save_to_csv(self, filename=CSV_FILE):
        """Append this account's transactions to a CSV file."""
        file_exists = os.path.isfile(filename)
        with open(filename, mode="a", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["owner", "type", "amount", "balance", "timestamp"])
            if not file_exists:
                writer.writeheader()
            writer.writerows(self.history)
        print(f"Saved {len(self.history)} transactions to {filename}")


def analyze_transactions(filename=CSV_FILE):
    """Use pandas to analyze the saved transaction CSV."""
    import pandas as pd

    if not os.path.isfile(filename):
        print("No transaction file found yet. Do some deposits/withdrawals first.")
        return

    df = pd.read_csv(filename)

    print("\n===== CSV Dataset Analysis (pandas) =====")
    print(f"Total transactions: {len(df)}")
    print(f"Unique account owners: {df['owner'].nunique()}")

    print("\nTotal amount by transaction type:")
    print(df.groupby("type")["amount"].sum())

    print("\nAverage transaction amount by owner:")
    print(df.groupby("owner")["amount"].mean())

    print("\nFinal balance per owner (latest transaction):")
    latest = df.sort_values("timestamp").groupby("owner").tail(1)
    print(latest[["owner", "balance"]].to_string(index=False))
    print("=" * 42)


def main():
    print("=== OOP Bank Account System ===")

    accounts = {}

    while True:
        print("\n1. Create account")
        print("2. Deposit")
        print("3. Withdraw")
        print("4. Show history")
        print("5. Save all to CSV")
        print("6. Analyze CSV with pandas")
        print("7. Exit")

        choice = input("Choose an option: ")

        if choice == "1":
            name = input("Enter account owner name: ")
            if name in accounts:
                print("Account already exists.")
            else:
                accounts[name] = BankAccount(name)
                print(f"Account created for {name}.")

        elif choice == "2":
            name = input("Enter account owner name: ")
            if name in accounts:
                amount = float(input("Enter deposit amount: "))
                accounts[name].deposit(amount)
            else:
                print("No such account.")

        elif choice == "3":
            name = input("Enter account owner name: ")
            if name in accounts:
                amount = float(input("Enter withdrawal amount: "))
                accounts[name].withdraw(amount)
            else:
                print("No such account.")

        elif choice == "4":
            name = input("Enter account owner name: ")
            if name in accounts:
                accounts[name].show_history()
            else:
                print("No such account.")

        elif choice == "5":
            for acc in accounts.values():
                acc.save_to_csv()

        elif choice == "6":
            analyze_transactions()

        elif choice == "7":
            print("Exiting. Goodbye!")
            break

        else:
            print("Invalid choice, try again.")


if __name__ == "__main__":
    main()