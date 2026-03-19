// @ts-check

/**
 * @template {keyof import('./types/commands.generated').CommandMap} T
 * @param {T} command
 * @param {import('./types/commands.generated').CommandMap[T]['request']} payload
 * @returns {Promise<
 *   { ok: true, data: import('./types/commands.generated').CommandMap[T]['response'] } |
 *   { ok: false, error: string, details?: string }
 * >}
 */
export async function invoke(command, payload) {
  const result = await window.__mini.invoke(command, payload);
  return /** @type {any} */ (result);
}
