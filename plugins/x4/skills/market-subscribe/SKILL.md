---
name: market-subscribe
description: Use when adding email capture to the marketing site, setting up a subscriber list, or wiring Resend/Loops to a sign-up form. Generates a SubscribeForm React component, a /api/subscribe Next.js route handler, and optionally inserts the form into an existing marketing page. Trigger for "add an email sign-up form", "capture emails on the marketing site", "set up a subscriber list", "add a newsletter form", "wire up Resend to my site", or when /market-email has no list to send to yet.
version: 1.0.0
license: MIT
---

# /market-subscribe — Email Capture Scaffolding

Adds a working email sign-up form to the marketing site. Generates a
`SubscribeForm` component and a `/api/subscribe` route handler, wired to
Resend or Loops. The form captures emails from site visitors into your list
so `/market-email` has an audience to send to.

**Arguments:**
- `--provider resend|loops` — override auto-detected provider
- `--page landing|features|custom` — which page to insert the form into

## Process

### Step 0: Load config

Check for `brand/BRAND.md` in the project root. This is the primary source.
If absent, fall back to the `brand:` section in `.claude/agent-team.config.md` (legacy).

From `brand/BRAND.md`, extract:
- **Email provider** — from `## Email List` → `**Provider:**`
- **API key env var** — from `## Email List` → `**API key env var:**`
- **Audience ID** — from `## Email List` → `**Audience ID:**`

Also read `marketing.site_dir` from `.claude/agent-team.config.md` — defaults to `apps/marketing`.

If neither brand source exists and `--provider` was not passed:
"Brand not configured — run `/init-setup` to create `brand/BRAND.md`,
or pass `--provider resend` to proceed with defaults."

If `--provider` was passed, use it regardless of config.

### Step 1: Check what exists

1. Verify `{site_dir}/app/` exists. If not: "No marketing site found at `{site_dir}`. Run `/x4:create` first or set `marketing.site_dir` in config." Stop.

2. Check for existing subscribe infrastructure:
   - `{site_dir}/components/SubscribeForm.tsx` — component already exists?
   - `{site_dir}/app/api/subscribe/route.ts` — API route already exists?

3. If both exist already:
   "Email capture is already set up. To update the provider or audience, edit `app/api/subscribe/route.ts` directly."
   Offer to: show the existing files, update the audience ID, or stop.

4. Check existing landing page for a form or subscribe section:
   - `{site_dir}/app/page.tsx` — scan for `subscribe`, `email`, `newsletter` — if found, note it.

### Step 2: Confirm the plan

Present what will be generated:

```
## Email Capture Setup

Will generate:

  {site_dir}/components/SubscribeForm.tsx
    → React component with email input, loading state, success/error feedback

  {site_dir}/app/api/subscribe/route.ts
    → Next.js route handler → {provider} API → adds to your {audience context}

  {optional} Insert SubscribeForm into {page} page

Provider: {resend or loops}
API key:  ${api_key_env} (must be set in your .env.local)
{If audience_id set}: Audience: {audience_id}
{If not set}: ⚠ No audience_id configured — you'll need to add it to the API route

Continue? (yes / change provider / skip page insertion)
```

### Step 3: Generate SubscribeForm component

Write `{site_dir}/components/SubscribeForm.tsx`:

The component should:
- Be a `'use client'` component
- Manage `email`, `status` (`idle | loading | success | error`), and `message` state
- POST to `/api/subscribe` with `{ email }`
- Disable the input and button while loading and after success
- Show clear feedback for each state
- Accept a `className` prop for layout flexibility
- Accept a `buttonText` prop (default: `"Get updates"`)
- Accept a `placeholder` prop (default: `"your@email.com"`)

Style with Tailwind CSS 4. Match the project's existing Tailwind patterns if detectable — scan a few existing components first. If no existing pattern is clear, use clean neutral defaults:
- Input: `rounded-lg border border-neutral-200 bg-white px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-neutral-900`
- Button: `rounded-lg bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700 disabled:opacity-50`
- Success state: replace the form with a brief confirmation message
- Error state: show message in red below the form

**Example structure (adapt styling to the project):**

```tsx
'use client'

import { useState } from 'react'

interface SubscribeFormProps {
  className?: string
  buttonText?: string
  placeholder?: string
}

export function SubscribeForm({
  className,
  buttonText = 'Get updates',
  placeholder = 'your@email.com',
}: SubscribeFormProps) {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [message, setMessage] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setStatus('loading')
    try {
      const res = await fetch('/api/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      })
      const data = await res.json()
      if (res.ok) {
        setStatus('success')
        setMessage(data.message ?? "You're on the list!")
        setEmail('')
      } else {
        setStatus('error')
        setMessage(data.error ?? 'Something went wrong. Try again.')
      }
    } catch {
      setStatus('error')
      setMessage('Something went wrong. Try again.')
    }
  }

  if (status === 'success') {
    return (
      <p className={className}>
        {message}
      </p>
    )
  }

  return (
    <form onSubmit={handleSubmit} className={className}>
      <div className="flex gap-2">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder={placeholder}
          required
          disabled={status === 'loading'}
          className="..." // adapt to project style
        />
        <button
          type="submit"
          disabled={status === 'loading'}
          className="..." // adapt to project style
        >
          {status === 'loading' ? 'Subscribing...' : buttonText}
        </button>
      </div>
      {status === 'error' && (
        <p className="mt-2 text-sm text-red-600">{message}</p>
      )}
    </form>
  )
}
```

