import { useEffect, useMemo, useState } from "react";
import { createLogger } from "../lib/logger";
import { getUiBootstrap } from "../lib/ui-shell";
import type { UiBootstrap } from "../lib/ui-contract";

export function ControlPanelApp() {
  const [boot, setBoot] = useState<UiBootstrap | null>(null);
  const [error, setError] = useState<string | null>(null);

  const logger = useMemo(() => {
    if (!boot) return null;
    return createLogger({
      module: "control_panel",
      traceId: boot.trace_id,
      sessionId: boot.session_id,
    });
  }, [boot]);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const data = await getUiBootstrap("control_panel");
        if (!mounted) return;
        setBoot(data);
      } catch (err) {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : String(err));
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (!logger) return;
    void logger.info("bootstrap_loaded", "Control panel bootstrap loaded");
  }, [logger]);

  return (
    <main className="panel-shell">
      <section className="panel">
        <header>
          <p className="eyebrow">Control Panel</p>
          <h1>S1 Runtime</h1>
        </header>
        <dl>
          <dt>Window</dt>
          <dd>{boot?.window_kind ?? "loading"}</dd>
          <dt>Status</dt>
          <dd>{boot?.ui_status ?? "loading"}</dd>
          <dt>Trace</dt>
          <dd className="mono">{boot?.trace_id ?? "-"}</dd>
          <dt>Mode</dt>
          <dd>{boot?.runtime_mode ?? "-"}</dd>
        </dl>
      </section>
      {error && <p className="error">{error}</p>}
    </main>
  );
}
