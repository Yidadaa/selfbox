export function errorText(error: unknown): string | null {
  const messages: string[] = [];
  const seen = new Set<unknown>();
  let current = error;
  while (current != null && !seen.has(current)) {
    seen.add(current);
    if (typeof current === "string") {
      if (current.trim()) messages.push(current);
      break;
    }
    if (typeof current !== "object") break;
    if ("message" in current && typeof current.message === "string") {
      if (current.message.trim()) messages.push(current.message);
    } else {
      try {
        const serialized = JSON.stringify(current, null, 2);
        if (typeof serialized === "string" && serialized !== "{}")
          messages.push(serialized);
      } catch {
        // 原生异常可能包含循环引用，继续读取 cause。
      }
    }
    current = "cause" in current ? current.cause : undefined;
  }
  return messages.length ? messages.join("\n\n") : null;
}
