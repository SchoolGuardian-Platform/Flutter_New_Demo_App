import dotenv from "dotenv";

dotenv.config();

let nodemailer: any = null;
try {
  // Safe dynamic require for Nodemailer
  nodemailer = require("nodemailer");
} catch {
  // Nodemailer is optional/fallback mode enabled
}

export interface IEmailService {
  sendPasswordResetEmail(toEmail: string, resetLink: string): Promise<void>;
  sendVerificationEmail(toEmail: string, firstName: string, verificationLink: string): Promise<void>;
}

export class EmailService implements IEmailService {
  private transporter: any = null;

  constructor() {
    const host = process.env.EMAIL_HOST;
    const port = parseInt(process.env.EMAIL_PORT || "587", 10);
    const user = process.env.EMAIL_USER;
    const pass = process.env.EMAIL_PASSWORD;

    if (nodemailer && host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: {
          user,
          pass,
        },
      });
    }
  }

  /**
   * Sends password reset email.
   * NOTE: Never logs the raw reset token.
   */
  async sendPasswordResetEmail(toEmail: string, resetLink: string): Promise<void> {
    const from = process.env.EMAIL_FROM || "noreply@schoolguardian.com";

    const mailOptions = {
      from,
      to: toEmail,
      subject: "Password Reset Request - SchoolGuardian",
      text: `Hello,\n\nYou requested a password reset for your SchoolGuardian account. Please use the following link to reset your password within 30 minutes:\n\n${resetLink}\n\nIf you did not request this, please ignore this email.\n`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>SchoolGuardian Password Reset</h2>
          <p>Hello,</p>
          <p>You requested a password reset for your SchoolGuardian account. Click the link below to set a new password (valid for 30 minutes):</p>
          <p><a href="${resetLink}" style="background-color: #2563eb; color: white; padding: 10px 18px; text-decoration: none; border-radius: 4px; display: inline-block;">Reset Password</a></p>
          <p>If the button doesn't work, copy and paste this URL into your browser:</p>
          <p><code>${resetLink}</code></p>
          <p>If you did not request a password reset, please ignore this message.</p>
        </div>
      `,
    };

    if (this.transporter) {
      await this.transporter.sendMail(mailOptions);
      console.log(`[EmailService] Password reset email sent successfully to ${toEmail}`);
    } else {
      // Clean fallback mode when email credentials or nodemailer module are not yet present
      console.log(`[EmailService] Email provider transport not active. Simulated dispatch to ${toEmail}`);
    }
  }

  /**
   * Sends email verification link.
   * NOTE: Never logs the raw verification token.
   */
  async sendVerificationEmail(toEmail: string, firstName: string, verificationLink: string): Promise<void> {
    const from = process.env.EMAIL_FROM || "noreply@schoolguardian.com";

    const mailOptions = {
      from,
      to: toEmail,
      subject: "Verify your SchoolGuardian email",
      text: `Hello ${firstName},\n\nThank you for registering with SchoolGuardian.\n\nPlease verify your email address by using the following link within 30 minutes:\n\n${verificationLink}\n\nIf you did not create this account, you can ignore this email.\n\nSchoolGuardian`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>SchoolGuardian Email Verification</h2>
          <p>Hello ${firstName},</p>
          <p>Thank you for registering with SchoolGuardian.</p>
          <p>Please verify your email address by clicking the button below (valid for 30 minutes):</p>
          <p><a href="${verificationLink}" style="background-color: #2563eb; color: white; padding: 10px 18px; text-decoration: none; border-radius: 4px; display: inline-block;">Verify Email</a></p>
          <p>If the button doesn't work, copy and paste this URL into your browser:</p>
          <p><code>${verificationLink}</code></p>
          <p>If you did not create this account, you can ignore this email.</p>
          <p>SchoolGuardian</p>
        </div>
      `,
    };

    if (this.transporter) {
      await this.transporter.sendMail(mailOptions);
      console.log(`[EmailService] Verification email sent successfully to ${toEmail}`);
    } else {
      console.log(`[EmailService] Email provider transport not active. Simulated dispatch of verification email to ${toEmail}`);
    }
  }
}

export const emailService = new EmailService();
