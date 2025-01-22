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

Part of, or possibly the entirety of plugin support will be added in afterwards, be it split over the server and client.

The configuration structure is also simplified,
it now consists of Markdown files and their
corresponding metadata files in JSON.
Global configuration is done in the `config.toml` file.

### Caching
Cynthia Mini diverges from Cynthia "Full" in that on Cynthia "Full", the server processes all the config into simple HTML, whereas on Cynthia Mini, all the server does is serve up the data. The frontend parses everything.

Another difference, having to do with this, is that both the frontend and the backend carry a SQLite database for caching purposes. This because the client syncs and only then filters data from the server, and that load can be greatly decreased by keeping data in a database.

On the client side [`SQL.js`](https://sql.js.org/) is used, on the server, the more native [`BunSQLite`](https://bun.sh/docs/api/sqlite) is used (using [`bungibindies`](https://hex.pm/packages/bungibindies), to bind to Bun API's)

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
./config.toml
```

Something like this.
