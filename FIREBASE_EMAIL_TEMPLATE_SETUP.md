# Firebase Email Template Customization Guide

## How to Customize Password Reset Email Template

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Templates**

### Step 2: Customize Password Reset Email
1. Click on **Password reset** template
2. You can customize:
   - **Subject**: Email subject line
   - **Body**: Email content with HTML support
   - **Action URL**: Link that appears in the email

### Step 3: Email Template Customization Options

#### Basic Customization:
- **Email Subject**: Customize the subject line
- **Email Body**: Add your branding, logo, and custom message
- **Action Button**: Customize the reset button text

#### Advanced Customization (HTML):
You can use HTML in the email body to make it more professional:

```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <div style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
    <h1 style="color: white; margin: 0;">Expense Manager</h1>
  </div>
  
  <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
    <h2 style="color: #333; margin-top: 0;">Reset Your Password</h2>
    
    <p style="color: #666; line-height: 1.6;">
      Hello,<br><br>
      We received a request to reset your password for your Expense Manager account.
      Click the button below to reset your password:
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{link}}" style="background: #6366F1; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold;">
        Reset Password
      </a>
    </div>
    
    <p style="color: #999; font-size: 12px; line-height: 1.6;">
      If you didn't request this password reset, please ignore this email or contact support if you have concerns.
      <br><br>
      This link will expire in 1 hour.
      <br><br>
      Best regards,<br>
      Expense Manager Team
    </p>
  </div>
  
  <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
    <p>© 2025 Expense Manager. All rights reserved.</p>
    <p>Developer: Amaanullah Khan | info@amaanullah.com</p>
  </div>
</div>
```

### Step 4: Available Variables
Firebase provides these variables you can use in the template:
- `%LINK%` - The password reset link (REQUIRED - must be included)
- `%EMAIL%` - User's email address
- `%APP_NAME%` - Application name
- `%DISPLAY_NAME%` - User's display name (if available)

**IMPORTANT:** The `%LINK%` tag is **REQUIRED** and must be included in your template, otherwise Firebase will show an error.

### Step 5: Custom Action URL (Optional)
You can set a custom domain for the reset link:
1. In Firebase Console → Authentication → Settings
2. Scroll to **Authorized domains**
3. Add your custom domain
4. Configure the action URL to use your domain

### Step 6: Email Sender Configuration
1. Go to **Authentication** → **Settings** → **User actions**
2. Configure **Email action handler URL** if using custom domain
3. Set up **Email templates** for different languages if needed

## Important Notes:
- HTML is supported in email body
- CSS should be inline for better email client compatibility
- Test the email by sending a password reset request
- Check spam folder if email doesn't arrive
- Email templates are global for all users in your project

## Complete Professional Email Template:

**Subject:**
```
Reset Your Expense Manager Password
```

