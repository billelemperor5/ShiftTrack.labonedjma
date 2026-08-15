import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/hive_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  TransactionProvider() {
    _loadTransactions();
  }

  void refresh() => _loadTransactions();

  void _loadTransactions() {
    final box = HiveService.getTransactionBox();
    _transactions = box.values.toList();
    // Sort by date descending
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  double get currentBalance {
    double balance = 0;
    for (var t in _transactions) {
      if (t.type == TransactionType.deposit) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double get monthlyEntrees {
    final now = DateTime.now();
    double total = 0;
    for (var t in _transactions) {
      if (t.date.year == now.year &&
          t.date.month == now.month &&
          t.type == TransactionType.deposit) {
        total += t.amount;
      }
    }
    return total;
  }

  double get monthlySorties {
    final now = DateTime.now();
    double total = 0;
    for (var t in _transactions) {
      if (t.date.year == now.year &&
          t.date.month == now.month &&
          t.type == TransactionType.withdrawal) {
        total += t.amount;
      }
    }
    return total;
  }

  Future<void> addTransaction(Transaction transaction) async {
    final box = HiveService.getTransactionBox();
    await box.add(transaction);
    _loadTransactions();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
    _loadTransactions();
  }

  Future<void> clearAllTransactions() async {
    final box = HiveService.getTransactionBox();
    await box.clear();
    _loadTransactions();
  }
}
