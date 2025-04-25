import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import 'package:medicare/widgets/notification_popup.dart';

class NewsView extends StatefulWidget {
  const NewsView({Key? key}) : super(key: key);

  @override
  _NewsViewState createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  bool isLoading = true;
  final String newsUrl = 'https://www.medicalnewstoday.com/';
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(newsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.white.withOpacity(1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('medical_news'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.turquoise,
                  ),
                ),
                Row(
                  children: [
                    // Add notification icon button
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: AppTheme.turquoise,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const NotificationPopup(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        controller.reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.home),
                      onPressed: () {
                        controller.loadRequest(Uri.parse(newsUrl));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
