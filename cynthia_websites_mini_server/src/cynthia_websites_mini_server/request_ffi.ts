import type { BunFile } from "bun";
import { Ok as GleamOk, Error as GleamError } from "../../prelude";

export async function get_request_body(req: Request) {
  let a = req.body!;
  const chunks: Uint8Array[] = [];
  const reader = a.getReader();
  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    } else {
      chunks.push(value);
    }
  }
  return concatArrayBuffers(chunks);
}

export async function get_request_body_as_text(req: Request): Promise<string> {
  const bits = await get_request_body(req);
  const decoder = new TextDecoder("utf-8");
  return decoder.decode(bits);
}

function concatArrayBuffers(chunks: Uint8Array[]): Uint8Array {
  const result = new Uint8Array(chunks.reduce((a, c) => a + c.length, 0));
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

export async function answer_bunrequest_with_file(file: BunFile) {
  return new Response(await file.bytes());
}
