import type { Agent } from "./types";

export const initialAgents: Agent[] = [
  {
    id: "dev",
    name: "Frontend",
    role: "Frontend",
    x: 7,
    y: 6,
    homeX: 7,
    homeY: 6,
    state: "idle",
  },
  {
    id: "backend",
    name: "Backend",
    role: "Backend",
    x: 11,
    y: 6,
    homeX: 11,
    homeY: 6,
    state: "idle",
  },
  {
    id: "qa",
    name: "QA",
    role: "QA",
    x: 15,
    y: 6,
    homeX: 15,
    homeY: 6,
    state: "idle",
  },
  {
    id: "finance",
    name: "Financeiro",
    role: "Financeiro",
    x: 19,
    y: 6,
    homeX: 19,
    homeY: 6,
    state: "idle",
  },
];
