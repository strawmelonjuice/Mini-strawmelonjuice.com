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

function concatArrayBuffers(chunks: Uint8Array[]): Uint8Array {
  const result = new Uint8Array(chunks.reduce((a, c) => a + c.length, 0));
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}
