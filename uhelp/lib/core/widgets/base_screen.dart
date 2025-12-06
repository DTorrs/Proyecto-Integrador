import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool isLoading;
  final String? errorMessage;
  final Function? onRetry;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? drawer;
  final bool useScrollView;
  final bool resizeToAvoidBottomInset;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.actions,
    this.showBackButton = true,
    this.drawer,
    this.useScrollView = true,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
      ),
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: _buildBody(context),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => onRetry!(),
                child: Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return useScrollView
        ? SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: body,
          )
        : body;
  }
}