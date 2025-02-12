//// This is a stub implementation of the CUSTOM markdown parser,
//// which is not implemented yet. For now I'll just use kirala's to_html and then string.replace to correct the output.

// import kirala/markdown/html_renderer
// import kirala/markdown/parser
//
// fn tokens_to_html(tokens: List(parser.Token)) -> String {
//   tokens_to_html_internal(tokens, "")
// }
//
// fn tokens_to_html_internal(
//   tokens: List(parser.Token),
//   accumulated: String,
// ) -> String {
//   case tokens {
//     [] -> "" <> accumulated
//     [token, ..rest] -> {
//       case token {
//         parser.BlockQuote(_, _) -> todo
//         parser.Bold(_) -> todo
//         parser.CodeBlock(_, _, _) -> todo
//         parser.CodeLine(_) -> todo
//         parser.CodeSpan(_) -> todo
//         parser.Definition(_) -> todo
//         parser.DefinitionIs(_, _) -> todo
//         parser.DefinitionOf(_) -> todo
//         parser.FootNote(_, _) -> todo
//         parser.FootNoteUrlDef(_, _, _) -> todo
//         parser.H(_, _, _) -> todo
//         parser.HR -> todo
//         parser.ImgLink(_, _, _) -> todo
//         parser.InsertedText(_) -> todo
//         parser.Italic(_) -> todo
//         parser.Line(_) -> todo
//         parser.LineIndent(_, _) -> todo
//         parser.ListItem(_, _, _) -> todo
//         parser.MarkedText(_) -> todo
//         parser.Note(_, _) -> todo
//         parser.StrikeThrough(_) -> todo
//         parser.Table(_, _, _) -> todo
//         parser.Text(_) -> todo
//         parser.Url(_) -> todo
//         parser.UrlLink(_, _) -> todo
//       }
//     }
//   }
// }
