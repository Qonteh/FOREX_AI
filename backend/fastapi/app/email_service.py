"""
Email service for sending verification and notification emails.
Uses SMTP for sending emails.
"""
import smtplib
import secrets
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import os
from datetime import datetime, timedelta


class EmailService:
    """Service for sending emails."""
    
    def __init__(self):
        # Email configuration from environment variables
        self.smtp_host = os.getenv('SMTP_HOST', 'smtp.gmail.com')
        self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
        self.smtp_user = os.getenv('SMTP_USER', '')
        self.smtp_password = os.getenv('SMTP_PASSWORD', '')
        self.from_email = os.getenv('FROM_EMAIL', 'noreply@forexai.com')
        self.from_name = os.getenv('FROM_NAME', 'FOREX AI Trading')
        
        # Base URL for verification links
        self.base_url = os.getenv('BASE_URL', 'http://localhost:8001')
        
    def generate_verification_token(self) -> str:
        """Generate a secure random token for email verification."""
        return secrets.token_urlsafe(32)
    
    def send_verification_email(self, to_email: str, to_name: str, verification_token: str) -> bool:
        """
        Send email verification link to user.
        
        Args:
            to_email: Recipient email address
            to_name: Recipient name
            verification_token: Verification token
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            verification_link = f"{self.base_url}/auth/verify-email?token={verification_token}"
            
            subject = "Verify Your Email - FOREX AI Trading"
            
            # HTML email body
            html_body = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{
                        font-family: Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                    }}
                    .container {{
                        max-width: 600px;
                        margin: 0 auto;
                        padding: 20px;
                    }}
                    .header {{
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 30px;
                        text-align: center;
                        border-radius: 10px 10px 0 0;
                    }}
                    .content {{
                        background: #f9f9f9;
                        padding: 30px;
                        border-radius: 0 0 10px 10px;
                    }}
                    .button {{
                        display: inline-block;
                        padding: 15px 30px;
                        background: #667eea;
                        color: white;
                        text-decoration: none;
                        border-radius: 5px;
                        margin: 20px 0;
                    }}
                    .footer {{
                        text-align: center;
                        margin-top: 30px;
                        color: #666;
                        font-size: 12px;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🚀 Welcome to FOREX AI Trading!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello {to_name}!</h2>
                        <p>Thank you for registering with FOREX AI Trading. We're excited to have you on board!</p>
                        <p>To complete your registration and activate your account, please verify your email address by clicking the button below:</p>
                        <div style="text-align: center;">
                            <a href="{verification_link}" class="button">Verify Email Address</a>
                        </div>
                        <p>Or copy and paste this link into your browser:</p>
                        <p style="word-break: break-all; background: #fff; padding: 10px; border-radius: 5px;">
                            {verification_link}
                        </p>
                        <p><strong>This link will expire in 24 hours.</strong></p>
                        <p>If you didn't create an account with us, please ignore this email.</p>
                        <p>Best regards,<br>The FOREX AI Trading Team</p>
                    </div>
                    <div class="footer">
                        <p>© {datetime.now().year} FOREX AI Trading. All rights reserved.</p>
                        <p>This is an automated email. Please do not reply to this message.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # Plain text version
            text_body = f"""
            Hello {to_name}!
            
            Thank you for registering with FOREX AI Trading.
            
            To complete your registration, please verify your email address by clicking this link:
            {verification_link}
            
            This link will expire in 24 hours.
            
            If you didn't create an account with us, please ignore this email.
            
            Best regards,
            The FOREX AI Trading Team
            """
            
            # Create message
            message = MIMEMultipart('alternative')
            message['Subject'] = subject
            message['From'] = f"{self.from_name} <{self.from_email}>"
            message['To'] = to_email
            
            # Attach both plain text and HTML versions
            part1 = MIMEText(text_body, 'plain')
            part2 = MIMEText(html_body, 'html')
            message.attach(part1)
            message.attach(part2)
            
            # Send email only if SMTP is configured
            if self.smtp_user and self.smtp_password:
                with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                    server.starttls()
                    server.login(self.smtp_user, self.smtp_password)
                    server.send_message(message)
                print(f"✅ Verification email sent to {to_email}")
                return True
            else:
                # In development, just print the verification link
                print(f"\n{'='*80}")
                print(f"📧 EMAIL VERIFICATION (Development Mode)")
                print(f"{'='*80}")
                print(f"To: {to_email}")
                print(f"Name: {to_name}")
                print(f"Verification Link: {verification_link}")
                print(f"{'='*80}\n")
                return True
                
        except Exception as e:
            print(f"❌ Failed to send verification email: {str(e)}")
            return False
    
    def send_welcome_email(self, to_email: str, to_name: str) -> bool:
        """
        Send welcome email after email verification.
        
        Args:
            to_email: Recipient email address
            to_name: Recipient name
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            subject = "Welcome to FOREX AI Trading - Your Account is Active!"
            
            html_body = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{
                        font-family: Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                    }}
                    .container {{
                        max-width: 600px;
                        margin: 0 auto;
                        padding: 20px;
                    }}
                    .header {{
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 30px;
                        text-align: center;
                        border-radius: 10px 10px 0 0;
                    }}
                    .content {{
                        background: #f9f9f9;
                        padding: 30px;
                        border-radius: 0 0 10px 10px;
                    }}
                    .feature {{
                        background: white;
                        padding: 15px;
                        margin: 10px 0;
                        border-radius: 5px;
                        border-left: 4px solid #667eea;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎉 Your Account is Active!</h1>
                    </div>
                    <div class="content">
                        <h2>Welcome aboard, {to_name}!</h2>
                        <p>Your email has been successfully verified and your account is now active.</p>
                        <h3>🚀 What's Next?</h3>
                        <div class="feature">
                            <h4>📊 Explore Trading Signals</h4>
                            <p>Get AI-powered trading signals and market analysis</p>
                        </div>
                        <div class="feature">
                            <h4>🤖 Try Our AI Chat Bot</h4>
                            <p>Get instant answers to your trading questions</p>
                        </div>
                        <div class="feature">
                            <h4>💰 Refer Friends, Earn Rewards</h4>
                            <p>Share your referral code and earn 30% commission on premium subscriptions</p>
                        </div>
                        <p>Ready to start trading? Log in now and explore all features!</p>
                        <p>Best regards,<br>The FOREX AI Trading Team</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # In development mode, just print
            if not (self.smtp_user and self.smtp_password):
                print(f"\n{'='*80}")
                print(f"📧 WELCOME EMAIL (Development Mode)")
                print(f"To: {to_email}")
                print(f"Name: {to_name}")
                print(f"{'='*80}\n")
                return True
            
            # Send actual email if SMTP configured
            message = MIMEMultipart('alternative')
            message['Subject'] = subject
            message['From'] = f"{self.from_name} <{self.from_email}>"
            message['To'] = to_email
            
            part = MIMEText(html_body, 'html')
            message.attach(part)
            
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(message)
            
            print(f"✅ Welcome email sent to {to_email}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send welcome email: {str(e)}")
            return False
