# Turning on Crema accounts (about 20 minutes, free)

Until you finish these steps, Crema runs exactly like before: no sign-in button, and your data stays in the browser. Once the keys are in, a **Sign in** button shows up in the header.

## 1. Create the Supabase project
1. Go to https://supabase.com, sign up (free plan is fine) and click **New project**. Pick any name and region, and save the database password somewhere safe.
2. Once it's ready, open **SQL Editor → New query**. Paste in everything from `supabase-setup.sql` and click **Run**. You should see "Success". That step creates the usernames table and the table that holds each person's journal. Row Level Security is switched on, so each account can only read its own data.

## 2. Put the two keys into the site
1. In Supabase, open **Project Settings → API Keys** (or **Data API**). Copy:
   - the **Project URL** (`https://xxxx.supabase.co`)
   - the **Publishable key** (`sb_publishable_…`). The legacy **anon** key works too.
2. In `index.html`, find the two lines (search for `SUPABASE_URL`) and paste the values between the quotes:
   ```js
   const SUPABASE_URL='https://xxxx.supabase.co';
   const SUPABASE_ANON_KEY='sb_publishable_…';
   ```
   These keys are designed to be public. The security rules from step 1 are what protect the data. **Never** paste the `service_role` / secret key into the site.

## 3. Tell Supabase where your site lives
In **Authentication → URL Configuration**:
- **Site URL:** `https://crematrading.vercel.app`
- **Redirect URLs:** add `https://crematrading.vercel.app/**`

This is where confirmation emails, password-reset links and Google sign-in send people back to.

## 4. Turn on Google sign-in
1. Go to https://console.cloud.google.com and create a project (any name).
2. Open **Google Auth Platform** (APIs & Services → OAuth consent screen). Set the app name and support email, choose **External** as the audience, and publish the app.
3. Go to **Clients → Create client → Web application**:
   - **Authorized JavaScript origins:** `https://crematrading.vercel.app`
   - **Authorized redirect URIs:** the callback URL shown on Supabase's Google provider page. It looks like `https://xxxx.supabase.co/auth/v1/callback`.
4. Copy the **Client ID** and **Client secret**. In Supabase, open **Authentication → Sign In / Providers → Google**, switch it on, paste both values and save.

## 5. Email sign-up
Email + password is on by default. New accounts get a confirmation email before they can sign in.

Supabase's built-in email sender only sends a few emails per hour. That's fine while it's just you, but before inviting other people, add your own email sender under **Authentication → Emails → SMTP Settings**. Resend, Postmark and SendGrid all have free tiers.

## 6. Deploy
Upload the updated files to your GitHub repo, replacing the old ones. Vercel redeploys automatically.

## How it behaves
- **Signing in is optional.** Without an account, Crema works as before, storing data on that device only.
- **The first time you sign in**, the trades already on that device are uploaded to your account.
- **On another device** that already has its own trades, Crema asks you to choose **Merge both** or **Use account data only**.
- **Every change syncs automatically.** The dot next to your name in the header shows the status: green means synced, amber means syncing, red means a problem (it will retry). If you edit offline, the changes upload when you're back online.
- **When you sign out**, you choose whether to keep a copy on the device or remove it. Remove it on shared computers.
- **Usernames:** email sign-ups pick one when they register. Google users can set one in the account window. After that, people can sign in with either their username or their email.
- **Screenshots attached to trades** are included in the sync, so very screenshot-heavy journals make each save bigger.
