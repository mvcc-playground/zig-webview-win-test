// @ts-check
/// <reference path="../types/global.generated.d.ts" />

/**
 * @template {keyof import("../types/commands.generated").CommandMap} T
 * @param {T} command
 * @param {...import("../types/commands.generated").CommandMap[T]["args"]} args
 * @returns {Promise<import("../types/commands.generated").InvokeTuple<T>>}
 */
export async function invoke(command, ...args) {
  return window.invoke(command, ...args);
}
