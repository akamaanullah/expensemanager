import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                    Icons.privacy_tip,
                    size: 48,
                    color: themeColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Privacy Policy',
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Your privacy matters to us',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                      ),
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
                    '1. Introduction',
                    'Expense Manager ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
                  ),

                  _buildSectionWithSubsections(
                    '2. Information We Collect',
                    'We collect information that you provide directly to us and information that is automatically collected when you use our application:',
                    [
                      'Personal Information:\n• Name and email address\n• Profile information\n• Account credentials',
                      'Transaction Data:\n• Income and expense records\n• Transaction amounts, dates, and categories\n• Currency preferences\n• Transaction descriptions',
                      'Device Information:\n• Device type and operating system\n• App version and usage statistics\n• IP address and device identifiers',
                    ],
                  ),

                  _buildSection(
                    '3. How We Use Your Information',
                    'We use the information we collect to:\n\n'
                    '• Provide, maintain, and improve our services\n'
                    '• Process and manage your transactions\n'
                    '• Send you technical notices and support messages\n'
                    '• Respond to your comments and questions\n'
                    '• Monitor and analyze usage patterns and trends\n'
                    '• Detect, prevent, and address technical issues\n'
                    '• Personalize your experience within the application',
                  ),

                  _buildSection(
                    '4. Data Storage and Security',
                    'We take data security seriously:\n\n'
                    '• All data is encrypted in transit using SSL/TLS\n'
                    '• Data is stored securely on Firebase servers\n'
                    '• We implement industry-standard security measures\n'
                    '• Access to your data is restricted to authorized personnel only\n'
                    '• Regular security audits and updates are performed\n\n'
                    'However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your information, we cannot guarantee absolute security.',
                  ),

                  _buildSectionWithSubsections(
                    '5. Data Sharing and Disclosure',
                    'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:',
                    [
                      'Service Providers: We may share data with trusted third-party service providers who assist us in operating our application (e.g., Firebase, cloud hosting services)',
                      'Legal Requirements: We may disclose your information if required by law or in response to valid requests by public authorities',
                      'Business Transfers: In the event of a merger, acquisition, or sale of assets, your information may be transferred',
                      'With Your Consent: We may share information with your explicit consent',
                    ],
                  ),

                  _buildSectionWithSubsections(
                    '6. Your Rights and Choices',
                    'You have the following rights regarding your personal information:',
                    [
                      'Access: You can view and access your personal data through the application',
                      'Modification: You can update your profile and preferences at any time',
                      'Deletion: You can request deletion of your account and all associated data through the "Clear All Data" option in settings',
                      'Export: You can export your transaction data in CSV or JSON format',
                      'Opt-out: You can stop using the application at any time',
                    ],
                  ),

                  _buildSection(
                    '7. Data Retention',
                    'We retain your personal information for as long as your account is active or as needed to provide you services. If you delete your account, we will delete your personal information within a reasonable timeframe, except where we are required to retain it for legal purposes.',
                  ),

                  _buildSection(
                    '8. Third-Party Services',
                    'Our application uses third-party services that may collect information used to identify you:\n\n'
                    '• Firebase (Google): For authentication, database, and analytics\n'
                    '• Currency Exchange APIs: For real-time currency conversion rates\n\n'
                    'Please review the privacy policies of these third-party services to understand how they handle your information.',
                  ),

                  _buildSection(
                    '9. Children\'s Privacy',
                    'Our application is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
                  ),

                  _buildSection(
                    '10. International Data Transfers',
                    'Your information may be transferred to and maintained on computers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ. By using our application, you consent to the transfer of your information to our facilities and those third parties with whom we share it as described in this policy.',
                  ),

                  _buildSection(
                    '11. Changes to This Privacy Policy',
                    'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
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
                              Icons.contact_support,
                              color: themeColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Contact Us',
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
                          'If you have any questions about this Privacy Policy or our data practices, please contact us:',
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

  Widget _buildSectionWithSubsections(String title, String intro, List<String> subsections) {
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
            intro,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ...subsections.map((subsection) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                subsection,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

