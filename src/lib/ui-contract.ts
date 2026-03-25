export type WindowKind = "minibar" | "control_panel";

export type UiStatus = "ready" | "recording" | "processing" | "inserted" | "error";

export type RuntimeMode = "native_multi_window";

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

export type UiBootstrap = {
  window_kind: WindowKind;
  ui_status: UiStatus;
  trace_id: string;
  session_id?: string | null;
  runtime_mode: RuntimeMode;
  control_panel_url: string;
};

export type ClientLogEvent = {
  level: LogLevel;
  trace_id: string;
  session_id?: string | null;
  module: string;
  event: string;
  message: string;
  error?: string | null;
  stack?: string | null;
  metadata_json?: string | null;
};
