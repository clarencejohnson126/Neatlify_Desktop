# check-credits (Edge Function)

This function supports:

- `action=check`: validate a user has enough credits for `file_count`
- `action=deduct`: deduct credits after a successful organization
- `action=balance`: return current credit balance

## Why this exists

The production issue we hit was `action=deduct` returning HTTP 500 due to weak input validation and type coercion (e.g. `"file_count": "10"` being treated as a string and corrupting `credits_used` via string concatenation).

This version:

- Strictly parses `file_count` as a non-negative integer (numeric strings allowed, non-numeric rejected)
- Prevents accidental credit corruption from string concatenation
- Uses optimistic concurrency (`credits_used` must match) to avoid lost updates
- Returns consistent JSON shapes for Swift decoding

## Required secrets

This function needs a privileged key to bypass RLS on `profiles`:

- `SUPABASE_SERVICE_ROLE_KEY`

Set it in Supabase:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="..." --project-ref nlvlwrhayrvberdyjgjx
```

## Deploy

```bash
./scripts/deploy-check-credits.sh nlvlwrhayrvberdyjgjx
```

## Smoke test

```bash
export SUPABASE_PROJECT_REF="nlvlwrhayrvberdyjgjx"
export SUPABASE_ANON_KEY="..."
./scripts/smoke-test-check-credits.sh "user@example.com" 10

# Run a real deduction (use a test account)
RUN_DEDUCT=1 ./scripts/smoke-test-check-credits.sh "user@example.com" 10
```

## Repairing corrupted balances (if needed)

If a user’s `credits_used` was corrupted previously, fix it from Supabase SQL Editor:

```sql
select email, credits_total, credits_used, credits_remaining
from profiles
where email = 'user@example.com';

-- Set credits_used to the correct value (example: restore remaining credits to 490)
update profiles
set credits_used = credits_total - 490
where email = 'user@example.com';
```
