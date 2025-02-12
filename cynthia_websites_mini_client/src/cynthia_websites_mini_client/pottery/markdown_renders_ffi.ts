import markdownit from "markdown-it";
import Token from "markdown-it/lib/token.mjs";

// commonmark mode
const markdown = markdownit("commonmark");

export function custom_render(text: string): string {
  let mdast = markdown.parse(text, {});
  mdast.forEach((token: Token) => {
    (function find_link_refs(current_token) {
      switch (current_token.type) {
        case "link_open":
          //         type: "link_open",
          // tag: "a",
          // attrs: [["href", "/about"]],
          // If the link is a relative link, add a hashbang to it
          if (
            current_token.attrs !== null &&
            current_token.attrs[0][1].startsWith("/") &&
            !current_token.attrs[0][1].startsWith("/#")
          ) {
            const original_href: string = current_token.attrs[0][1];
            const new_href: string = "/#" + original_href;
            current_token.attrs[0][1] = new_href;
            console.log(original_href + " -> " + current_token.attrs[0][1]);
          }
          break;
        case "inline":
          {
            // Recurse
            if (
              current_token.children !== null &&
              current_token.children !== undefined
            ) {
              current_token.children.forEach(find_link_refs);
            }
          }
          break;
        default:
          // console.log("Unhandled token type: " + current_token.type);
          break;
      }
    })(token);
  });
  const rendered = markdown.renderer.render(mdast, {}, {});
  return rendered;
}
