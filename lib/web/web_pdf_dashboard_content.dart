import 'package:flutter/material.dart';

class WebPDFDashboardContent extends StatelessWidget {
  const WebPDFDashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.blueGrey),
          SizedBox(height: 24),
          Text('PDF preview/download is not yet supported in web version.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
