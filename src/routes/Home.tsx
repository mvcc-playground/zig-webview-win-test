import { Link } from "wouter";

export function HomeRoute() {
  return (
    <section className="stack">
      <div className="card">
        <p className="section-label">Overview</p>
        <h2>Frontend limpo, bridge preservado</h2>
        <p>
          Esta base usa React + TypeScript + Wouter na raiz do projeto, enquanto
          o codigo Zig fica isolado em <code>src-zig/</code>.
        </p>
      </div>

      <div className="card">
        <p className="section-label">Next</p>
        <p>
          Abra a area de comandos para testar o client gerado com{" "}
          <code>ping</code>, <code>sum</code>, <code>sub</code>,{" "}
          <code>echo</code>, <code>health</code> e comandos de identidade.
        </p>
        <Link href="/commands" className="cta-link">
          Ir para Commands
        </Link>
      </div>
    </section>
  );
}
