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
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    original_filename: string;
  }[];
  private contentStore: Map<
    string,
    {
      html: string;
      original_filename: string;
      meta_title: string;
      meta_description: string;
      meta_kind: number;
      meta_permalink: string;
      last_inserted_at: string;
    }
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
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    original_filename: string;
  }) {
    this.contentQueue.push(content);
  }
  content_queue_next(
    cb: (
      arg0:
        | {
            meta_title: string;
            meta_description: string;
            meta_kind: number;
            meta_permalink: string;
            last_inserted_at: string;
            original_filename: string;
          }
        | undefined,
    ) => void,
  ) {
    if (this.contentQueue.length > 0) {
      const content = this.contentQueue.shift();
      cb(content);
    }
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
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    original_filename: string;
  },
): void {
  store.add_to_content_queue(content);
}

export function next_in_content_queue(
  store: ClientStore,
  cb: (
    arg0:
      | {
          meta_title: string;
          meta_description: string;
          meta_kind: number;
          meta_permalink: string;
          last_inserted_at: string;
          original_filename: string;
        }
      | undefined,
  ) => void,
) {
  store.content_queue_next(cb);
}
