import { Ok as ResultOk, Error as ResultError } from "../../prelude";
import { parse, stringify } from "smol-toml";
import fs from "node:fs";
interface PartialGlobalConfig {
  theme?: string;
  theme_dark?: string;
  colour?: string;
  font?: string;
  font_size?: number;
  site_name?: string;
  site_description?: string;
}
interface GlobaConfig extends PartialGlobalConfig {
  theme: string;
  theme_dark: string;
  colour: string;
  font: string;
  font_size: number;
  site_name: string;
  site_description: string;
}

interface flatGlobalConfig {
  global_theme: string;
  global_theme_dark: string;
  global_colour: string;
  global_font: string;
  global_font_size: number;
  global_site_name: string;
  global_site_description: string;
}

interface flatEntireConfigPartial {
  global: flatGlobalConfig;
}

export function parse_configtoml(
  tomlfile: string,
  default_config: GlobaConfig,
): ResultOk<flatGlobalConfig, unknown> | ResultError<string, any> {
  try {
    const b = fs.readFileSync(tomlfile, "utf8");
    const p = parse(b).global as PartialGlobalConfig;
    const f: GlobaConfig = {
      theme: p.theme ?? default_config.theme,
      theme_dark: p.theme_dark ?? default_config.theme_dark,
      colour: p.colour ?? default_config.colour,
      font: p.font ?? default_config.font,
      font_size: p.font_size ?? default_config.font_size,
      site_name: p.site_name ?? default_config.site_name,
      site_description: p.site_description ?? default_config.site_description,
    };
    return new ResultOk({
      global_theme: f.theme,
      global_theme_dark: f.theme_dark,
      global_colour: f.colour,
      global_font: f.font,
      global_font_size: f.font_size,
      global_site_name: f.site_name,
      global_site_description: f.site_description,
    });
  } catch (e) {
    return new ResultError(Bun.inspect(e));
  }
}

export function config_to_toml(config: flatGlobalConfig): string {
  const c = {
    global: {
      theme: config.global_theme,
      theme_dark: config.global_theme_dark,
      colour: config.global_colour,
      font: config.global_font,
      font_size: config.global_font_size,
      site_name: config.global_site_name,
      site_description: config.global_site_description,
    },
  };
  return stringify(c);
}
