@external(javascript, "./files_ffi.ts", "exists")
pub fn file_exist(file: String) -> Bool

@external(javascript, "./files_ffi.ts", "path_join")
pub fn path_join(parts: List(String)) -> String

@external(javascript, "./files_ffi.ts", "path_normalize")
pub fn path_normalize(path: String) -> String
