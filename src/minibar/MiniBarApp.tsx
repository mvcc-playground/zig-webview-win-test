import { useEffect, useMemo, useState } from "react";
import { createLogger } from "../lib/logger";
import { getUiBootstrap, openControlPanel } from "../lib/ui-shell";
import type { UiBootstrap } from "../lib/ui-contract";

export function MiniBarApp() {
  const [boot, setBoot] = useState<UiBootstrap | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const logger = useMemo(() => {
    if (!boot) return null;
    return createLogger({ module: "minibar", traceId: boot.trace_id, sessionId: boot.session_id });
  }, [boot]);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const data = await getUiBootstrap("minibar");
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
    void logger.info("bootstrap_loaded", "MiniBar bootstrap loaded");
  }, [logger]);

  const handleOpenPanel = async () => {
    if (!logger) return;
    setBusy(true);
    try {
      const result = await openControlPanel();
      await logger.info("open_control_panel", "Control panel command invoked", result);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
      await logger.error("open_control_panel_failed", "Failed to open control panel", err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="minibar-shell">
      <section className="minibar">
        <div className="future-controls" aria-label="Future controls">
          <button type="button" className="ghost-btn" disabled title="Recording settings (coming soon)">
            Rec
          </button>
          <button type="button" className="ghost-btn" disabled title="Model selection (coming soon)">
            GPT
          </button>
        </div>
        <div className="status">
          <span className="dot" />
          <strong>{boot?.ui_status ?? "loading"}</strong>
        </div>
        <button type="button" onClick={handleOpenPanel} disabled={!boot || busy}>
          Open Settings
        </button>
      </section>
      {error && <p className="error">{error}</p>}
    </main>
  );
}
