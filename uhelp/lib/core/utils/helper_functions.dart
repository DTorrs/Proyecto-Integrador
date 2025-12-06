import 'package:intl/intl.dart';

class HelperFunctions {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  static String truncateString(String text, int length) {
    if (text.length <= length) {
      return text;
    }
    return '${text.substring(0, length)}...';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    List<String> nameParts = name.split(' ');
    String initials = '';
    
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
      if (initials.length >= 2) break;
    }
    
    return initials;
  }
}