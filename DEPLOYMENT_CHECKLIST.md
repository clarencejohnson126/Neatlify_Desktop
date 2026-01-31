# Neatlify Deployment Checklist

Complete checklist for preparing Neatlify for distribution.

## Pre-Deployment

### Code Preparation

- [ ] **Remove debug code**
  - [ ] Remove test API keys
  - [ ] Remove console.log statements
  - [ ] Remove development shortcuts
  - [ ] Set proper API key obfuscation

- [ ] **Update version numbers**
  - [ ] CFBundleShortVersionString in Info.plist (e.g., "1.0.0")
  - [ ] CFBundleVersion (build number, e.g., "1")
  - [ ] Update AboutSettingsView with version

- [ ] **Configure production API key**
  - [ ] Implement proper API key rotation system
  - [ ] Set up backend key server (if using)
  - [ ] Add fallback mechanisms

- [ ] **Set up Stripe**
  - [ ] Create Stripe account
  - [ ] Set up monthly subscription product ($19.99/month)
  - [ ] Set up lifetime product ($99 one-time)
  - [ ] Update PaymentService.swift with checkout URLs
  - [ ] Configure webhooks for subscription events
  - [ ] Test payment flow end-to-end

### Testing

- [ ] **Functional testing**
  - [ ] Test onboarding flow
  - [ ] Test chat interface
  - [ ] Test file scanning (10, 100, 1000+ files)
  - [ ] Test image organization
  - [ ] Test PDF organization
  - [ ] Test mixed file types
  - [ ] Test undo functionality
  - [ ] Test permissions flow
  - [ ] Test paywall trigger
  - [ ] Test subscription activation

