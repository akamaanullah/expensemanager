import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 48,
                    color: themeColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terms & Conditions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    '1. Acceptance of Terms',
                    'By accessing and using the Expense Manager application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                  ),

                  _buildSection(
                    '2. Use License',
                    'Permission is granted to temporarily use the Expense Manager application for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                    '• Modify or copy the materials\n'
                    '• Use the materials for any commercial purpose or for any public display\n'
                    '• Attempt to decompile or reverse engineer any software contained in the application\n'
                    '• Remove any copyright or other proprietary notations from the materials',
                  ),

                  _buildSection(
                    '3. User Account',
                    'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to:\n\n'
                    '• Provide accurate, current, and complete information during registration\n'
                    '• Maintain and promptly update your account information\n'
                    '• Notify us immediately of any unauthorized use of your account\n'
                    '• Be responsible for all activities that occur under your account',
                  ),

                  _buildSection(
                    '4. Data and Privacy',
                    'Your use of the Expense Manager application is also governed by our Privacy Policy. By using the application, you consent to:\n\n'
                    '• The collection and use of your personal information as described in the Privacy Policy\n'
                    '• The storage of your transaction data on secure servers\n'
                    '• The use of data analytics to improve our services\n\n'
                    'We are committed to protecting your privacy and ensuring the security of your financial data.',
                  ),

                  _buildSection(
                    '5. Prohibited Uses',
                    'You may not use the Expense Manager application:\n\n'
                    '• For any unlawful purpose or to solicit others to perform unlawful acts\n'
                    '• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n'
                    '• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n'
                    '• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n'
                    '• To submit false or misleading information\n'
                    '• To upload or transmit viruses or any other type of malicious code',
                  ),

                  _buildSection(
                    '6. Service Availability',
                    'We strive to ensure the Expense Manager application is available at all times. However, we do not guarantee:\n\n'
                    '• Uninterrupted or error-free service\n'
                    '• That defects will be corrected immediately\n'
                    '• That the service will meet your specific requirements\n\n'
                    'We reserve the right to modify, suspend, or discontinue any part of the service at any time with or without notice.',
                  ),

                  _buildSection(
                    '7. Limitation of Liability',
                    'In no event shall Expense Manager or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on the Expense Manager application, even if Expense Manager or an authorized representative has been notified orally or in writing of the possibility of such damage.',
                  ),

                  _buildSection(
                    '8. Accuracy of Materials',
                    'The materials appearing in the Expense Manager application could include technical, typographical, or photographic errors. Expense Manager does not warrant that any of the materials on its application are accurate, complete, or current. Expense Manager may make changes to the materials contained on its application at any time without notice.',
                  ),

                  _buildSection(
                    '9. Modifications',
                    'Expense Manager may revise these terms of service for its application at any time without notice. By using this application, you are agreeing to be bound by the then current version of these terms of service.',
                  ),

                  _buildSection(
                    '10. Governing Law',
                    'These terms and conditions are governed by and construed in accordance with applicable laws. You agree to submit to the exclusive jurisdiction of the courts in the jurisdiction where the application is operated.',
                  ),

                  const SizedBox(height: 24),

                  // Contact Information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: themeColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Questions or Concerns?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'If you have any questions about these Terms & Conditions, please contact us:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: themeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Developer: Amaanullah Khan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: themeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      'info@amaanullah.com',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: themeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      '+92 319 6935307',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You can also visit the Help & Support section in the app settings for more assistance.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

