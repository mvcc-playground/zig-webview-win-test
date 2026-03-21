import { Link } from "wouter";

export function HomeRoute() {
  return (
    <section className="stack">
      <div className="card">
        <p className="section-label">Overview</p>
        <h2>Example app on top of a reusable Zig core</h2>
        <p>
          Este app existe para validar o caminho feliz do monorepo: um core
          reutilizavel em <code>core/mini/</code> e um consumidor real em{" "}
          <code>example/</code>.
        </p>
      </div>

      <div className="card">
        <p className="section-label">Next</p>
        <p>
          Abra a area de comandos para testar o client gerado, o bridge interno
          e os comandos Zig tipados do exemplo.
        </p>
        <Link href="/commands" className="cta-link">
          Ir para Commands
        </Link>
      </div>
    </section>
  );
}
