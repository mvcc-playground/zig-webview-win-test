import { Link, Route, Switch } from "wouter";
import { HomeRoute } from "./routes/Home";
import { CommandsRoute } from "./routes/Commands";
import { NotFoundRoute } from "./routes/NotFound";

export function App() {
  return (
    <main className="shell">
      <section className="panel">
        <header className="hero">
          <p className="eyebrow">react + typescript + wouter</p>
          <h1>Desktop shell for Zig commands</h1>
          <p className="lede">
            O app roda com Vite no desenvolvimento e com arquivos estaticos em
            producao, sem mudar o bridge nativo.
          </p>
        </header>

        <nav className="nav">
          <Link href="/" className="nav-link">
            Home
          </Link>
          <Link href="/commands" className="nav-link">
            Commands
          </Link>
        </nav>

        <section className="route-frame">
          <Switch>
            <Route path="/" component={HomeRoute} />
            <Route path="/commands" component={CommandsRoute} />
            <Route component={NotFoundRoute} />
          </Switch>
        </section>
      </section>
    </main>
  );
}
