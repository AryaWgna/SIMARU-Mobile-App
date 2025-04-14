import 'package:flutter/material.dart';

// Interface for screens with error handling capability
abstract class ErrorHandlingCapable {
  String? get errorMessage;
  void clearError();
}

// You can simplify this part if not needed
class ErrorHandlingScreen extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorHandlingScreen({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<ErrorHandlingScreen> createState() => ErrorHandlingScreenState();
}

class ErrorHandlingScreenState extends State<ErrorHandlingScreen> {
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }
  
  @override
  void didUpdateWidget(ErrorHandlingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage) {
      _errorMessage = widget.errorMessage;
    }
  }
  
  String? get errorMessage => _errorMessage;
  
  void setError(String? error) {
    setState(() {
      _errorMessage = error;
    });
  }
  
  void clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
