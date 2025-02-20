export function get_color_scheme() {
  // Media queries the preferred color colorscheme

  if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    return "dark";
  }
  return "light";
}

export function set_data(el: HTMLElement, key: string, val: string) {
  // Set a data attribute on an element
  el.setAttribute("data-" + key, val);
}

export function set_hash(hash: string) {
  // Set the hash of the page
  window.location.hash = hash;
}
