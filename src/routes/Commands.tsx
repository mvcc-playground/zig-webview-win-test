import { useState } from "react";
import { commands } from "../lib/commands";
import { InvokeRuntimeError } from "../lib/invoke";

export function CommandsRoute() {
  const [message, setMessage] = useState("hello from React + TypeScript");
  const [lastName, setLastName] = useState("silva");
  const [text, setText] = useState("echo from generated client");
  const [output, setOutput] = useState("Aguardando chamada...");

  async function runPing() {
    try {
      const data = await commands.ping({ message });
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runSum() {
    try {
      const data = await commands.sum(12, 21);
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runSub() {
    try {
      const data = await commands.sub(21, 12);
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runEcho() {
    try {
      const data = await commands.echo({ text });
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runHealth() {
    try {
      const data = await commands.health();
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runGetFullName() {
    try {
      const data = await commands.getFullName(lastName);
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
  }

  async function runGetLastName() {
    try {
      const data = await commands.getLastName(lastName);
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      setOutput(formatError(error));
    }
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
        <label className="field">
          <span>Last name</span>
          <input
            value={lastName}
            onChange={(event) => setLastName(event.currentTarget.value)}
          />
        </label>
        <label className="field">
          <span>Echo text</span>
          <input
            value={text}
            onChange={(event) => setText(event.currentTarget.value)}
          />
        </label>

        <div className="actions">
          <button onClick={runPing}>Ping</button>
          <button onClick={runSum}>Sum 12 + 21</button>
          <button onClick={runSub}>Sub 21 - 12</button>
          <button onClick={runEcho}>Echo</button>
          <button onClick={runHealth}>Health</button>
          <button onClick={runGetLastName}>getLastName</button>
          <button onClick={runGetFullName}>getFullName</button>
        </div>
      </div>

      <pre className="output">{output}</pre>
    </section>
  );
}

function formatError(error: unknown): string {
  if (error instanceof InvokeRuntimeError) {
    return JSON.stringify(
      {
        code: error.code,
        message: error.message,
        details: error.details ?? null,
      },
      null,
      2,
    );
  }

  if (error instanceof Error) {
    return JSON.stringify({ message: error.message }, null, 2);
  }

  return JSON.stringify({ message: String(error) }, null, 2);
}
