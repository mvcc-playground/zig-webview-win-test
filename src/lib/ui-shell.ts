import { commands } from "./commands";
import type { ClientLogEvent, UiBootstrap, WindowKind } from "./ui-contract";

export async function getUiBootstrap(windowKind: WindowKind): Promise<UiBootstrap> {
  return commands.get_ui_bootstrap({ window_kind: windowKind });
}

export async function openControlPanel(): Promise<{ opened: boolean; runtime_mode: string }> {
  return commands.open_control_panel();
}

export async function logClientEvent(payload: ClientLogEvent): Promise<void> {
  await commands.log_client_event({
    ...payload,
    session_id: payload.session_id ?? null,
    error: payload.error ?? null,
    stack: payload.stack ?? null,
    metadata_json: payload.metadata_json ?? null,
  });
}
