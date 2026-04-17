import type { AgentActivityEvent, AgentActivityEventType, AgentId } from "./types";

const agentIds: AgentId[] = ["dev", "backend", "qa", "finance"];

export function randomMockEvent(): AgentActivityEvent {
  const type = randomEventType();
  const agentId = agentIds[Math.floor(Math.random() * agentIds.length)];

  return {
    id: crypto.randomUUID(),
    agentId,
    type,
    createdAt: Date.now(),
    message: mockMessage(type),
  };
}

function randomEventType(): AgentActivityEventType {
  const types: AgentActivityEventType[] = [
    "idle",
    "writing_code",
    "reading_file",
    "running_tests",
    "error",
  ];
  return types[Math.floor(Math.random() * types.length)];
}

function mockMessage(type: AgentActivityEventType) {
  switch (type) {
    case "writing_code":
      return "Implementando feature";
    case "reading_file":
      return "Lendo arquivo";
    case "running_tests":
      return "Rodando testes";
    case "error":
      return "Falha detectada";
    default:
      return "Aguardando";
  }
}
