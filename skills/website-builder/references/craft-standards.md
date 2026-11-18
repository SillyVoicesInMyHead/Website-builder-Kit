# Craft standards (what separates a good page from a passable one)

Read this before writing CSS and again when you look at the first screenshot.

## Borrowing a brand look
- Copy the brand's colours, spacing, radii and shadows. Do NOT copy its type weight or
  size if you do not have its typeface. A light weight (300) is designed for a specific
  font; in the system fallback it renders thin and washed out. Without the brand font:
  body 400, headings 500-600, and check the screenshot for strength.
- A brand file describes a finished product with real photography, product shots and
  proof. A page with only tokens applied still looks empty. Say in the notes what
  the brand has that you are replacing it with.

## Type and contrast
- Body text 16px or more; secondary text 14px minimum; nothing under 12px except legal.
- Muted text must reach 4.5:1 against its background. Compute it (a few lines of JS or
  Python); do not estimate. Prefer a darker muted colour over a lighter weight.
- Headings need clear steps in size and weight from body. If all text is the same thin
  grey-blue, there is no hierarchy.

## Composition
- Every section needs one focal point and a clear job. Large flat tinted bands with a
  heading and a few small cards read as a template.
- Hero: the product itself should be the visual (a believable, well-built mockup at a
  readable size, not a small card floating in empty space). Check that the hero fills the
  first screen with purpose; a big empty area beside small text is a failure.
- Pricing: the recommended tier is visibly larger/denser, prices are the biggest numbers,
  the toggle visibly changes them. On phones put the recommended tier first or keep its
  badge fully visible.
- Comparison tables: sticky first column and a visible scroll cue on phones; on narrow
  screens consider one tier per tab instead of a sideways scroll.
- Rhythm: vary section backgrounds and density deliberately; avoid the same padding and
  same card on every section.

## Motion
- Motion should show cause and effect (toggle slides, price changes, details open),
  not decorate. Load `motion-principles` before writing it; skipping it left the run
  unable to confirm any animation worked.

## Self-review before finishing
Look at EVERY section at desktop and phone width in a screenshot (take viewport-sized
shots per section if a full-page capture is cut off). Ask of each: would a designer ship
this? List what looks weak and fix it before reporting. Do not report a page "done" if a
section was never seen rendered.

## Anti-generic rules (from "I Studied 10,000 AI Websites" and a Claude Code web-design workflow)
- **Accent discipline:** one accent colour, used only on what you click. Split roughly 60%
  background, 30% structure, 10% accent. Don't default to Tailwind blue or indigo.
- **Depth, not one flat plane:** a back layer (photo, soft shape, colour block), a middle layer
  (headline, cards) and a front layer (the one CTA, soft shadow). Let one card or image break
  into the next section.
- **Motion has a job:** one thing moves per screen; the first screen's headline, text and button
  are readable at once (no fly-in delay); honour reduced motion. Never `transition: all`.
- **A free sample beats a claim:** where it fits, add a small tool (quiz, estimator,
  calculator) that answers a question customers ask.
- **A product mockup in the hero is fine** when it shows the real product at a readable size;
  label illustrative data. This overrides `tells`' rule against products drawn in divs.
- **When matching a reference, match it:** don't add sections or "improve" it.

## Phones (quick checklist)
- `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`
  and `env(safe-area-inset-*)` padding on full-bleed bars.
- Tap targets at least 44px. Inputs at 16px or more so iOS doesn't zoom the page.
- Hover effects only under `@media (hover: hover)`; nothing important is hover-only.
- Use `100dvh`, not `100vh`, for full-height sections.
- `-webkit-tap-highlight-color: transparent` with your own visible pressed state.
- No horizontal scroll at 375px and 320px; check with a screenshot, not just a width check.
