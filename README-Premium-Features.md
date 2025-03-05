# Soul AI Premium Features Implementation

This document provides instructions for setting up and configuring the premium features in the Soul AI app.

## 1. StoreKit Configuration

The app uses StoreKit for in-app purchases. The configuration is stored in `Soul AI/Configuration/Subscriptions.storekit`.

### Adding the StoreKit Configuration to Xcode

1. Open your Xcode project
2. Right-click on the Soul AI group in the Project Navigator
3. Select "Add Files to 'Soul AI'..."
4. Navigate to and select `Soul AI/Configuration/Subscriptions.storekit`
5. Make sure "Copy items if needed" is unchecked
6. Click "Add"

### Enabling StoreKit Testing in Xcode

1. Select your target in Xcode
2. Go to the "Build Settings" tab
3. Search for "StoreKit"
4. Set "Enable StoreKit Testing" to "Yes"
5. Set "StoreKit Configuration" to your "Subscriptions.storekit" file

## 2. Deploying Supabase Functions

The app uses Supabase Edge Functions for advanced meditation generation. Follow these steps to deploy the function:

### Prerequisites

1. Install the Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Log in to Supabase:
   ```bash
   supabase login
   ```

### Deploying the Function

1. Navigate to the project root directory
2. Deploy the function:
   ```bash
   supabase functions deploy generate-advanced-meditation --project-ref YOUR_PROJECT_REF
   ```
   Replace `YOUR_PROJECT_REF` with your Supabase project reference.

3. Set the required environment variables:
   ```bash
   supabase secrets set OPENAI_API_KEY=your_openai_api_key --project-ref YOUR_PROJECT_REF
   supabase secrets set SUPABASE_URL=your_supabase_url --project-ref YOUR_PROJECT_REF
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key --project-ref YOUR_PROJECT_REF
   ```

## 3. Setting Up App Store Connect for In-App Purchases

When you're ready to release your app with in-app purchases, you'll need to configure them in App Store Connect:

### Creating In-App Purchases

1. Log in to App Store Connect
2. Go to your app > Features > In-App Purchases
3. Click the "+" button to add a new in-app purchase
4. Select "Auto-Renewable Subscription"
5. Enter the Product ID (e.g., com.soulai.premium)
6. Configure the subscription details:
   - Reference Name
   - Subscription Group
   - Subscription Duration
   - Price
   - Localization (display name, description)
   - Review Information

### Creating a Subscription Group

1. In App Store Connect, go to Features > Subscription Groups
2. Create a new subscription group called "Soul AI Subscriptions"
3. Add your subscription products to this group
4. Configure the ranking of subscriptions (Premium < Guided)

### Setting Up Sandbox Testing

1. Go to Users and Access > Sandbox > Testers
2. Add sandbox testers for testing in-app purchases
3. Use these test accounts on your device to test the subscription flow

## 4. Testing In-App Purchases

### Using StoreKit Testing in Xcode

With the StoreKit Configuration file set up, you can test in-app purchases directly in the simulator:

1. Run your app in the simulator
2. Navigate to the subscription screen
3. Tap on a subscription option
4. The StoreKit testing framework will simulate the purchase flow
5. You can approve or decline the purchase in the simulator

### Testing on a Real Device with Sandbox

To test on a real device:

1. Build and run your app on a device
2. Sign out of your regular Apple ID in Settings > App Store
3. Navigate to the subscription screen in your app
4. Tap on a subscription option
5. When prompted to sign in, use your sandbox tester account
6. Complete the purchase flow

## 5. Additional Considerations

### Receipt Validation

For security, you should implement server-side receipt validation:

1. When a purchase is completed, send the receipt to your server
2. Your server should validate the receipt with Apple's servers
3. Update the user's subscription status in your database

### Subscription Management

Provide users with ways to manage their subscriptions:

1. Add a "Manage Subscription" button that opens the App Store subscription management page
2. Implement subscription status checking on app launch
3. Handle subscription expiration gracefully

### Analytics and Tracking

Consider implementing analytics to track subscription conversions:

1. Track when users view the subscription page
2. Track when users start the subscription process
3. Track successful and failed subscription attempts
4. Analyze which features drive subscriptions 