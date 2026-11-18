# Stacks

Read only the section for the languages the user picked.

## HTML + CSS + plain JavaScript (default)

- Every skill in the library map fits. No build step: one `index.html`, `styles.css`, `app.js`.
- Motion: prefer `css-native` before reaching for JavaScript.
- Preview: if the working directory has a `.claude/launch.json` for other projects, don't
  edit it. Serve the site folder with `python -m http.server <port>` through Bash
  with `run_in_background`, then open `http://localhost:<port>` with the browser pane (`navigate`).
  A `file://` page gives no JS or page tools. Stop the server at the end.

## TypeScript

- Same skills as above. Use Vite (`npm create vite@latest`, vanilla-ts template) only if the
  user is fine with a build step; ask in the opening questions if it's unclear.
- Keep types light; this is a site, not a library.

## Rust compiled to WebAssembly

- Use `rust-best-practices` for the Rust side, plus `rust-async-patterns` only if there is async work.
- Build with `wasm-pack build --target web` and load it from plain JS. Keep the page itself
  in HTML/CSS/JS so the design skills still apply.
- Check that `wasm-pack` is installed. If it's missing, ask before installing it.

## React / Svelte / Vue

- No framework skill is installed. Say so once, then use general knowledge for the framework.
- The design, motion, mobile, accessibility and check skills all still apply, because they
  are about the result, not the framework.
- Before adding any outside framework skill, run `skill-inspector` on it.

## Hosting

- **Cloudflare:** `wrangler` + `workers-best-practices`. Deploy only on the user's yes.
- **GitHub Pages / static host:** plain build output. Pushing to GitHub needs the user's yes.
- **Local only / decide later:** stop at a working local preview.
