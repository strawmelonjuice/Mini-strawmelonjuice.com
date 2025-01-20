import { Ok as ResultOk, Error as ResultError } from "../../prelude";
import { parse } from "smol-toml";
import fs from "node:fs";
interface PartialConfigToml {
  global_theme?: string;
  global_theme_dark?: string;
  global_colour?: string;
  global_font?: string;
  global_font_size?: number;
  global_site_name?: string;
  global_site_description?: string;
}
interface ConfigToml extends PartialConfigToml {
  global_theme: string;
  global_theme_dark: string;
  global_colour: string;
  global_font: string;
  global_font_size: number;
  global_site_name: string;
  global_site_description: string;
}
const default_config: ConfigToml = {
  global_theme: "autumn",
  global_theme_dark: "coffee",
  global_colour: "#FFFFFF",
  global_font: "Fira Sans",
  global_font_size: 12,
  global_site_name: "My Site",
  global_site_description: "A big site on a mini Cynthia!",
};

export function parse_configtoml(
  tomlfile: string,
): ResultOk<ConfigToml, unknown> | ResultError<string, any> {
  try {
    const b = fs.readFileSync(tomlfile, "utf8");
    const p = parse(b).config as PartialConfigToml;
    const f: ConfigToml = {
      global_theme: p.global_theme ?? default_config.global_theme,
      global_theme_dark:
        p.global_theme_dark ?? default_config.global_theme_dark,
      global_colour: p.global_colour ?? default_config.global_colour,
      global_font: p.global_font ?? default_config.global_font,
      global_font_size: p.global_font_size ?? default_config.global_font_size,
      global_site_name: p.global_site_name ?? default_config.global_site_name,
      global_site_description:
        p.global_site_description ?? default_config.global_site_description,
    };
    return new ResultOk(f);
  } catch (e) {
    return new ResultError(e.toString());
  }
}
