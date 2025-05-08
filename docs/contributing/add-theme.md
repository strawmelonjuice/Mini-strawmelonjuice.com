### Adding a theme

These below steps describe adding a theme for which the layout doesn't exist yet, if you re-use an existing layout, you can skip that step.

#### #1: Fork

Create a [fork](https://github.com/CynthiaWebsiteEngine/Mini/fork) of this repository.

#### #2: Add your definition to `themes.json`.

```json
{
  "name": "mythemename",
  "prevalence": "dark",
  "fonts": ["Fira Sans", "Ubuntu", "Noto Sans"],
  "font-size": 15,
  "fonts-mono": ["Fira Mono", "Ubuntu Mono", "Noto Mono"],
  "font-size-mono": 14,
  "daisyUI": "synthwave",
  "layout": "mylayout"
}
```

For generating your own colorscheme instead of a daisyUI premixed colorscheme name, consider using <https://v4.daisyui.com/theme-generator/>. You can just replace the theme name with the colors object:

```json
{
  "name": "mythemename",
  "prevalence": "dark",
  "fonts": ["Fira Sans", "Ubuntu", "Noto Sans"],
  "font-size": 15,
  "fonts-mono": ["Fira Mono", "Ubuntu Mono", "Noto Mono"],
  "font-size-mono": 14,
  "daisyUI": {
    "mycolorschemename": {
      "primary": "#ff00ff",
      "secondary": "#ff00ff",
      "accent": "#00ffff",
      "neutral": "#ff00ff",
      "base-100": "#ff00ff",
      "info": "#0000ff",
      "success": "#00ff00",
      "warning": "#00ff00",
      "error": "#ff0000"
    }
  },
  "layout": "mylayout"
}
```

Please note that color scheme names need to be unique, and that when you've defined a colorscheme like above, it can be reffered to by name with other layouts.

#### #3 Add your layout

Firstly, create a new layout module by copying + renaming the `cindy_simple.gleam` file in

```
cynthia_websites_mini_client/src/cynthia_websites_mini_client/pottery/molds/
```

This sets you up with cindy-simple as your template.

You'll also have to set some references to your newly created layout. For this, edit

```
cynthia_websites_mini_client/src/cynthia_websites_mini_client/pottery/molds.gleam
```

and update the functions `into()` and `retroactive_menu_update()`, these should have some comments on
them referencing how to add in proper references to your layout.

Now, of course, freely edit your layout module! Thanks to guidance of the robust Gleam type system and the ease of Lustre,
you should have no problem in either using it completely as templating language or as a proper programming language.

Also nice to know, CynthiaMini uses [DaisyUI v4](https://v4.daisyui.com/components/) for all of it's styling, this extends to the layout stylings.

#### #4 Create a PR

> If you don't know how to create a pull request,
> also see: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request>

Of course, this one can be the most scary. But if you ran `bun run test` and the tests are passing, you should be good to go!
Create a PR and wait for it to be reviewed. If you have any questions, feel free to put them in [issues](https://github.com/CynthiaWebsiteEngine/Mini/issues/new/) or email me at <mar@strawmelonjuice.com>.
You can of course also put it your question in the PR, I'll be happy to help you out!
