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
export function set_to_404(body: string) {
  document.body.dataset["404"] = "true";
  document.body.classList.value = "bg-base-100 w-[100VW] h-[100VH]";
  document.body.innerHTML = body;
  document.title = "404 - Page Not Found";
}

export function get_inner_html(el: HTMLElement) {
  // Get the innerHTML of an element
  return el.innerHTML;
}
