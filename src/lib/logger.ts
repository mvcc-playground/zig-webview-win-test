import { logClientEvent } from "./ui-shell";
import type { ClientLogEvent, LogLevel } from "./ui-contract";

type LoggerContext = {
  traceId: string;
  module: string;
  sessionId?: string | null;
};

export type Logger = {
  debug: (event: string, message: string, metadata?: Record<string, unknown>) => Promise<void>;
  info: (event: string, message: string, metadata?: Record<string, unknown>) => Promise<void>;
  warn: (event: string, message: string, metadata?: Record<string, unknown>) => Promise<void>;
  error: (event: string, message: string, error?: unknown, metadata?: Record<string, unknown>) => Promise<void>;
};

function buildPayload(
  context: LoggerContext,
  level: LogLevel,
  event: string,
  message: string,
  metadata?: Record<string, unknown>,
): ClientLogEvent {
  return {
    level,
    trace_id: context.traceId,
    session_id: context.sessionId ?? null,
    module: context.module,
    event,
    message,
    metadata_json: metadata ? JSON.stringify(metadata) : null,
  };
}

export function createLogger(context: LoggerContext): Logger {
  const log = async (
    level: LogLevel,
    event: string,
    message: string,
    metadata?: Record<string, unknown>,
  ) => {
    await logClientEvent(buildPayload(context, level, event, message, metadata));
  };

  return {
    debug: (event, message, metadata) => log("DEBUG", event, message, metadata),
    info: (event, message, metadata) => log("INFO", event, message, metadata),
    warn: (event, message, metadata) => log("WARN", event, message, metadata),
    error: async (event, message, error, metadata) => {
      await logClientEvent({
        ...buildPayload(context, "ERROR", event, message, metadata),
        error: error instanceof Error ? error.message : String(error ?? ""),
        stack: error instanceof Error ? error.stack : null,
      });
    },
  };
}
