# CynthiaWebsiteEngine-mini

Simplified version of CynthiaWeb. Not supporting most of the features.
Simply put, goal is to run a really
simple server here, serving static stuff and having the client do the rest.

This leaves a lot of customization options in the bin,
as for example custom formats are out of the optional.

In return, Cynthia Mini comes with pre-made themes with each some customisable options!

## Themes

... Uh, well, that's awkward, I haven't come to this part yet ...

### Default theme

The default theme for light mode will be based on the DaisyUI "autumn" theme (light) or the "coffee" theme (dark), using
Fira Sans as default font and using
the "Cyndy" layout templates.

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

Another difference, having to do with this, is that both the frontend and the backend carry a SQLite database for
caching purposes. This because the client syncs and only then filters data from the server, and that load can be greatly
decreased by keeping data in a database.

On the client side [`SQL.js`](https://sql.js.org/) is used, on the server, the more native
[`BunSQLite`](https://bun.sh/docs/api/sqlite) is used (using [`bungibindies`](https://hex.pm/packages/bungibindies), to
bind to Bun API's)

#### Database-only

Because Cynthia Mini first loads config to a SQLite database and then uses it, it can also run in database-only mode,
where there is no config directory, and only an SQLite database to run off directly.

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
./cache.db
```

Something like this.
