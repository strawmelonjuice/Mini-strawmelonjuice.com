# CynthiaWebsiteEngine-mini

Simplified version of CynthiaWeb. Not supporting most of the features.
Simply put, goal is to run a really
simple server here, serving static stuff and having the client do the rest.

This leaves a lot of customisation options in the bin,
as for example custom formats are out of the optional.

In return, Cynthia Mini comes with pre-made themes with each some customisable options!

## Themes
A Cynthia Mini theme consists of the combination of a predefined colourscheme and layout. You can [add your own](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/contributing/add-theme.md) if you'd like!

[Some themes are coming in!](https://github.com/CynthiaWebsiteEngine/Mini/issues/1)

Also see [list of themes](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/themes.md)

## Functionality

CynthiaWeb-mini has functionality that moves away from the enormous
approach that [CynthiaWebSiteEngine v2 and v3](https://github.com/strawmelonjuice/CynthiaWebSiteEngine)
have, and instead takes an approach closer to that of the
[original `strawmelonjuice.PHP` engine](https://github.com/strawmelonjuice/strawmelonjuice.com).

Part of, or possibly the entirety of [the well-interfaced
`CynthiaV3`'s plugin support](https://www.npmjs.com/package/@cynthiaweb/plugin-api) will be added in afterwards, be it
split over the server and client.

The configuration structure is also simplified,
it now consists of Markdown files and their
corresponding metadata files in JSON.
Global configuration is done in the `cynthia-mini.toml` file.

### Caching

Cynthia Mini diverges from Cynthia "Full" in that on Cynthia "Full", the server processes all the config into simple
HTML, whereas on Cynthia Mini, all the server does is serve up the data. The frontend parses everything.

#### Static mode

Static mode allows you to pre-generate your website content into static files that can be deployed to any web server. When running Cynthia Mini with the `static` or `pregenerate` command, it will:

1. Load your content and configuration from the `content` directory and `cynthia-mini.toml`
2. Generate a complete `site.json` file containing all your site data
3. Create an `index.html` file with the Cynthia Mini client embedded in it to render your site
4. Output everything to an `out` directory that can be deployed anywhere

This approach provides the benefits of a static site generator (hosting on any web server, improved security, faster load times) while retaining the dynamic features of Cynthia Mini through client-side rendering.

To use static mode:
```
cynthiaweb-mini static
```

After generation, you can serve the output directory with any static file server.

### Example config directory structure

```directory
./content/
    index.md
    index.md.meta.json
    about.md
    about.md.meta.json
    projects/
        project1.html
        project1.html.meta.json
        project2.md
        project2.md.meta.json
    articles/
        article1.md
        article1.md.meta.json
        article2.md
        article2.md.meta.json
./cynthia-mini.toml
```

Something like this.
