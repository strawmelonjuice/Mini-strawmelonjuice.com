# CynthiaWebsiteEngine-mini

A lightweight website engine emphasising simplicity and ease of use. Optimised for small to medium-sized websites requiring both static and dynamic capabilities.
Create entire sites out of just a few djot/markdown/html/plaintext files and their json metadata!

## Key Features

- 🚀 Simple setup and configuration
- 🎨 Wide collection of pre-made themes
- 📝 Djot and HTML support (MarkDown support with Pandoc)
- 🔧 Static site generation capabilities
- 🔌 Extensible plugin architecture based on the Cynthia v3 plugin system (coming in v2)

## Documentation

For complete documentation, please visit the [Cynthia Mini Documentation](https://cynthiawebsiteengine.github.io/Mini-docs/#/).

## Quick setup (PLEASE READ THE DOCS INSTEAD!)

```sh
# Install from NPM repositories
bun install -g @cynthiaweb/mini

# Or install using binary installer script
curl -fsSL https://cynthiawebsiteengine.github.io/Mini-docs/assets/install.sh | bash

# See https://cynthiawebsiteengine.github.io/Mini-docs/#/install for more
```

To create a new site:

```sh
# Create a new directory and initialize
mkdir my-site
cd my-site
cynthiaweb-mini init
```

And then host it in dynamic mode:

```sh
cynthiaweb-mini dynamic
```

For more info on modes and commands see the [Cynthia Mini Documentation](https://cynthiawebsiteengine.github.io/Mini-docs/#/) and `cynthiaweb-mini help`.

## Overview

Cynthia Mini is the simplified version of CynthiaWeb that focuses on serving static content while letting the client handle the presentation. It features:

- Create entire sites out of just a few markdown/html/plaintext files and their json metadata
- Pre-made themes with customization options
- Static site generation for easy deployment
- Client-side rendering for dynamic features

For detailed information about configuration, theming, and deployment, check out our [documentation](https://cynthiawebsiteengine.github.io/Mini-docs/#/).

## Example Structure

```directory
./content/
    index.dj
    index.dj.meta.json
    about.md
    about.md.meta.json
    projects/
        project1.html
        project1.html.meta.json
        project2.dj
        project2.dj.meta.json
    articles/
        article1.dj
        article1.dj.meta.json
        article2.dj
        article2.dj.meta.json
./cynthia-mini.toml
```

## Contributing

Contributions are welcome! Whether it's adding new themes, improving documentation, or fixing bugs, please feel free to contribute.

For more info, see <https://cynthiawebsiteengine.github.io/Mini-docs/#/contributing>

## Licence

[AGPLv3 Licence](LICENSE)
