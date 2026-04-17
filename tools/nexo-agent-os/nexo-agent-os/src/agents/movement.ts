import type { Agent } from "./types";

export type MovementConfig = {
  speedTilesPerSecond: number;
};

export function stepAgentsTowardTargets(
  agents: Agent[],
  targets: Map<Agent["id"], { x: number; y: number }>,
  dtSeconds: number,
  config: MovementConfig
): Agent[] {
  const maxStep = config.speedTilesPerSecond * dtSeconds;

  return agents.map((agent) => {
    const target = targets.get(agent.id);
    if (!target) {
      return agent;
    }

    const dx = target.x - agent.x;
    const dy = target.y - agent.y;

    if (dx === 0 && dy === 0) {
      return agent;
    }

    // move 1 axis per step for grid-like pathing
    const stepX = dx !== 0 ? Math.sign(dx) * Math.min(Math.abs(dx), maxStep) : 0;
    const stepY = dx === 0 && dy !== 0 ? Math.sign(dy) * Math.min(Math.abs(dy), maxStep) : 0;

    // clamp to grid
    const nextX = Math.round((agent.x + stepX) * 1000) / 1000;
    const nextY = Math.round((agent.y + stepY) * 1000) / 1000;

    return {
      ...agent,
      x: nextX,
      y: nextY,
    };
  });
}

export function isAtTarget(agent: Agent, target: { x: number; y: number }) {
  return Math.abs(agent.x - target.x) < 0.01 && Math.abs(agent.y - target.y) < 0.01;
}
