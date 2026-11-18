# Cinematic sites: layered scroll storytelling

Read this for any site meant to feel premium, "Apple-like", award-worthy or "not AI-made".
That is the default look unless the user asked for something plain.

## Why AI sites look flat, and what fixes it

A page made only of CSS boxes, gradients and text will look generic however good the
type is. Premium sites have three things generic ones lack:

1. **Real imagery in layers.** A background, a middle layer, the product or subject, and a
   foreground, each a separate image (PNG/WebP with transparency, or SVG) that moves at its
   own speed as you scroll. This depth is the single biggest difference.
2. **Scroll feedback.** Something answers every scroll: words reveal, cards stack, a product
   turns, a video scrubs. The visitor feels in control.
3. **Borrowed taste.** The look is taken from real sites the user likes, not invented.

"Make it premium" or "subtle animations" in a prompt produces none of these. Plan them
explicitly.

## Seven principles (check the plan against these before building)

1. **Brand:** logo, colours, type. If there's none, make a small one and stick to it.
2. **The three Ps:** the pain being solved, the person who has it, the promise of how the
   product solves it. These drive the copy and the order of the scroll story.
3. **Scroll responsiveness:** the page reacts to scrolling. Not every section flies; even
   words appearing as they enter is enough between the big moments.
4. **Inspiration:** 2 or 3 real sites, with a note of exactly what to borrow from each
   (the layered hero, the card stack, the pricing feel).
5. **Components:** reuse proven component patterns (see galleries) instead of inventing.
6. **Mobile:** the same feel on a phone, adapted (shorter pins, fewer layers if needed).
7. **Verification:** watch it by scrolling, frame by frame (see Check below).

## Where to look