- [ ] **Edge cases**
  - [ ] No internet connection
  - [ ] Invalid API key
  - [ ] Folder access denied
  - [ ] Duplicate filenames
  - [ ] Files in use (can't move)
  - [ ] Disk space full
  - [ ] Empty folders
  - [ ] Large files (>100MB)
  - [ ] Special characters in filenames

- [ ] **Performance testing**
  - [ ] 1000+ images
  - [ ] 500+ PDFs
  - [ ] Large folder trees
  - [ ] Memory usage monitoring
  - [ ] CPU usage monitoring

- [ ] **Security testing**
  - [ ] API key not exposed in binary
  - [ ] No sensitive data in logs
  - [ ] Proper sandbox restrictions
  - [ ] Network requests use HTTPS
  - [ ] User data not persisted insecurely

### App Store Preparation

- [ ] **App metadata**
  - [ ] App name: "Neatlify"
  - [ ] Subtitle: "AI File Organization"
  - [ ] Keywords: file, organize, AI, Claude, automation, productivity
  - [ ] Category: Productivity
  - [ ] Age rating: 4+

- [ ] **App Store description**
  ```
  Organize your files in seconds with AI.

  Neatlify uses Claude AI to intelligently categorize your files based on natural language commands. Simply tell Neatlify how you want to organize, and it handles the rest.

  FEATURES
  • Natural language commands
  • AI-powered categorization
  • Image and PDF analysis
  • Safe operations with preview
  • 7-day undo period
  • Local file processing

  PERFECT FOR
  • Construction managers organizing site photos
  • Photographers sorting by location
  • Accountants grouping receipts
  • Designers organizing by client
  • Anyone with messy folders

  FREE TRIAL
  Try 3 cleanups free. No credit card required.

  SUBSCRIPTION
  • Monthly: $19.99/month (3 cleanups)
  • Lifetime: $99 one-time (unlimited)

  Your files stay on your Mac. We only send content to Claude for analysis, never store anything on our servers.
  ```

- [ ] **Screenshots (required sizes)**
  - [ ] 1280 x 800 px (macOS)
  - [ ] Create 5 screenshots showing:
    1. Welcome/onboarding
    2. Chat interface with example
    3. Organization preview
    4. Progress tracking
    5. Completed organization

- [ ] **App preview video** (optional but recommended)
  - [ ] 30-second demo
  - [ ] Show complete organization flow

- [ ] **Privacy policy**
  - [ ] Create privacy policy page
  - [ ] Host at https://neatlify.com/privacy
  - [ ] Add link to Info.plist

- [ ] **Terms of service**
  - [ ] Create ToS document
  - [ ] Host at https://neatlify.com/terms
  - [ ] Add link to Info.plist

- [ ] **Support page**
  - [ ] Create support/FAQ page
  - [ ] Host at https://neatlify.com/support
  - [ ] Add contact email

### Icons & Assets

- [ ] **App icon**
  - [ ] Design 1024x1024 icon
  - [ ] Add to Assets.xcassets
  - [ ] Include all required sizes:
    - 16x16
    - 32x32
    - 64x64
    - 128x128
    - 256x256
    - 512x512
    - 1024x1024

- [ ] **Document icons** (optional)
  - [ ] Custom file type icons if needed

### Code Signing

- [ ] **Apple Developer Program**
  - [ ] Enroll in Apple Developer Program ($99/year)
  - [ ] Create App ID: com.neatlify.desktop
  - [ ] Create certificates
  - [ ] Create provisioning profiles

- [ ] **Xcode signing**
  - [ ] Select development team
  - [ ] Enable automatic code signing
  - [ ] Verify bundle identifier matches App ID

- [ ] **Notarization setup**
  - [ ] Create App-Specific Password for notarization
  - [ ] Configure notarytool

### Build Configuration

- [ ] **Release build settings**
  - [ ] Optimization Level: Optimize for Speed
  - [ ] Build Configuration: Release
  - [ ] Strip Debug Symbols: Yes
  - [ ] Dead Code Stripping: Yes

- [ ] **Hardened runtime**
  - [ ] Enable Hardened Runtime
  - [ ] Configure exceptions if needed

- [ ] **Entitlements review**
  - [ ] Verify minimal permissions
  - [ ] No unnecessary entitlements

## Deployment Process

### 1. Archive Build

```bash
# Clean build
Product > Clean Build Folder (Shift+Cmd+K)

# Archive
Product > Archive

# Wait for archive to complete
```

### 2. Notarize App

```bash
# Export for notarization
Organizer > Archives > Export > Developer ID

# Notarize
xcrun notarytool submit Neatlify.zip \
  --apple-id your@email.com \
  --team-id TEAM_ID \
  --password app-specific-password \
  --wait

# Staple notarization ticket
xcrun stapler staple Neatlify.app
```

### 3. App Store Submission

- [ ] Upload via Xcode Organizer
- [ ] Fill out App Store Connect information
- [ ] Add screenshots
- [ ] Add description
- [ ] Set pricing
- [ ] Submit for review

### 4. Alternative Distribution (Optional)

If distributing outside App Store:

- [ ] Create DMG installer
- [ ] Notarize DMG
- [ ] Set up download page
- [ ] Configure analytics (if needed)

## Post-Deployment

### Monitoring

- [ ] **Set up monitoring**
  - [ ] Crash reporting (if not using built-in)
  - [ ] Usage analytics
  - [ ] API usage tracking
  - [ ] Stripe webhook monitoring

- [ ] **Create support system**
  - [ ] Support email (support@neatlify.com)
  - [ ] FAQ page
  - [ ] User documentation

### Marketing

- [ ] **Landing page**
  - [ ] Create website: https://neatlify.com
  - [ ] Add demo video
  - [ ] Add pricing information
  - [ ] Add download/purchase links

- [ ] **Social media**
  - [ ] Twitter account
  - [ ] Product Hunt launch
  - [ ] LinkedIn post
  - [ ] Reddit (relevant subreddits)

- [ ] **Content marketing**
  - [ ] Blog post about file organization
  - [ ] Tutorial videos
  - [ ] Case studies

### Legal

- [ ] **Business setup**
  - [ ] Register business entity (LLC recommended)
  - [ ] Set up business bank account
  - [ ] Configure tax collection (if required)

- [ ] **Insurance**
  - [ ] Consider liability insurance

## Version Updates

For future updates:

### Before Each Release

- [ ] Increment version number
- [ ] Update changelog
- [ ] Test upgrade path from previous version
- [ ] Test migration of user data
- [ ] Create release notes

### Release Notes Template

```
Version X.Y.Z

NEW FEATURES
• Feature 1
• Feature 2

IMPROVEMENTS
• Improvement 1
• Improvement 2

BUG FIXES
• Fix 1
• Fix 2

KNOWN ISSUES
• Issue 1 (will fix in next release)
```

## Emergency Procedures

### API Key Compromise

If API key is compromised:
1. Rotate key immediately on Anthropic dashboard
2. Update APIKeyManager.swift
3. Release emergency update
4. Notify users to update

### Critical Bug

If critical bug discovered:
1. Pull app from App Store (if possible)
2. Fix bug immediately
3. Submit expedited review
4. Notify affected users

### Subscription Issues

If Stripe integration fails:
1. Pause new subscriptions
2. Investigate Stripe webhooks
3. Fix integration
4. Resume subscriptions
5. Credit affected users

## Cost Monitoring

### Monthly Cost Tracking

Monitor these costs:
- [ ] Anthropic API usage ($X/month)
- [ ] Stripe fees (2.9% + $0.30 per transaction)
- [ ] Apple Developer Program ($99/year)
- [ ] Hosting (if applicable)

### Break-Even Analysis

Calculate break-even:
- Average API cost per cleanup: $8-15
- Monthly subscribers needed to break even
- Lifetime purchases needed to break even

Adjust pricing if needed.

## App Store Review

### Common Rejection Reasons

Prepare for these:
- [ ] Missing privacy policy
- [ ] Subscription not clearly explained
- [ ] App crashes during review
- [ ] Permissions not justified
- [ ] In-app purchase issues

### Review Timeline

- Initial review: 1-3 days
- Updates: 1-2 days
- Expedited review (emergency): Few hours

## Launch Day Checklist

- [ ] App approved and live on App Store
- [ ] Website live
- [ ] Support email monitored
- [ ] Payment processing tested
- [ ] Monitoring dashboards active
- [ ] Social media posts scheduled
- [ ] Product Hunt launch prepared
- [ ] Press release sent (if applicable)

## Success Metrics

Track these KPIs:
- [ ] Downloads per day
- [ ] Trial-to-paid conversion rate
- [ ] Monthly recurring revenue (MRR)
- [ ] Churn rate
- [ ] Customer acquisition cost (CAC)
- [ ] Lifetime value (LTV)
- [ ] API cost per user
- [ ] Support ticket volume

## Continuous Improvement

Post-launch focus:
- [ ] Gather user feedback
- [ ] Monitor crash reports
- [ ] Track feature requests
- [ ] Analyze usage patterns
- [ ] Optimize API costs
- [ ] Improve conversion rates

---

**Estimated Time to Production:** 4-6 weeks after development complete

**Required Budget:**
- Apple Developer: $99/year
- API costs: Variable based on usage
- Hosting: $5-20/month
- Legal (privacy policy, ToS): $500-2000 one-time

**Launch Readiness:** Check all boxes above before launch!