### Step 4: Generate API route

Write `{site_dir}/app/api/subscribe/route.ts`.

**For Resend:**

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.{api_key_env})

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const email = typeof body?.email === 'string' ? body.email.trim() : ''

    if (!email || !email.includes('@')) {
      return NextResponse.json({ error: 'A valid email address is required.' }, { status: 400 })
    }

    await resend.contacts.create({
      audienceId: process.env.RESEND_AUDIENCE_ID ?? '{audience_id}',
      email,
      unsubscribed: false,
    })

    return NextResponse.json({ message: "You're on the list!" })
  } catch (error) {
    console.error('[subscribe] error:', error)
    return NextResponse.json(
      { error: 'Failed to subscribe. Please try again.' },
      { status: 500 }
    )
  }
}
```

**For Loops:**

```typescript
import { NextRequest, NextResponse } from 'next/server'

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const email = typeof body?.email === 'string' ? body.email.trim() : ''

    if (!email || !email.includes('@')) {
      return NextResponse.json({ error: 'A valid email address is required.' }, { status: 400 })
    }

    const res = await fetch('https://app.loops.so/api/v1/contacts/create', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.{api_key_env}}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    })

    if (!res.ok) {
      throw new Error(`Loops error: ${res.status}`)
    }

    return NextResponse.json({ message: "You're on the list!" })
  } catch (error) {
    console.error('[subscribe] error:', error)
    return NextResponse.json(
      { error: 'Failed to subscribe. Please try again.' },
      { status: 500 }
    )
  }
}
```

Use the actual env var names and audience ID from config. If `audience_id` is not set,
add a `// TODO: set RESEND_AUDIENCE_ID in .env.local` comment and note it in the summary.

### Step 5: Insert form into page

Skip if `--page` was not specified and the user chose to skip page insertion in Step 2.

**Determine target page:**
- `landing` → `{site_dir}/app/page.tsx`
- `features` → `{site_dir}/app/features/page.tsx`
- `custom` → ask: "Which page file should the form be added to?"

Read the target page file. Find the best placement:
- If a `{/* market-update:subscribe:start */}` marker exists, replace between markers.
- If there's an existing hero section or CTA section, insert the form after it.
- Otherwise, insert before the closing tag of the main export, wrapped in markers:

```tsx
{/* market-update:subscribe:start */}
<section className="py-16 text-center">
  <h2 className="mb-2 text-xl font-semibold">Stay in the loop</h2>
  <p className="mb-6 text-neutral-500">
    Get notified when new features ship.
  </p>
  <SubscribeForm className="mx-auto flex max-w-sm flex-col gap-3" />
</section>
{/* market-update:subscribe:end */}
```

Add the import at the top of the page file:
```tsx
import { SubscribeForm } from '@/components/SubscribeForm'
```

After inserting, run the linter on the modified file if `test_commands.lint` is configured.

### Step 6: Check package dependency

Check if the provider's package is in `{site_dir}/package.json`:
- Resend: `"resend"` in dependencies
- Loops: no package needed (uses fetch)

If Resend is not installed:
```
The Resend package is not installed in {site_dir}. Install it:

  cd {site_dir} && bun add resend
```

### Step 7: Env var check

Check if the API key env var is set in `.env.local` or `.env`:
- Run: `grep -q "{api_key_env}" {project_root}/.env.local && echo "found" || echo "not found"`

If not found, add a placeholder line to `.env.local`:
```
{api_key_env}=     # get from resend.com/dashboard (or loops.so/settings)
```

If `audience_id` is not in config, also add:
```
RESEND_AUDIENCE_ID=   # get from resend.com/audiences
```

### Step 8: Summary

```
## Email Capture Ready

### Generated
  ✓ {site_dir}/components/SubscribeForm.tsx
  ✓ {site_dir}/app/api/subscribe/route.ts  → {provider}
  {✓ or ○} Inserted into {page} page

### Env vars needed
  {api_key_env}         → {where to get it}
  {RESEND_AUDIENCE_ID}  → resend.com/audiences (create one if needed)

### Install dependency (if needed)
  cd {site_dir} && bun add resend

### Test it
  Start the dev server (bun dev) and try submitting the form at:
  http://localhost:3001

  Check your Resend dashboard → Audiences to confirm the contact appears.

### Next Steps
  - Run /x4:market-email once you have subscribers to send to
  - Customize the form copy in the page file (section text, button label)
  - The SubscribeForm component accepts buttonText and placeholder props
```

## Rules

- Never hardcode API key values — always use `process.env.VAR_NAME`
- Adapt Tailwind classes to match the existing project style — scan existing components first
- If the page insertion would break TypeScript (typecheck fails), revert the insertion and report it
- Always run the linter after writing TSX files if lint is configured
- If `audience_id` is missing, add clear TODO comments in the generated code — don't silently leave it broken
