import markdownit from "markdown-it";
import Token from "markdown-it/lib/token.mjs";

// commonmark mode
const markdown = markdownit("commonmark");

export function custom_render(
  text: string,
  phone_home_url: () => string,
): string {
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
            !current_token.attrs[0][1].startsWith(phone_home_url() + "#")
          ) {
            const original_href: string = current_token.attrs[0][1];
            const new_href: string = phone_home_url() + "#" + original_href;
            current_token.attrs[0][1] = new_href;
            // console.log(original_href + " -> " + current_token.attrs[0][1]);
          }
          current_token.attrSet("class", "text-info underline");
          break;
        case "bullet_list_open":
          current_token.attrSet("class", "list-disc list-inside");
          break;
        case "ordered_list_open":
          current_token.attrSet("class", "list-decimal list-inside");
          break;
        case "paragraph_open":
          current_token.attrSet("class", "mb-2");
          break;
        case "strong_open":
          current_token.attrSet("class", "font-bold");
          break;
        case "em_open":
          current_token.attrSet("class", "italic");
          break;
        case "code_inline":
          current_token.attrSet(
            "class",
            "bg-neutral text-neutral-content p-1 rounded-lg",
          );
          break;
        case "fence":
          const lang = current_token.info;
          current_token.attrSet(
            "class",
            "bg-neutral text-neutral-content pl-4 block ml-2 mr-2 overflow-x-auto break-none whitespace-pre-wrap font-mono border-dotted border-2 border-neutral-content",
          );
          break;
        case "blockquote_open":
          current_token.attrSet(
            "class",
            "border-l-4 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
          );
          break;
        case "heading_open":
          let classes = "";
          switch (token.tag) {
            case "h1":
              classes = "text-4xl font-bold text-accent";
              break;
            case "h2":
              classes = "text-3xl font-bold text-accent";
              break;
            case "h3":
              classes = "text-2xl font-bold text-accent";
              break;
            case "h4":
              classes = "text-xl font-bold text-accent";
              break;
            case "h5":
              classes = "text-lg font-bold text-accent";
              break;
            case "h6":
              classes = "font-bold text-accent";
              break;
          }
          current_token.attrSet("class", classes);
          break;
        case "image":
        // I'm not sure what to do with images yet
        case "text":
        case "softbreak":
        case "list_item_open":
          // ignore text tokens
          break;
        case "inline":
        case "html_inline":
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
          if (!current_token.type.endsWith("_close")) {
            console.warn(
              `Unhandled token type:\n\t${current_token.type} == <${current_token.tag}>`,
            );
          }
          break;
      }
    })(token);
  });
  const rendered = markdown.renderer.render(mdast, {}, {});
  return rendered;
}
