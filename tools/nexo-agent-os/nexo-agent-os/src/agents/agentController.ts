import type { Agent } from "./types";
import type { AgentActivityEvent, AgentVisualState } from "../events/types";
import { officeSpots } from "../scene/officeLayout";

export type UpdateResult = {
  agents: Agent[];
  lastEvent?: AgentActivityEvent;
};

export function applyEventToAgents(
  prevAgents: Agent[],
  event: AgentActivityEvent
): UpdateResult {
  const next = prevAgents.map((agent) => {
    if (agent.id !== event.agentId) {
      return agent;
    }

    const { target, state } = resolveTargetForEvent(event.type, agent);

    return {
      ...agent,
      state,
      lastEvent: event.message,
      x: target?.x ?? agent.x,
      y: target?.y ?? agent.y,
    };
  });

  return { agents: next, lastEvent: event };
}

function resolveTargetForEvent(
  type: AgentActivityEvent["type"],
  agent: Agent
): { target?: { x: number; y: number }; state: AgentVisualState } {
  switch (type) {
    case "writing_code":
      return { target: deskForAgent(agent.id), state: "walking" };
    case "reading_file":
      return { target: deskForAgent(agent.id), state: "walking" };
    case "running_tests":
      return { target: officeSpots.qa_area, state: "walking" };
    case "error":
      return { target: { x: agent.x, y: agent.y }, state: "error" };
    default:
      return { target: { x: agent.homeX, y: agent.homeY }, state: "walking" };
  }
}

function deskForAgent(id: Agent["id"]) {
  switch (id) {
    case "dev":
      return officeSpots.dev_desk;
    case "backend":
      return officeSpots.backend_desk;
    case "qa":
      return officeSpots.qa_desk;
    case "finance":
      return officeSpots.finance_desk;
  }
}
