# Collingwood Cave Cocktail

A 3D vinyl-record invite for a Halloween house party. One static page, served by GitHub Pages.

- `index.html` – the whole site (page, styles, script)
- `come-together.mp3` – 36-second excerpt that plays when the record spins
- `supabase-setup.sql` – guest-list database: run once in the Supabase SQL editor
- `.nojekyll` – tells GitHub Pages to serve files as they are

RSVPs are stored in Supabase. The page holds the project URL and public anon key in the `RSVP` object near the top of its script. The organiser view is at `/#guests` and needs the passphrase set in the `settings` table.
