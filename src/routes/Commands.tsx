import { useState } from "react";
import { invoke } from "../lib/invoke";

export function CommandsRoute() {
  const [message, setMessage] = useState("hello from React + TypeScript");
  const [output, setOutput] = useState("Aguardando chamada...");

  async function runPing() {
    const [data, error] = await window.invoke("ping", { message });
    setOutput(JSON.stringify(error ? { error } : { data }, null, 2));
  }

  async function runSum() {
    const [data, error] = await invoke("sum", 12, 21);
    setOutput(JSON.stringify(error ? { error } : { data }, null, 2));
  }

  async function runSub() {
    const [data, error] = await invoke("sub", 21, 12);
    setOutput(JSON.stringify(error ? { error } : { data }, null, 2));
  }

  return (
    <section className="stack">
      <div className="card">
        <p className="section-label">Invoke</p>
        <label className="field">
          <span>Mensagem</span>
          <input
            value={message}
            onChange={(event) => setMessage(event.currentTarget.value)}
          />
        </label>

        <div className="actions">
          <button onClick={runPing}>Ping</button>
          <button onClick={runSum}>Sum 12 + 21</button>
          <button onClick={runSub}>Sub 21 - 12</button>
        </div>
      </div>

      <pre className="output">{output}</pre>
    </section>
  );
}
