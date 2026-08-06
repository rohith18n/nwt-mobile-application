  import 'package:nwt_app/constants/data/categories/categories.types.dart';

final List<Category> categories = [
    // Main category: Income
    Category(
      id: 'income',
      name: 'Income',
    ),
    // Income subcategories
    Category(
      id: 'salary',
      name: 'Salary',
      parentId: 'income',
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      parentId: 'income',
    ),
    Category(
      id: 'bonus',
      name: 'Bonus',
      parentId: 'income',
    ),
    Category(
      id: 'other_income',
      name: 'Other Income',
      parentId: 'income',
    ),
    
    // Main category: Expense
    Category(
      id: 'expense',
      name: 'Expense',
    ),
    // Expense subcategories
    Category(
      id: 'food',
      name: 'Food & Dining',
      parentId: 'expense',
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      parentId: 'expense',
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      parentId: 'expense',
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      parentId: 'expense',
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      parentId: 'expense',
    ),
    Category(
      id: 'health',
      name: 'Health',
      parentId: 'expense',
    ),
    Category(
      id: 'education',
      name: 'Education',
      parentId: 'expense',
    ),
    
    // Main category: Transfer
    Category(
      id: 'transfer',
      name: 'Transfer',
    ),
    // Transfer subcategories
    Category(
      id: 'account_transfer',
      name: 'Account Transfer',
      parentId: 'transfer',
    ),
    Category(
      id: 'loan_payment',
      name: 'Loan Payment',
      parentId: 'transfer',
    ),
    
    // Main category: Uncategorized
    Category(
      id: 'uncategorized',
      name: 'Uncategorized',
    ),
  ];