import type { AgentId, AgentVisualState } from "../events/types";

export type Agent = {
  id: AgentId;
  name: string;
  role: string;

  x: number;
  y: number;

  homeX: number;
  homeY: number;

  state: AgentVisualState;
  lastEvent?: string;
};
