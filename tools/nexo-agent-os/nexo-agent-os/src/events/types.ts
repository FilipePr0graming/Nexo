export type AgentActivityEventType =
  | "idle"
  | "writing_code"
  | "reading_file"
  | "running_tests"
  | "error";

export type AgentVisualState =
  | "idle"
  | "walking"
  | "typing"
  | "reading"
  | "testing"
  | "error";

export type AgentId = "dev" | "backend" | "qa" | "finance";

export type AgentActivityEvent = {
  id: string;
  agentId: AgentId;
  type: AgentActivityEventType;
  createdAt: number;
  message: string;
};
