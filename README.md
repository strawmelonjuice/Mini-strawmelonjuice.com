# CynthiaWebsiteEngine-mini

Simplified version of CynthiaWeb. Not supporting most of the features.
Simply put, goal is to run a really
simple server here, serving static stuff and having the client do the rest.

This leaves a lot of customization options in the bin,
as for example custom formats are out of the optional.

## Functionality

CynthiaWeb-mini has functionality that moves away from the enormous
approach that [CynthiaWebSiteEngine](https://github.com/strawmelonjuice/CynthiaWebSiteEngine)
has, and instead takes an approach closer to that of the
original `strawmelonjuice.PHP` engine.

The configuration structure is also simplified,
it now consists of Markdown files and their
corresponding metadata files in JSON.
Global configuration is done in the `config.jsonc` file.

### Example directory structure

```filetree
./content/
    index.md
    index.md.meta.jsonc
    about.md
    about.md.meta.jsonc
    projects/
        project1.html
        project1.html.meta.jsonc
        project2.md
        project2.md.meta.jsonc
    articles/
        article1.md
        article1.md.meta.jsonc
        article2.md
        article2.md.meta.jsonc
./config.jsonc
```

Something like this.
