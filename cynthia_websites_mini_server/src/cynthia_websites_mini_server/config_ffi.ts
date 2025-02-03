import  * as Gleam  from "../../prelude";
import { parse, stringify } from "smol-toml";
import fs from "node:fs";
interface PartialGlobalConfig {
  theme?: string;
  theme_dark?: string;
  colour?: string;
  site_name?: string;
  site_description?: string;
  layout?: string;
}
interface GlobaConfig extends PartialGlobalConfig {
  theme: string;
  theme_dark: string;
  colour: string;
  site_name: string;
  site_description: string;
  layout: string;
}

interface flatGlobalConfig {
  global_theme: string;
  global_theme_dark: string;
  global_colour: string;
  global_site_name: string;
  global_site_description: string;
  global_layout: string;
}

export function parse_configtoml(
  tomlfile: string,
  default_config: flatGlobalConfig,
): Gleam.Ok<flatGlobalConfig, unknown> | Gleam.Error<string, any> {
  try {
    const b = fs.readFileSync(tomlfile, "utf8");
    const p = parse(b).global as PartialGlobalConfig;
    const f: GlobaConfig = {
      theme: p.theme ?? default_config.global_theme,
      theme_dark: p.theme_dark ?? default_config.global_theme_dark,
      colour: p.colour ?? default_config.global_colour,
      site_name: p.site_name ?? default_config.global_site_name,
      site_description:
        p.site_description ?? default_config.global_site_description,
      layout: p.layout ?? default_config.global_layout,
    };
    return new Gleam.Ok({
      global_theme: f.theme,
      global_theme_dark: f.theme_dark,
      global_colour: f.colour,
      global_site_name: f.site_name,
      global_site_description: f.site_description,
      global_layout: f.layout,
    });
  } catch (e) {
    return new Gleam.Error(Bun.inspect(e));
  }
}

export function config_to_toml(config: flatGlobalConfig): string {
  const c = {
    global: {
      theme: config.global_theme,
      theme_dark: config.global_theme_dark,
      colour: config.global_colour,
      site_name: config.global_site_name,
      site_description: config.global_site_description,
      layout: config.global_layout,
    },
  };
  return stringify(c);
}
