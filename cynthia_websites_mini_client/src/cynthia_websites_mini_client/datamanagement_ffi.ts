interface flatGlobalConfig {
  global_theme: string;
  global_theme_dark: string;
  global_colour: string;
  global_site_name: string;
  global_site_description: string;
}

class ClientStore {
  global: {
    theme: string;
    theme_dark: string;
    colour: string;
    site_name: string;
    site_description: string;
  };
  private contentQueue: {
    html: string;
    permalink: string;
    type: number;
    filename: string;
  }[];
  private contentStore: Map<
    string,
    { html: string; permalink: string; type: number; filename: string }
  >;
  constructor(global_config: flatGlobalConfig) {
    this.global = {
      theme: global_config.global_theme,
      theme_dark: global_config.global_theme_dark,
      colour: global_config.global_colour,
      site_name: global_config.global_site_name,
      site_description: global_config.global_site_description,
    };
    this.contentQueue = [];
    this.contentStore = new Map();
  }
  add_to_content_queue(content: {
    html: string;
    permalink: string;
    type: number;
    filename: string;
  }) {
    this.contentQueue.push(content);
  }
  update(global_config: flatGlobalConfig) {
    this.global = {
      theme: global_config.global_theme,
      theme_dark: global_config.global_theme_dark,
      colour: global_config.global_colour,
      site_name: global_config.global_site_name,
      site_description: global_config.global_site_description,
    };
  }
}

export function initialise(config: flatGlobalConfig) {
  const store = new ClientStore(config);
  return store;
}

export function populate_global_config(
  store: ClientStore,
  config: flatGlobalConfig,
): void {
  store.update(config);
}

export function get_config_item(store: ClientStore, item: string): string[] {
  switch (item) {
    case "theme":
      return [store.global.theme];
    case "theme_dark":
      return [store.global.theme_dark];
    case "colour":
      return [store.global.colour];
    case "site_name":
      return [store.global.site_name];
    case "site_description":
      return [store.global.site_description];
    default:
      return [];
  }
}

export function add_to_content_queue(
  store: ClientStore,
  content: {
    html: string;
    permalink: string;
    type: number;
    filename: string;
  },
): void {
  store.add_to_content_queue(content);
  console.log(store);
}
