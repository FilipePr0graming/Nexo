import type { Agent } from "../agents/types";

export function AgentPanel(props: {
  agents: Agent[];
  selectedAgentId: Agent["id"] | null;
  onSelect: (id: Agent["id"]) => void;
  logs: Array<{ ts: number; agentName: string; message: string }>;
}) {
  const selected = props.selectedAgentId
    ? props.agents.find((a) => a.id === props.selectedAgentId) ?? null
    : null;

  return (
    <div
      style={{
        width: 320,
        background: "#0b1220",
        borderLeft: "1px solid rgba(148,163,184,0.15)",
        color: "#e2e8f0",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div style={{ padding: 16, borderBottom: "1px solid rgba(148,163,184,0.15)" }}>
        <div style={{ fontWeight: 800, letterSpacing: -0.4 }}>Nexo Agent OS</div>
        <div style={{ fontSize: 12, color: "rgba(226,232,240,0.7)" }}>
          Escritório 2D (mock de eventos)
        </div>
      </div>

      <div style={{ padding: 12 }}>
        <div style={{ fontSize: 12, color: "rgba(226,232,240,0.6)", marginBottom: 8 }}>
          Agentes
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {props.agents.map((agent) => {
            const isSelected = agent.id === props.selectedAgentId;
            return (
              <button
                key={agent.id}
                onClick={() => props.onSelect(agent.id)}
                style={{
                  textAlign: "left",
                  background: isSelected ? "rgba(59,130,246,0.18)" : "rgba(148,163,184,0.06)",
                  border: "1px solid rgba(148,163,184,0.12)",
                  borderRadius: 12,
                  padding: 10,
                  color: "#e2e8f0",
                  cursor: "pointer",
                }}
              >
                <div style={{ fontWeight: 700 }}>{agent.name}</div>
                <div style={{ fontSize: 12, color: "rgba(226,232,240,0.7)" }}>
                  {agent.state}
                  {agent.lastEvent ? ` • ${agent.lastEvent}` : ""}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <div
        style={{
          padding: 12,
          borderTop: "1px solid rgba(148,163,184,0.15)",
          marginTop: "auto",
        }}
      >
        <div style={{ fontSize: 12, color: "rgba(226,232,240,0.6)", marginBottom: 8 }}>
          Logs
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8, maxHeight: 260, overflow: "auto" }}>
          {props.logs.slice(0, 12).map((log) => (
            <div
              key={`${log.ts}-${log.agentName}-${log.message}`}
              style={{
                fontSize: 12,
                background: "rgba(148,163,184,0.06)",
                border: "1px solid rgba(148,163,184,0.12)",
                borderRadius: 12,
                padding: 10,
              }}
            >
              <div style={{ fontWeight: 700 }}>{log.agentName}</div>
              <div style={{ color: "rgba(226,232,240,0.75)" }}>{log.message}</div>
            </div>
          ))}
          {props.logs.length === 0 ? (
            <div style={{ fontSize: 12, color: "rgba(226,232,240,0.6)" }}>
              Sem logs ainda.
            </div>
          ) : null}
        </div>

        {selected ? (
          <div style={{ marginTop: 12, fontSize: 12, color: "rgba(226,232,240,0.7)" }}>
            Selecionado: <span style={{ fontWeight: 700 }}>{selected.name}</span>
          </div>
        ) : (
          <div style={{ marginTop: 12, fontSize: 12, color: "rgba(226,232,240,0.6)" }}>
            Selecione um agente.
          </div>
        )}
      </div>
    </div>
  );
}
