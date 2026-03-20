import "./styles.css";
import { invoke } from "./invoke.js";

const app = document.querySelector("#app");

app.innerHTML = `
  <main class="shell">
    <section class="card">
      <p class="eyebrow">zig + vite</p>
      <h1>Mini desktop shell</h1>
      <p class="lede">
        O frontend roda pelo Vite no desenvolvimento e via <code>dist</code>
        estático em produção.
      </p>

      <label class="field">
        <span>Mensagem</span>
        <input id="message" value="hello from frontend/src/main.js" />
      </label>

      <div class="actions">
        <button data-command="ping">Ping</button>
        <button data-command="sum">Sum 12 + 21</button>
        <button data-command="sub">Sub 21 - 12</button>
      </div>

      <pre id="output">Aguardando chamada...</pre>
    </section>
  </main>
`;

const message = /** @type {HTMLInputElement} */ (document.querySelector("#message"));
const output = document.querySelector("#output");

document.querySelector('[data-command="ping"]').addEventListener("click", async () => {
  const [data, error] = await invoke("ping", { message: message.value });
  renderResult(data, error);
});

document.querySelector('[data-command="sum"]').addEventListener("click", async () => {
  const [data, error] = await invoke("sum", 12, 21);
  renderResult(data, error);
});

document.querySelector('[data-command="sub"]').addEventListener("click", async () => {
  const [data, error] = await invoke("sub", 21, 12);
  renderResult(data, error);
});

function renderResult(data, error) {
  output.textContent = JSON.stringify(error ? { error } : { data }, null, 2);
}