| Gallery | Good for |
|---|---|
| godly.website | Trending sites, and separate views for heroes, CTAs, footers |
| awwwards.com | Award winners by industry (pick the user's niche) |
| 21st.dev | Components with a "copy prompt" button: backgrounds, scroll containers, cards, FAQs |
| motionsites (search "motion sites animated backgrounds") | Animated hero backgrounds |
| land-book.com, lapa.ninja, saaslandingpage.com | Landing pages by category |
| apple.com product pages | The reference for pinned, scrubbed product scroll |

Open the chosen sites in the browser pane and scroll them. Write down what moves, how fast,
and in what order, then copy that feel. `library/design-md/<brand>/DESIGN.md` covers a brand's
type and colour; galleries cover composition and motion.

## Assets: get real images before writing CSS

Decide the layers first (for example: sky, far hills, product, foreground leaves), then get
one image per layer. In order of preference:

1. **An image-generation tool the user has connected** (an MCP image tool, Krea, Higgsfield,
   Figma's image generation). These usually cost credits, so ask once with the count and
   rough cost before generating. Ask for cutouts on a plain background so they can be
   separated.
2. **Free stock photos** from Unsplash or Pexels (free licenses; credit the photographer in
   the footer or README). Search the site in the browser pane, download with `curl` into
   `assets/`. Prefer photos that already separate into layers (a product on a clean
   background, a landscape with clear depth).
3. **SVG layers you draw**: ridgelines, foliage, abstract shapes. Good for backgrounds and
   foregrounds; build the hero subject from a photo when you can.

Making layers from one photo: put the photo as the back layer, then add foreground SVG shapes
(leaves, ridges, haze) and a soft gradient overlay as separate layers. A `mask-image` or
`clip-path` can cut a subject out of a clean background. Never ship a hero with no imagery.

## Scroll patterns (pick 3 to 5; one or two are the big moments)

| Pattern | Build |
|---|---|
| **Layered parallax hero** | Stack layers with `position: absolute` in a sticky or tall section; move each with `translate3d` by scroll progress × its depth factor (back slow, front fast) |
| **Word-by-word reveal** | Split text into spans; animate opacity/translate per word with CSS `animation-timeline: view()` and staggered `animation-range`, or GSAP |
| **Sticky card stack** | Cards with `position: sticky; top: <offset + i*12px>` so each new card slides over the last, slightly scaled down |
| **Pinned product sequence** | A section 300-400vh tall with a sticky inner frame; scroll progress picks the frame of an image sequence on `<canvas>`, or rotates/explodes an SVG or layered product |
| **Scroll-scrubbed video** | For a "growing" or "light turns on" moment. Prefer an image sequence; video `currentTime` scrubbing is choppy |
| **Horizontal scroll band** | A sticky section whose inner track moves sideways as you scroll down |
| **Number tickers** | Count up when the stat enters view (only real or clearly illustrative numbers) |
| **Pointer-reactive background** | A soft gradient or mesh that follows the mouse slightly; off on touch |
| **Sticky nav** | A compact nav that stays on top after the hero |

Plain HTML/CSS/JS: native CSS scroll-driven animations for reveals; GSAP + ScrollTrigger
(exact version from a CDN) for pinned and scrubbed sequences; Lenis only if scroll feels jerky.

### Layered parallax starter

```html
<section class="hero" style="height:180vh">
  <div class="stage" style="position:sticky;top:0;height:100vh;overflow:hidden">
    <img class="layer" data-depth="0.15" src="assets/sky.webp" alt="">
    <img class="layer" data-depth="0.35" src="assets/hills.webp" alt="">
    <img class="layer" data-depth="0.6"  src="assets/product.webp" alt="Product name">
    <img class="layer" data-depth="0.9"  src="assets/foreground.webp" alt="">
    <h1 class="hero-title">…</h1>
  </div>
</section>
<script>
const layers = [...document.querySelectorAll('.layer')];
const hero = document.querySelector('.hero');
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
function tick() {
  const p = Math.min(1, Math.max(0, -hero.getBoundingClientRect().top / hero.offsetHeight));
  for (const l of layers) l.style.transform = `translate3d(0, ${-p * 300 * l.dataset.depth}px, 0)`;
}
if (!reduce) { addEventListener('scroll', () => requestAnimationFrame(tick), { passive: true }); tick(); }
</script>
```

## Rules that keep it from feeling cheap or broken

- One or two signature moments; the rest gets quiet reveals. No fly-through-a-3D-world unless
  the brand calls for it.
- First screen: headline, one line and the button are readable immediately.
- Animate only `transform` and `opacity`. Size images to their display size; use WebP/AVIF.
- `prefers-reduced-motion: reduce`: show final states, no scrubbing or parallax.
- Phones: shorter pinned sections, fewer layers if it janks, no hover-only effects.
- Content reads correctly if JS fails.
- No hard cuts between sections: overlap the next section's background into the last layer.

## Check: watch it like a visitor

Scroll in steps of about half a screen and screenshot each step, so the screenshots play back
like a video of the scroll. For every pinned section capture start, middle and end. Look for:
layers that leave gaps or show edges, hard cuts between sections, text over busy imagery,
anything out of bounds, and jank. Do the same at phone width. Fix and re-capture the bad steps.

## Clone a reference, then rebrand

When the user likes a specific site:

1. Open it in the browser pane, scroll it, and screenshot it in steps.
2. Read the key computed styles (fonts, sizes, colours, spacing) with `javascript_tool`.
3. Build a faithful version of its structure and motion first, without adding or "improving".
4. Second pass: swap in the user's brand, copy (from the three Ps) and assets.

Don't reuse a real company's name, logo, photos or exact copy.

## A one-shot brief that works

When the user wants a quick, ambitious first version, brief the build like this (fill in):

> Build [one / two distinctly different] [product] sites that could win a design award.
> Inspiration: [sites], and components from 21st.dev / godly.website. Make up or use the
> branding: [brand]. Get the assets: [generate with … / free stock / SVG]. Every site needs:
> subtle but premium scroll-driven animation, text reveals, layering so the whole site has
> depth as you scroll, and different animations at different depths. Screenshot and verify
> everything while scrolling, desktop and phone: nothing out of bounds, no hard cuts.
