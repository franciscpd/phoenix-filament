# Theming Guide

PhoenixFilament uses daisyUI 5's theme system, which is built on CSS custom properties
(variables). This means themes apply instantly without a rebuild and can be customized per
panel.

## Built-in daisyUI Themes

daisyUI 5 ships 35+ themes. Set one per panel with the `theme:` option:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  theme: "corporate"
```

Popular choices:

| Theme name | Style |
|------------|-------|
| `"light"` | Clean light default |
| `"dark"` | Dark background |
| `"corporate"` | Professional, blue-grey |
| `"retro"` | Warm, vintage palette |
| `"cyberpunk"` | Neon yellow + dark |
| `"cupcake"` | Soft pastels |
| `"bumblebee"` | Yellow + warm tones |
| `"emerald"` | Greens and teals |
| `"synthwave"` | Neon purple + dark |
| `"dracula"` | Classic dark purple |
| `"night"` | Navy dark |
| `"dim"` | Muted dark |
| `"nord"` | Arctic blues |
| `"sunset"` | Warm orange gradient |
| `"forest"` | Earth greens |
| `"aqua"` | Ocean blues |
| `"lemonade"` | Bright lemon yellow |
| `"valentine"` | Pink and red |
| `"halloween"` | Orange and dark |
| `"garden"` | Soft pinks |
| `"fantasy"` | Purple fantasy |
| `"wireframe"` | Minimal, black/white |
| `"black"` | Pure dark |
| `"luxury"` | Gold on black |
| `"cmyk"` | Print-style CMYK |
| `"autumn"` | Deep reds and golds |
| `"acid"` | Neon green |
| `"lofi"` | Muted monochrome |
| `"pastel"` | Soft pastel rainbow |
| `"business"` | Dark professional |
| `"coffee"` | Warm browns |
| `"winter"` | Cool icy tones |

## Dark Mode Toggle

Add a light/dark toggle button to the panel header:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  theme: "corporate",
  theme_switcher: true
```

When `theme_switcher: true`, a sun/moon toggle appears in the top navigation bar. It uses
daisyUI's `theme-controller` mechanism — clicking it switches between your configured
`theme` and `"dark"`.

If you want to control which dark theme is used with `theme_switcher`, you can render the
`PhoenixFilament.Components.Theme.theme_switcher/1` component directly in a custom layout:

```heex
<PhoenixFilament.Components.Theme.theme_switcher
  light_theme="corporate"
  dark_theme="dracula"
/>
```

## CSS Variable Overrides

Every daisyUI theme is defined through CSS custom properties. You can override individual
colors without replacing the entire theme by adding CSS to your `assets/css/app.css`:

```css
/* Override just the primary color in the corporate theme */
[data-theme="corporate"] {
  --color-primary: oklch(60% 0.2 270);
  --color-primary-content: oklch(98% 0.01 270);
}
```

Available CSS variables (all use OKLCH color format in daisyUI 5):

| Variable | Description |
|----------|-------------|
| `--color-primary` | Primary brand color |
| `--color-primary-content` | Text on primary backgrounds |
| `--color-secondary` | Secondary accent color |
| `--color-secondary-content` | Text on secondary backgrounds |
| `--color-accent` | Accent highlight color |
| `--color-accent-content` | Text on accent backgrounds |
| `--color-neutral` | Neutral surface color |
| `--color-neutral-content` | Text on neutral backgrounds |
| `--color-base-100` | Main background |
| `--color-base-200` | Slightly darker background |
| `--color-base-300` | Even darker background |
| `--color-base-content` | Main text color |
| `--color-info` | Informational color |
| `--color-success` | Success/positive color |
| `--color-warning` | Warning color |
| `--color-error` | Error/danger color |

## Brand Customization

### Brand name

Set the text displayed in the sidebar header:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  brand_name: "Acme Admin"
```

### Logo

Replace the text brand name with an image:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  brand_name: "Acme Admin",
  logo: "/images/logo.svg"
```

When `logo:` is set, the sidebar header renders the image instead of the brand name text.
The `brand_name` is still used for the page `<title>` and accessibility attributes.

## Per-Panel Theme Isolation

If your application has multiple panels (e.g. a customer portal and a superadmin panel),
each can have a different theme:

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    theme: "corporate",
    brand_name: "Staff Admin"
end

defmodule MyAppWeb.SuperAdmin do
  use PhoenixFilament.Panel,
    path: "/superadmin",
    theme: "dark",
    brand_name: "Super Admin"
end
```

Each panel applies its theme via the `data-theme` attribute scoped to the panel layout —
themes do not leak between panels or into the host application.
