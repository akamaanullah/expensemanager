import 'package:flutter/material.dart';

class CategoryUtils {
  // Map category name to icon
  static IconData getCategoryIcon(String categoryName) {
    final iconMap = {
      // Income categories
      'Salary': Icons.account_balance,
      'Freelance': Icons.work,
      'Investment': Icons.trending_up,
      'Business': Icons.business,
      'Gift': Icons.card_giftcard,
      'Rental': Icons.home,
      
      // Expense categories
      'Food': Icons.restaurant,
      'Transport': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Bills': Icons.receipt,
      'Entertainment': Icons.movie,
      'Healthcare': Icons.medical_services,
      'Education': Icons.school,
      'Travel': Icons.flight,
      
      // Default
      'Other': Icons.category,
    };
    
    return iconMap[categoryName] ?? Icons.category;
  }
  
  // Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Get month name
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
  
  // Group transactions by date
  static String getGroupKey(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return 'This Week';
    } else if (date.year == now.year && date.month == now.month) {
      return 'This Month';
    } else {
      return '${getMonthName(date.month)} ${date.year}';
    }
  }
}

