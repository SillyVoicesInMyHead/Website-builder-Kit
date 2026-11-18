# Cinematic sites: layered scroll storytelling

The principles, the layered approach and the one-shot brief below come from Nate Herk's videos on building websites with Claude ("I Studied 10,000 AI Websites", "Fable 5.1 Kills AI Website Slop"); the scroll patterns and code are this kit's own.

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
| recent.design (formerly godly.website) | Trending sites, and separate views for heroes, CTAs, footers |
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

### Placing a product into a scene photo

A product dropped into a room photo by flex or padding lands wherever the layout puts it,
which is often in mid-air: a lamp floating over a bed, a bottle hovering over a table. Real
objects stand on something. So:

1. **Plan the contact point in the photo.** Before building, write down which surface the
   object stands on (nightstand top, desk, shelf, floor) and its pixel position in the photo
   file (open the image and read the coordinates). If the photo has no fitting surface,
   generate or pick one that does, or generate the product already in the scene.
2. **Cut it out properly.** Use a real transparent PNG/WebP cutout (alpha from the product's
   silhouette), not `mix-blend-mode` or a radial mask over a black square: blends wash out
   dark parts and masks leave a dark halo.
3. **Pin it to the photo, not the layout.** Map the photo point to the screen with the image's
   own `object-fit: cover` crop, `object-position` and transform, at every viewport size.
   The cutout `el` must be `position: absolute; left: 0; top: 0` inside a box the same size
   and place as the photo's box (the same layer, or a sibling layer with `inset: 0`), and the
   photo's `transform-origin` must be the default centre:

   ```js
   function pin(el, img, px, py, pw) {          // px, py, pw in the photo's own pixels
     if (!img.naturalWidth || !el.naturalWidth) return;  // not loaded yet: the load handler calls again
     const W = img.offsetWidth, H = img.offsetHeight;
     const k = Math.max(W / img.naturalWidth, H / img.naturalHeight);
     const [ox, oy] = getComputedStyle(img).objectPosition.split(' ').map(parseFloat);
     const m = new DOMMatrixReadOnly(getComputedStyle(img).transform); // scale about centre
     let x = (W - img.naturalWidth * k) * ox / 100 + px * k;
     let y = (H - img.naturalHeight * k) * oy / 100 + py * k;
     x = W / 2 + m.a * (x - W / 2) + m.e;  y = H / 2 + m.d * (y - H / 2) + m.f;
     const w = pw * k * m.a, h = w * el.naturalHeight / el.naturalWidth;  // el: the cutout <img>
     el.style.width = w + 'px';
     el.style.transform = `translate(${x - w / 2}px, ${y - h}px)`;        // base sits on the point
   }
   ```

   Call it when both images have loaded (`Promise.all([img.decode(), el.decode()])`, or a
   `load` listener on each), again on resize, and before any reduced-motion early return.
   Keep the cutout hidden (`visibility: hidden`) until the first call has placed it.
4. **Same depth as the photo.** In a parallax stack, give the object's layer the same depth
   factor as the photo layer, or it slides off its surface while scrolling. Keep it above any
   darkening wash layers so it stays the brightest thing in the scene.
5. **Ground it.** A contact shadow or light pool under the base, light spill on the wall
   behind, and a believable size next to the furniture.
6. **Phones crop the photo differently.** Set a phone `object-position` that keeps the surface
   in view, and check the object didn't slide off the screen edge.
7. **Keep the surface on screen at every desktop size.** Run the same mapping for the
   surface's left and right edges at 1280×720, 1440×900, 1920×1080 and 2560 wide. If an edge
   lands off screen, shift `object-position` x or zoom out (a smaller `scale()`).
8. **Anything that passes in front must cover the object and its surface together.** A
   foreground layer (bedding, leaves, a dark wipe) that covers the surface but not the object
   makes it float again, mid-scroll. Remove that layer, keep it below the surface line, or fade
   the object by exactly that layer's opacity at the object's base, read from its position on
   every scroll frame.
9. **Check every scroll state, not just the first screen.** Placement that's right at the
   top of the page can break at 50%, 85% and the end of the section.
10. **One product, every image.** Generated images drift: one may show a knob where another has
    a ring, or a different base shape. Put every image of the product side by side before
    building, and make the copy describe what the pictures show. Crop to the matching detail,
    or regenerate (ask first if it costs credits).

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
  For a pinned photo section, put static gradient edges inside the sticky frame, under the
  text, matching the colours of the sections above and below. They then work with reduced
  motion and without JS, and never cover the captions.
- Text over a bright photo needs its own backing: a soft radial scrim behind it. Behind a
  sticky frame, a `z-index: -1` pseudo-element drops under the photo unless its parent has its
  own `z-index`.
- Fade product layers with `opacity` and dim cards with an overlay's opacity, not `filter`:
  filters repaint on every scroll frame.
- No dead buttons: a call to action on a demo opens something or says honestly what happens.
  A link to its own section reads as broken.
- When two layers clash, fix where they meet; don't delete a layer. Removing a foreground
  layer to stop it crossing the product cured the overlap but left a flat, dark scene. Mask
  the layer instead, with its fade edge set in pixels from the product's measured position
  (a fixed percentage drifts across widths), and turn it off only where the crop leaves it no
  room. After any fix, compare before and after screenshots for lost depth, not just the bug.

## Check: watch it like a visitor

Scroll in steps of about half a screen and screenshot each step, so the screenshots play back
like a video of the scroll. For every pinned section capture start, middle and end. Look for:
layers that leave gaps or show edges, hard cuts between sections, text over busy imagery,
anything out of bounds, and jank. Do the same at phone width. Fix and re-capture the bad steps.

Then a **does-this-make-physical-sense pass**: zoom into each place a product meets the scene
and ask what holds it up. Floating, wrong scale, light from the wrong side, or a dark box around
a cutout is a bug, as serious as clipped text.

Tool notes:
- Headless Chrome or Edge may lay a page out wider than a narrow `--window-size` asks for, so
  take phone screenshots in the browser pane at 375 wide, and read `innerWidth` before trusting
  any phone shot.
- Headless `--screenshot` captures the top of the page only. Scroll states need the browser
  pane or Playwright.
- A screenshot taken right after a scroll or reload can show an earlier frame, or a fade still
  in progress. Read the computed `opacity`, or take a second shot, before judging.
- Background tabs throttle animation frames, so scroll-driven values don't update there.
  Bring the tab to the front before measuring scroll states.
- Prove placement with numbers as well as pictures: the object's rect against the mapped
  surface point, and the transforms of the photo and object layers (they must be equal), at
  each scroll state you check.

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
> Inspiration: [sites], and components from 21st.dev / recent.design. Make up or use the
> branding: [brand]. Get the assets: [generate with … / free stock / SVG]. Every site needs:
> subtle but premium scroll-driven animation, text reveals, layering so the whole site has
> depth as you scroll, and different animations at different depths. Screenshot and verify
> everything while scrolling, desktop and phone: nothing out of bounds, no hard cuts.
