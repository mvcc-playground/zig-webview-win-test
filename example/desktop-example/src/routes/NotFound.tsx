import { Link } from "wouter";

export function NotFoundRoute() {
  return (
    <section className="card">
      <p className="section-label">404</p>
      <h2>Rota nao encontrada</h2>
      <p>Esta rota nao existe no frontend atual.</p>
      <Link href="/" className="cta-link">
        Voltar para Home
      </Link>
    </section>
  );
}
