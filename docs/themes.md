# List of Cynthia Mini Themes

> A Cynthia Mini theme consists of the combination of a predefined colour scheme and layout. You can [add your own](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/contributing/add-theme.md) if you'd like!

## How Themes Work

Cynthia Mini uses a theme system that combines colour schemes with layouts to create a complete visual experience.
One of these themes is automatically selected based on your system's light or dark mode preference.

To specify a theme in your `cynthia-mini.toml` file, edit one or both lines of:

```toml
theme = "autumn"
theme_dark = "oceanic"
```

If no theme is specified, the system will default to "autumn" for light mode and
"night" for dark mode.

## Available Themes

### Autumn

Embrace the warm, inviting ambience of fall with the Autumn theme. Features earthy tones and gentle contrasts that create a cosy reading environment.

> **Default Light Theme** - Automatically applied when light mode is preferred

> - Layout: `cindy`
> - Mode: Light
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px

### Autumn Dual

The Autumn colour scheme with the dual layout variation. Preserves the warm earthy tones while adding support for a secondary menu, making it ideal for sites needing contextual navigation options.

> - Layout: `cindy-dual`
> - Mode: Light
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px
> - Special Features: Secondary menu support

### Night

A sophisticated dark mode experience that reduces eye strain while maintaining perfect contrast and readability.

> **Default Dark Theme** - Automatically applied when dark mode is preferred

> - Layout: `cindy`
> - Mode: Dark
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px

### Night Dual

The Night theme with an enhanced layout that includes a secondary menu system. Perfect for dark-mode enthusiasts who need additional navigation options in their website structure.

> - Layout: `cindy-dual`
> - Mode: Dark
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px
> - Special Features: Secondary menu support

### Coffee

Rich and robust like your favourite brew, the Coffee theme delivers a dark aesthetic with deep, warm undertones inspired by coffee hues.

> - Layout: `cindy`
> - Mode: Dark
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px

### Coffee Dual

The Coffee colour scheme paired with our dual-menu layout. Combines rich, warm dark tones with enhanced navigation capabilities that allow for both primary and contextual menu systems.

> - Layout: `cindy-dual`
> - Mode: Dark
> - Font Family: Fira Sans, Ubuntu, Noto Sans
> - Font Size: 15px
> - Monospace Font: Fira Mono, Ubuntu Mono, Noto Mono
> - Monospace Size: 14px
> - Special Features: Secondary menu support

### Oceanic

Cool blues and calming teals create an immersive dark experience. Unlike other themes, Oceanic features its own custom layout and distinctive font pairing, making it perfect for technical content and code snippets.

Oceanic was created as a test, to check how accurate [add theme](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/contributing/add-theme.md) was. However, I decided to keep it.

> - Layout: `oceanic` (custom)
> - Mode: Dark
> - Font Family: Poppins, Open Sans, Roboto
> - Font Size: 16px
> - Monospace Font: Fira Code, JetBrains Mono, Consolas
> - Monospace Size: 14px
> - Special Features: Custom colour palette, supports two menus, enhanced for code display

### GitHub Light

A clean, professional theme based on GitHub's light mode interface. Perfect for documentation and technical content with excellent readability and familiar GitHub styling.

> - Layout: `github`
> - Mode: Light
> - Font Family: -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial
> - Font Size: 16px
> - Monospace Font: SFMono-Regular, Consolas, Liberation Mono
> - Monospace Size: 14px
> - Special Features: GitHub-style code blocks, table formatting

### GitHub Dark

The dark mode counterpart to GitHub Light, offering the same professional experience with reduced eye strain for low-light environments. Features GitHub's dark palette with carefully chosen contrast ratios.

> - Layout: `github`
> - Mode: Dark
> - Font Family: -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial
> - Font Size: 16px
> - Monospace Font: SFMono-Regular, Consolas, Liberation Mono
> - Monospace Size: 14px
> - Special Features: GitHub-style code blocks, syntax highlighting optimised for dark mode

## Layout Comparison

### Cindy Layouts

> - **cindy**
>   - Primary Menu: ✅
>   - Secondary Menu: ❌
>   - Responsive Design: ✅
>   - Post Metadata Display: Right sidebar
>   - Focus: Simplicity
>
> - **cindy-dual**
>   - Primary Menu: ✅
>   - Secondary Menu: ✅
>   - Responsive Design: ✅
>   - Post Metadata Display: Right sidebar
>   - Focus: Navigation

### Other Layouts

> - **oceanic**
>   - Primary Menu: ✅
>   - Secondary Menu: ✅
>   - Responsive Design: ✅
>   - Post Metadata Display: Left sidebar
>   - Focus: Visual appeal
>
> - **github**
>   - Primary Menu: ✅
>   - Secondary Menu: ❌
>   - Responsive Design: ✅
>   - Post Metadata Display: Left sidebar
>   - Focus: Technical content

