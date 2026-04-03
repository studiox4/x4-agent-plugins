# Brand — {{BRAND_NAME}}

> Edit this file freely. All x4 marketing skills read from it automatically —
> /market-update, /market-email, /market-linkedin, /market-tweet, and /market-subscribe.
>
> Add logo and image files to `brand/assets/` and update the paths below.
> Changes take effect the next time you run any marketing command.

---

## Identity

**Name:** {{BRAND_NAME}}
**Tagline:** {{BRAND_TAGLINE}}
**One-liner:** {{BRAND_DESCRIPTION}}

---

## Voice & Tone

**Voice:** {{BRAND_VOICE}}
**Audience:** {{BRAND_AUDIENCE}}

Write like you're explaining something to a smart colleague — not writing a press release.

| Do | Avoid |
|----|-------|
| Be specific — name the actual command or file | Buzzwords (leverage, synergize, empower) |
| Show, don't tell | Hyperbole (revolutionary, game-changing) |
| Lead with user benefit | Leading with internal mechanism |
| Use the product's actual words | Paraphrasing into marketing-speak |

---

## Colors

**Primary:** #000000
**Accent:** #6366f1
**Background:** #ffffff
**Text:** #171717

> Update these to match your brand. Used in email templates and marketing site.

---

## Logo & Visual Assets

Add your files to `brand/assets/`. Update the paths here so marketing skills
know which asset to use where.

| Asset | Path | When to Use |
|-------|------|-------------|
| Logo (light bg) | brand/assets/logo.svg | Email headers, docs, light backgrounds |
| Logo (dark bg) | brand/assets/logo-dark.svg | Dark headers, Twitter/LinkedIn banners |
| Icon | brand/assets/logo-icon.svg | Favicon, social media avatar, app icon |
| OG Image | brand/assets/og-image.png | Open Graph (1200×630) — link previews everywhere |
| Social Banner | brand/assets/banner.png | Twitter/LinkedIn profile header image |

**Asset tips:**
- Use SVG for logos — scalable, small file size, works everywhere
- Use PNG for OG images and photos — 1200×630px for Open Graph
- For email: host assets on your domain or a CDN (`assets.yourdomain.com`)
  Email clients block localhost and most cloud storage URLs

---

## Social & Contact

**Twitter/X:** {{TWITTER_HANDLE}}
**LinkedIn:** {{LINKEDIN_URL}}
**Website:** {{WEBSITE_URL}}
**Email from:** {{EMAIL_FROM}}
**Hashtags:** {{HASHTAGS}}

---

## Email List

**Provider:** {{EMAIL_PROVIDER}}
**API key env var:** {{EMAIL_API_KEY_ENV}}
**Audience ID:** {{EMAIL_AUDIENCE_ID}}
**From name:** {{BRAND_NAME}} Updates

> The audience ID is created in your Resend dashboard (resend.com/audiences)
> or your Loops account. Set it here so /market-email knows where to send.

---

## Marketing Channel Priority

Which channels matter most? Marketing skills use this order when suggesting next steps.
Reorder or remove lines to match your priorities.

1. Marketing site (`/x4:market-update`)
2. Email list (`/x4:market-email`)
3. Twitter/X (`/x4:market-tweet`)
4. LinkedIn (`/x4:market-linkedin`)

---

## X / Twitter API (optional)

Enable `--post` in `/x4:market-tweet` to post threads programmatically.

**API key env var:** {{X_API_KEY_ENV}}

> Leave as-is if you prefer copy-paste posting. Set the env var and update
> this file when you're ready for programmatic posting.
