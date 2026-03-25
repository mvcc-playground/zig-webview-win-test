import React from "react";
import ReactDOM from "react-dom/client";
import { ControlPanelApp } from "./ControlPanelApp";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ControlPanelApp />
  </React.StrictMode>,
);
