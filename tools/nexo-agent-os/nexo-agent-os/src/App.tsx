import { useEffect, useMemo, useState } from "react";

import { initialAgents } from "./agents/initialAgents";
import type { Agent } from "./agents/types";
import { applyEventToAgents } from "./agents/agentController";
import { isAtTarget, stepAgentsTowardTargets } from "./agents/movement";
import { randomMockEvent } from "./events/mockEventStream";
import type { AgentActivityEvent } from "./events/types";
import { officeSpots } from "./scene/officeLayout";
import { PixiStage } from "./scene/PixiStage";
import { AgentPanel } from "./ui/AgentPanel";

type AgentLog = { ts: number; agentName: string; message: string };

type AgentRuntime = {
  agentTargets: Map<Agent["id"], { x: number; y: number }>;
  pendingState: Map<Agent["id"], Agent["state"]>;
};

function resolveFinalStateForEventType(event: AgentActivityEvent) {
  switch (event.type) {
    case "writing_code":
      return "typing" as const;
    case "reading_file":
      return "reading" as const;
    case "running_tests":
      return "testing" as const;
    case "error":
      return "error" as const;
    default:
      return "idle" as const;
  }
}

function resolveTargetForEvent(event: AgentActivityEvent) {
  switch (event.type) {
    case "writing_code":
    case "reading_file":
      return deskFor(event.agentId);
    case "running_tests":
      return officeSpots.qa_area;
    case "idle":
      return homeFor(event.agentId);
    case "error":
      return null;
  }
}

function deskFor(agentId: Agent["id"]) {
  switch (agentId) {
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

function homeFor(agentId: Agent["id"]) {
  return deskFor(agentId);
}

export default function App() {
  const [agents, setAgents] = useState<Agent[]>(initialAgents);
  const [selectedAgentId, setSelectedAgentId] = useState<Agent["id"] | null>(
    "dev"
  );
  const [logs, setLogs] = useState<AgentLog[]>([]);

  const runtime = useMemo<AgentRuntime>(
    () => ({ agentTargets: new Map(), pendingState: new Map() }),
    []
  );

  useEffect(() => {
    const interval = setInterval(() => {
      const event = randomMockEvent();

      setLogs((prev) => [
        {
          ts: Date.now(),
          agentName: agentName(event.agentId),
          message: `${event.type} • ${event.message}`,
        },
        ...prev,
      ]);

      const target = resolveTargetForEvent(event);
      if (target) {
        runtime.agentTargets.set(event.agentId, { x: target.x, y: target.y });
        runtime.pendingState.set(
          event.agentId,
          resolveFinalStateForEventType(event)
        );
      } else {
        runtime.agentTargets.delete(event.agentId);
        runtime.pendingState.set(event.agentId, "error");
      }

      setAgents((prev) =>
        applyEventToAgents(prev, event).agents.map((a) =>
          a.id === event.agentId
            ? { ...a, state: target ? "walking" : "error", lastEvent: event.type }
            : a
        )
      );
    }, 2200);

    return () => clearInterval(interval);
  }, [runtime]);

  useEffect(() => {
    let raf = 0;
    let last = performance.now();

    const tick = (t: number) => {
      const dt = Math.min(0.05, (t - last) / 1000);
      last = t;

      setAgents((prev) => {
        const stepped = stepAgentsTowardTargets(prev, runtime.agentTargets, dt, {
          speedTilesPerSecond: 3.2,
        });

        return stepped.map((a) => {
          const target = runtime.agentTargets.get(a.id);
          if (!target) {
            return a;
          }

          if (isAtTarget(a, target)) {
            runtime.agentTargets.delete(a.id);
            const finalState = runtime.pendingState.get(a.id) ?? "idle";
            runtime.pendingState.delete(a.id);
            return { ...a, x: target.x, y: target.y, state: finalState };
          }

          return { ...a, state: "walking" };
        });
      });

      raf = requestAnimationFrame(tick);
    };

    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [runtime]);

  return (
    <div style={{ display: "flex", height: "100vh", width: "100vw" }}>
      <PixiStage agents={agents} />
      <AgentPanel
        agents={agents}
        selectedAgentId={selectedAgentId}
        onSelect={setSelectedAgentId}
        logs={logs}
      />
    </div>
  );
}

function agentName(id: Agent["id"]) {
  switch (id) {
    case "dev":
      return "Frontend";
    case "backend":
      return "Backend";
    case "qa":
      return "QA";
    case "finance":
      return "Financeiro";
  }
}