**Body (HTML) - Copy this complete template:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Reset Your Password - Expense Manager</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <!-- Wrapper Table -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 20px;">
    <tr>
      <td align="center">
        <!-- Main Container -->
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1); max-width: 600px;">
          
          <!-- Header with Gradient -->
          <tr>
            <td style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); padding: 50px 40px; text-align: center;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <div style="width: 80px; height: 80px; background-color: rgba(255, 255, 255, 0.2); border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center;">
                      <span style="font-size: 40px;">💰</span>
                    </div>
                    <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; letter-spacing: -0.5px;">Expense Manager</h1>
                    <p style="color: rgba(255, 255, 255, 0.95); margin: 10px 0 0 0; font-size: 16px; font-weight: 400;">Track Your Finances Smartly</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="padding: 50px 40px;">
              <h2 style="color: #1f2937; margin: 0 0 20px 0; font-size: 26px; font-weight: 700; line-height: 1.3;">Reset Your Password</h2>
              
              <p style="color: #4b5563; line-height: 1.7; margin: 0 0 20px 0; font-size: 16px;">
                Hello,
              </p>
              
              <p style="color: #4b5563; line-height: 1.7; margin: 0 0 35px 0; font-size: 16px;">
                We received a request to reset your password for your %APP_NAME% account associated with <strong style="color: #1f2937;">%EMAIL%</strong>.
                <br><br>
                Click the button below to create a new password. This link will expire in <strong style="color: #6366F1;">1 hour</strong> for your security.
              </p>
              
              <!-- Reset Password Button -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 35px 0;">
                <tr>
                  <td align="center">
                    <a href="%LINK%" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); color: #ffffff; text-decoration: none; padding: 16px 48px; border-radius: 10px; display: inline-block; font-weight: 600; font-size: 16px; box-shadow: 0 4px 14px rgba(99, 102, 241, 0.4); transition: all 0.3s ease;">
                      Reset Password
                    </a>
                  </td>
                </tr>
              </table>
              
              <!-- Alternative Link -->
              <div style="background-color: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px; margin: 0 0 35px 0;">
                <p style="color: #6b7280; margin: 0 0 10px 0; font-size: 14px; font-weight: 500;">
                  Or copy and paste this link into your browser:
                </p>
                <p style="color: #6366F1; margin: 0; font-size: 13px; word-break: break-all; line-height: 1.6;">
                  %LINK%
                </p>
              </div>
              
              <!-- Security Notice -->
              <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 18px 20px; margin: 0 0 30px 0; border-radius: 6px;">
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding: 0;">
                      <p style="color: #92400e; margin: 0; font-size: 14px; line-height: 1.6;">
                        <strong style="display: block; margin-bottom: 5px;">⚠️ Security Notice</strong>
                        If you didn't request this password reset, please ignore this email. Your account remains secure and no changes have been made. If you have concerns about your account security, please contact our support team immediately.
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
              
              <!-- Additional Info -->
              <div style="border-top: 1px solid #e5e7eb; padding-top: 25px; margin-top: 30px;">
                <p style="color: #6b7280; margin: 0 0 10px 0; font-size: 14px; line-height: 1.6;">
                  <strong style="color: #1f2937;">Need help?</strong>
                </p>
                <p style="color: #6b7280; margin: 0; font-size: 14px; line-height: 1.6;">
                  • Email: <a href="mailto:info@amaanullah.com" style="color: #6366F1; text-decoration: none;">info@amaanullah.com</a><br>
                  • Phone: <a href="tel:+923196935307" style="color: #6366F1; text-decoration: none;">+92 319 6935307</a>
                </p>
              </div>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #f9fafb; padding: 35px 40px; text-align: center; border-top: 1px solid #e5e7eb;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <p style="color: #6b7280; margin: 0 0 8px 0; font-size: 14px; line-height: 1.6;">
                      © 2025 Expense Manager. All rights reserved.
                    </p>
                    <p style="color: #9ca3af; margin: 0 0 8px 0; font-size: 12px;">
                      Developed by <strong style="color: #6366F1;">Amaanullah Khan</strong>
                    </p>
                    <p style="color: #9ca3af; margin: 0; font-size: 11px;">
                      This is an automated email. Please do not reply to this message.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
        </table>
        
        <!-- Bottom Spacing -->
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width: 600px;">
          <tr>
            <td style="padding: 30px 0 0 0; text-align: center;">
              <p style="color: #9ca3af; margin: 0; font-size: 11px; line-height: 1.6;">
                If you're having trouble with the button above, copy and paste the URL into your web browser.
              </p>
            </td>
          </tr>
        </table>
        
      </td>
    </tr>
  </table>
</body>
</html>
```

## Quick Setup Steps:
1. Open Firebase Console → Authentication → Templates
2. Click on "Password reset" 
3. Customize Subject and Body (paste HTML template above)
4. Click "Save"
5. Test by requesting a password reset

## Testing:
1. Send a password reset request from your app
2. Check the email inbox (and spam folder)
3. Verify the email looks professional and all links work
4. Test the reset link functionality

